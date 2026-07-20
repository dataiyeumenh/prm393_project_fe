import '../models/api/cart_dto.dart';
import 'api_service.dart';

class CartService {
  static Future<ApiResult<CartResponse>> getCart() async {
    try {
      final response = await ApiService.dio.get('/api/v1/cart');

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final cart = CartResponse.fromJson(data as Map<String, dynamic>);
        return ApiResult.success(cart);
      }
      return ApiResult.fail(response.data['message'] ?? 'Failed to load cart');
    } catch (e) {
      return ApiResult.fail(_extractError(e));
    }
  }

  static Future<ApiResult<CartResponse>> addToCart(CartItemRequest request) async {
    try {
      final response = await ApiService.dio.post(
        '/api/v1/cart',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final cart = CartResponse.fromJson(data as Map<String, dynamic>);
        return ApiResult.success(cart);
      }
      return ApiResult.fail(response.data['message'] ?? 'Failed to add to cart');
    } catch (e) {
      return ApiResult.fail(_extractError(e));
    }
  }

  static Future<ApiResult<CartResponse>> removeFromCart(String cartItemId) async {
    try {
      final response = await ApiService.dio.delete('/api/v1/cart/$cartItemId');

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final cart = CartResponse.fromJson(data as Map<String, dynamic>);
        return ApiResult.success(cart);
      }
      return ApiResult.fail(response.data['message'] ?? 'Failed to remove from cart');
    } catch (e) {
      return ApiResult.fail(_extractError(e));
    }
  }

  static Future<ApiResult<void>> clearCart() async {
    try {
      final response = await ApiService.dio.delete('/api/v1/cart/clear');
      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResult.success(null);
      }
      return ApiResult.fail(response.data['message'] ?? 'Failed to clear cart');
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
