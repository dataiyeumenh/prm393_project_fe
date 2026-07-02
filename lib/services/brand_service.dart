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

  static String _extractError(dynamic e) {
    final str = e.toString();
    final match = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(str);
    if (match != null) return match.group(1)!;
    return 'An error occurred. Please try again.';
  }
}
