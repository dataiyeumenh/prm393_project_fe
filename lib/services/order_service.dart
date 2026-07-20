import '../models/api/cart_dto.dart';
import '../models/api/order_dto.dart';
import '../models/api/product_dto.dart';
import 'api_service.dart';
import 'product_service.dart';

class OrderService {
  /// Mirrors the local cart onto the server cart before checkout.
  ///
  /// Clears the server cart first (`DELETE /cart/clear`), then re-adds each
  /// local line once. `POST /cart` adds to any existing quantity, but since
  /// the cart is now empty every line lands at exactly its local quantity —
  /// so a single pass is both simpler and free of duplicate/stale-item races.
  static Future<ApiResult<void>> syncCart(List<CartItemRequest> items) async {
    try {
      final clearResp = await ApiService.dio.delete('/api/v1/cart/clear');
      if (clearResp.statusCode != 200 && clearResp.statusCode != 204) {
        return ApiResult.fail(
          clearResp.data['message'] as String? ?? 'Failed to clear server cart',
        );
      }

      for (final item in items) {
        final response = await ApiService.dio.post(
          '/api/v1/cart',
          data: item.toJson(),
        );
        if (response.statusCode != 200 && response.statusCode != 201) {
          return ApiResult.fail(
            response.data['message'] as String? ?? 'Failed to sync cart',
          );
        }
      }
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.fail(_extractError(e));
    }
  }

  /// Customer: `POST /api/v1/orders/checkout` — creates an order (PENDING)
  /// from the server-side cart.
  static Future<ApiResult<OrderSummaryDTO>> checkout(
    CheckoutRequest request,
  ) async {
    try {
      final response = await ApiService.dio.post(
        '/api/v1/orders/checkout',
        data: request.toJson(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final order = OrderSummaryDTO.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        return ApiResult.success(order);
      }
      return ApiResult.fail(
        response.data['message'] as String? ?? 'Checkout failed',
      );
    } catch (e) {
      return ApiResult.fail(_extractError(e));
    }
  }

  /// Admin: get all orders paginated with optional status filter.
  static Future<ApiResult<PageResponse<OrderSummaryDTO>>> getOrders({
    String? status,
    int page = 0,
    int size = 20,
    String sortBy = 'createdAt',
    String sortDir = 'DESC',
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'size': size,
        'sortBy': sortBy,
        'sortDir': sortDir,
      };
      if (status != null) params['status'] = status;

      final response = await ApiService.dio.get(
        '/api/v1/admin/orders',
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        final body = response.data;
        // Response may be a page object or a list directly
        final data = body['data'];
        if (data is Map<String, dynamic> && data.containsKey('content')) {
          final page = PageResponse.fromJson(data, OrderSummaryDTO.fromJson);
          return ApiResult.success(page);
        } else if (data is List) {
          final items = data
              .map((e) => OrderSummaryDTO.fromJson(e as Map<String, dynamic>))
              .toList();
          return ApiResult.success(
            PageResponse(
              content: items,
              pageNumber: 0,
              pageSize: items.length,
              totalElements: items.length,
              totalPages: 1,
              last: true,
            ),
          );
        }
      }
      return ApiResult.fail(
        response.data['message'] as String? ?? 'Failed to load orders',
      );
    } catch (e) {
      return ApiResult.fail(_extractError(e));
    }
  }

  /// Get order detail by ID.
  static Future<ApiResult<OrderDetailDTO>> getOrderById(String id) async {
    try {
      final response = await ApiService.dio.get('/api/v1/orders/$id');
      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return ApiResult.success(OrderDetailDTO.fromJson(data));
      }
      return ApiResult.fail(
        response.data['message'] as String? ?? 'Failed to load order',
      );
    } catch (e) {
      return ApiResult.fail(_extractError(e));
    }
  }

  /// Admin: update order status.
  static Future<ApiResult<bool>> updateOrderStatus(
    String orderId,
    OrderStatus newStatus,
  ) async {
    try {
      final response = await ApiService.dio.put(
        '/api/v1/admin/orders/$orderId/status',
        data: UpdateOrderStatusRequest(status: newStatus.apiValue).toJson(),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResult.success(true);
      }
      // Some backends use PATCH instead of PUT
      return ApiResult.fail(
        response.data['message'] as String? ?? 'Failed to update status',
      );
    } catch (e) {
      return ApiResult.fail(_extractError(e));
    }
  }

  static String _extractError(dynamic e) {
    final str = e.toString();
    final match = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(str);
    if (match != null) return match.group(1)!;
    return 'An error occurred. Please try again.';
  }
}
