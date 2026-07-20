import 'package:dio/dio.dart';

import '../models/api/auth_dto.dart';
import 'api_service.dart';

class UserProfileService {
  static Future<ApiResult<UserProfileDTO>> getProfile() async {
    try {
      final response = await ApiService.dio.get('/api/v1/users/profile');
      if (response.statusCode == 200) {
        final body = response.data;
        final data = body is Map<String, dynamic>
            ? (body['data'] ?? body)
            : body;
        if (data is Map<String, dynamic>) {
          return ApiResult.success(UserProfileDTO.fromJson(data));
        }
      }
      return ApiResult.fail('Không tải được hồ sơ cá nhân');
    } catch (e) {
      return ApiResult.fail(_extractError(e));
    }
  }

  static Future<ApiResult<bool>> updateProfile(
    UpdateProfileRequest request,
  ) async {
    try {
      final response = await ApiService.dio.put(
        '/api/v1/users/profile',
        data: request.toJson(),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResult.success(true);
      }
      return ApiResult.fail('Cập nhật hồ sơ thất bại');
    } catch (e) {
      return ApiResult.fail(_extractError(e));
    }
  }

  static Future<ApiResult<bool>> updateAvatar({
    required List<int> bytes,
    required String fileName,
  }) async {
    final fieldNames = ['file', 'avatar'];
    dynamic lastError;

    for (final field in fieldNames) {
      try {
        final form = FormData.fromMap({
          field: MultipartFile.fromBytes(bytes, filename: fileName),
        });
        final response = await ApiService.dio.post(
          '/api/v1/users/avatar',
          data: form,
          options: Options(contentType: 'multipart/form-data'),
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          return ApiResult.success(true);
        }
        lastError = response.data;
      } catch (e) {
        lastError = e;
        // If backend specifically requires another field name, try fallback.
        final message = _extractError(e).toLowerCase();
        final code = (e is DioException) ? e.response?.statusCode : null;
        final shouldFallback =
            field == 'file' &&
            (code == 400 ||
                code == 422 ||
                message.contains('required') ||
                message.contains('part') ||
                message.contains('file'));
        if (shouldFallback) continue;
        return ApiResult.fail(_extractError(e));
      }
    }

    return ApiResult.fail(
      lastError != null
          ? _extractError(lastError)
          : 'Cập nhật ảnh đại diện thất bại',
    );
  }

  static String _extractError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final msg = data['message']?.toString();
        if (msg != null && msg.isNotEmpty) return msg;
      }
      final code = e.response?.statusCode;
      if (code == 401) return 'Bạn cần đăng nhập lại';
      if (code == 403) return 'Không có quyền truy cập';
      if (code == 404) return 'Endpoint profile chưa có trên backend';
      if (code != null) return 'Lỗi máy chủ ($code)';
    }
    return 'Có lỗi xảy ra, vui lòng thử lại';
  }
}

class ApiResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  ApiResult._({this.data, this.error, required this.isSuccess});

  factory ApiResult.success(T data) => ApiResult._(data: data, isSuccess: true);
  factory ApiResult.fail(String error) =>
      ApiResult._(error: error, isSuccess: false);
}
