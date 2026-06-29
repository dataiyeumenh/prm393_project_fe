import '../models/api/category_dto.dart';
import 'api_service.dart';

class CategoryService {
  static Future<ApiResult<List<CategoryDTO>>> getAllCategories() async {
    try {
      final response = await ApiService.dio.get('/api/v1/categories');

      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>;
        final categories = data
            .map((e) => CategoryDTO.fromJson(e as Map<String, dynamic>))
            .toList();
        return ApiResult.success(categories);
      }
      return ApiResult.fail(response.data['message'] ?? 'Failed to load categories');
    } catch (e) {
      return ApiResult.fail(_extractError(e));
    }
  }

  static String _extractError(dynamic e) {
    if (e is Exception) {
      final str = e.toString();
      if (str.contains('message')) {
        final match = RegExp(r'"message":"([^"]+)"').firstMatch(str);
        if (match != null) return match.group(1)!;
      }
    }
    return 'An error occurred. Please try again.';
  }
}

class ApiResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  ApiResult._({this.data, this.error, required this.isSuccess});

  factory ApiResult.success(T data) => ApiResult._(data: data, isSuccess: true);
  factory ApiResult.fail(String error) => ApiResult._(error: error, isSuccess: false);
}
