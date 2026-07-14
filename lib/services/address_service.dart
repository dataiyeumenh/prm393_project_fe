import 'package:dio/dio.dart';

import '../models/api/address_dto.dart';
import 'api_service.dart';
import 'product_service.dart';

class AddressService {
  /// `GET /api/v1/addresses`
  static Future<ApiResult<List<AddressDTO>>> getMyAddresses() async {
    try {
      final response = await ApiService.dio.get('/api/v1/addresses');
      if (response.statusCode == 200) {
        final list = (response.data['data'] as List<dynamic>? ?? [])
            .map((e) => AddressDTO.fromJson(e as Map<String, dynamic>))
            .toList();
        return ApiResult.success(list);
      }
      return ApiResult.fail(
          response.data['message'] as String? ?? 'Failed to load addresses');
    } catch (e) {
      return ApiResult.fail(_extractError(e));
    }
  }

  /// `POST /api/v1/addresses`
  static Future<ApiResult<AddressDTO>> createAddress(
      AddressRequest request) async {
    try {
      final response = await ApiService.dio.post(
        '/api/v1/addresses',
        data: request.toJson(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final address =
            AddressDTO.fromJson(response.data['data'] as Map<String, dynamic>);
        return ApiResult.success(address);
      }
      return ApiResult.fail(
          response.data['message'] as String? ?? 'Failed to add address');
    } catch (e) {
      return ApiResult.fail(_extractError(e));
    }
  }

  static String _extractError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return 'Network error. Please check your connection and try again.';
      }
    }
    return 'An error occurred. Please try again.';
  }
}
