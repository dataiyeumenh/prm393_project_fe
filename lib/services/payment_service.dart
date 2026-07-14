import 'package:dio/dio.dart';

import '../models/api/order_dto.dart';
import 'api_service.dart';
import 'product_service.dart';

class PaymentService {
  /// `GET /api/v1/payments/vnpay/create-url?orderId={id}`
  ///
  /// Returns the VNPay gateway URL the user should be redirected to.
  static Future<ApiResult<PaymentUrlResponse>> createVnpayUrl(
      String orderId) async {
    try {
      final response = await ApiService.dio.get(
        '/api/v1/payments/vnpay/create-url',
        queryParameters: {'orderId': orderId},
      );
      if (response.statusCode == 200) {
        final data = response.data['data'];
        // Backend may return {"paymentUrl": "..."} or the bare URL string.
        if (data is Map<String, dynamic>) {
          return ApiResult.success(PaymentUrlResponse.fromJson(data));
        }
        if (data is String && data.isNotEmpty) {
          return ApiResult.success(PaymentUrlResponse(paymentUrl: data));
        }
      }
      return ApiResult.fail(
          response.data['message'] as String? ?? 'Failed to create payment URL');
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
