import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/api/review_dto.dart';
import 'api_service.dart';

class ReviewService {
  static Future<ApiResult<ProductReviewPageDTO>> getProductReviews({
    required String productId,
    int page = 0,
    int size = 10,
    String sortBy = 'createdAt',
    String direction = 'desc',
  }) async {
    try {
      final response = await ApiService.dio.get(
        '/api/v1/reviews/product/$productId',
        queryParameters: {
          'page': page,
          'size': size,
          'sortBy': sortBy,
          'direction': direction,
        },
      );

      if (response.statusCode == 200) {
        final body = response.data;
        final data = body is Map<String, dynamic> ? body['data'] : null;
        if (data is Map<String, dynamic>) {
          return ApiResult.success(ProductReviewPageDTO.fromJson(data));
        }
      }

      return ApiResult.fail(_extractError(response.data));
    } catch (e) {
      return ApiResult.fail(_extractError(e));
    }
  }

  static Future<ApiResult<ProductReviewDTO>> createReview({
    required String productId,
    required double rating,
    required String comment,
    List<ReviewUploadImage> images = const [],
  }) async {
    try {
      final form = FormData.fromMap({
        'review': MultipartFile.fromString(
          jsonEncode({
            'productId': productId,
            'rating': rating,
            'comment': comment,
          }),
          filename: 'review.json',
          contentType: DioMediaType.parse('application/json'),
        ),
      });

      for (final image in images) {
        form.files.add(
          MapEntry(
            'images',
            MultipartFile.fromBytes(
              image.bytes,
              filename: image.fileName,
              contentType: _imageMediaType(image.fileName),
            ),
          ),
        );
      }

      final response = await ApiService.dio.post(
        '/api/v1/reviews',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.data;
        final data = body is Map<String, dynamic> ? body['data'] : null;
        if (data is Map<String, dynamic>) {
          return ApiResult.success(ProductReviewDTO.fromJson(data));
        }
      }

      return ApiResult.fail('Không thể gửi đánh giá');
    } catch (e) {
      return ApiResult.fail(_extractError(e));
    }
  }

  static String _extractError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final msg = data['message']?.toString();
        if (msg != null && msg.isNotEmpty) return msg;
      }
      final code = e.response?.statusCode;
      if (code != null) return 'Lỗi máy chủ ($code)';
    }

    if (e is Map<String, dynamic>) {
      final msg = e['message']?.toString();
      if (msg != null && msg.isNotEmpty) return msg;
    }

    return 'Có lỗi xảy ra, vui lòng thử lại';
  }

  static DioMediaType _imageMediaType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return DioMediaType.parse('image/png');
    }
    if (lower.endsWith('.webp')) {
      return DioMediaType.parse('image/webp');
    }
    if (lower.endsWith('.gif')) {
      return DioMediaType.parse('image/gif');
    }
    return DioMediaType.parse('image/jpeg');
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
