import 'package:flutter/foundation.dart';

import '../models/api/brand_dto.dart';
import 'api_service.dart';
import 'product_service.dart';

class BrandService {
  static Future<ApiResult<List<BrandDTO>>> getAllBrands() async {
    final endpoints = ['/api/v1/brands', '/api/v1/admin/brands'];

    dynamic lastError;
    for (final endpoint in endpoints) {
      try {
        final response = await ApiService.dio.get(endpoint);
        debugPrint('[BrandService] GET $endpoint -> ${response.statusCode}');
        debugPrint('[BrandService] Raw body: ${response.data}');
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

          return ApiResult.success(
            list
                .whereType<Map<String, dynamic>>()
                .map(BrandDTO.fromJson)
                .toList(),
          );
        }

        lastError = response.data;
      } catch (e) {
        lastError = e;
        final str = e.toString();
        if (str.contains('[404]')) {
          debugPrint('[BrandService] Skip 404 endpoint $endpoint');
          continue;
        }
        debugPrint('[BrandService] Error on $endpoint: $e');
      }
    }

    return ApiResult.fail(
      lastError != null ? _extractError(lastError) : 'Failed to load brands',
    );
  }

  static Future<ApiResult<bool>> createBrand({
    required String name,
    String? description,
    String? logoUrl,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (logoUrl != null && logoUrl.trim().isNotEmpty)
          'logoUrl': logoUrl.trim(),
      };

      final response = await ApiService.dio.post(
        '/api/v1/admin/brands',
        data: body,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResult.success(true);
      }
      return ApiResult.fail('Tạo thương hiệu thất bại');
    } catch (e) {
      return ApiResult.fail(_extractError(e));
    }
  }

  static Future<ApiResult<bool>> updateBrand(
    int brandId, {
    required String name,
    String? description,
    String? logoUrl,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (logoUrl != null && logoUrl.trim().isNotEmpty)
          'logoUrl': logoUrl.trim(),
      };

      final response = await ApiService.dio.put(
        '/api/v1/admin/brands/$brandId',
        data: body,
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResult.success(true);
      }
      return ApiResult.fail('Cập nhật thương hiệu thất bại');
    } catch (e) {
      return ApiResult.fail(_extractError(e));
    }
  }

  static Future<ApiResult<bool>> deleteBrand(int brandId) async {
    try {
      final response = await ApiService.dio.delete(
        '/api/v1/admin/brands/$brandId',
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResult.success(true);
      }
      return ApiResult.fail('Xóa thương hiệu thất bại');
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

    final str = e.toString();
    final match = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(str);
    if (match != null) return match.group(1)!;
    return 'An error occurred. Please try again.';
  }
}
