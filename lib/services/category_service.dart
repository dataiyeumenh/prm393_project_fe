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
  factory ApiResult.fail(String error) =>
      ApiResult._(error: error, isSuccess: false);
}
