import 'package:flutter/foundation.dart';

import '../models/api/category_dto.dart';
import 'api_service.dart';

class CategoryService {
  static Future<ApiResult<List<CategoryDTO>>> getAllCategories() async {
    final endpoints = ['/api/v1/categories', '/api/v1/category'];

    dynamic lastError;
    for (final endpoint in endpoints) {
      try {
        final response = await ApiService.dio.get(endpoint);
        debugPrint('[CategoryService] GET $endpoint -> ${response.statusCode}');
        debugPrint('[CategoryService] Raw body: ${response.data}');

        if (response.statusCode == 200) {
          final body = response.data;
          final raw = body is Map<String, dynamic>
              ? (body['data'] ?? body)
              : body;

          List<dynamic> list;
          if (raw is List) {
            list = raw;
          } else if (raw is Map && raw['content'] is List) {
            list = raw['content'] as List<dynamic>;
          } else if (raw is Map && raw['items'] is List) {
            list = raw['items'] as List<dynamic>;
          } else if (raw is Map && raw['results'] is List) {
            list = raw['results'] as List<dynamic>;
          } else {
            list = [];
          }

          final categories = list
              .whereType<Map<String, dynamic>>()
              .map(CategoryDTO.fromJson)
              .toList();
          debugPrint(
            '[CategoryService] Parsed categories count: ${categories.length}',
          );
          return ApiResult.success(categories);
        }

        lastError = response.data;
      } catch (e) {
        lastError = e;
        debugPrint('[CategoryService] Error on $endpoint: $e');
      }
    }

    return ApiResult.fail(
      lastError != null
          ? _extractError(lastError)
          : 'Failed to load categories',
    );
  }

  static Future<ApiResult<bool>> createCategory({
    required String name,
    String? description,
    String? imageUrl,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (imageUrl != null && imageUrl.trim().isNotEmpty)
          'imageUrl': imageUrl.trim(),
      };

      final response = await ApiService.dio.post(
        '/api/v1/admin/categories',
        data: body,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResult.success(true);
      }
      return ApiResult.fail('Tạo danh mục thất bại');
    } catch (e) {
      return ApiResult.fail(_extractError(e));
    }
  }

  static Future<ApiResult<bool>> updateCategory(
    int categoryId, {
    required String name,
    String? description,
    String? imageUrl,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (imageUrl != null && imageUrl.trim().isNotEmpty)
          'imageUrl': imageUrl.trim(),
      };

      final response = await ApiService.dio.put(
        '/api/v1/admin/categories/$categoryId',
        data: body,
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResult.success(true);
      }
      return ApiResult.fail('Cập nhật danh mục thất bại');
    } catch (e) {
      return ApiResult.fail(_extractError(e));
    }
  }

  static Future<ApiResult<bool>> deleteCategory(int categoryId) async {
    try {
      final response = await ApiService.dio.delete(
        '/api/v1/admin/categories/$categoryId',
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResult.success(true);
      }
      return ApiResult.fail('Xóa danh mục thất bại');
    } catch (e) {
      return ApiResult.fail(_extractError(e));
    }
  }

  static String _extractError(dynamic e) {
    final data = (e as dynamic).response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['message']?.toString();
      if (msg != null && msg.isNotEmpty) return msg;
      final error = data['error']?.toString();
      if (error != null && error.isNotEmpty) return error;
    }

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
  factory ApiResult.fail(String error) =>
      ApiResult._(error: error, isSuccess: false);
}
