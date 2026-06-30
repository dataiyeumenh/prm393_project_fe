import '../models/api/admin_dto.dart';
import '../models/api/product_dto.dart';
import 'api_service.dart';
import 'product_service.dart';

class AdminService {
  // ──────────────────────────────────────────────────────────────
  // Dashboard
  // ──────────────────────────────────────────────────────────────

  /// Fetch dashboard summary stats.
  /// Falls back to a combined request if dedicated endpoint is absent.
  static Future<ApiResult<DashboardStatsDTO>> getDashboardStats() async {
    try {
      final response = await ApiService.dio.get('/api/v1/admin/dashboard');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data is Map<String, dynamic>) {
          return ApiResult.success(DashboardStatsDTO.fromJson(data));
        }
      }
      return ApiResult.fail('Failed to load dashboard');
    } catch (_) {
      // Endpoint may not exist yet — return empty stats gracefully
      return ApiResult.success(DashboardStatsDTO.empty());
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Users
  // ──────────────────────────────────────────────────────────────

  static Future<ApiResult<PageResponse<AdminUserDTO>>> getUsers({
    int page = 0,
    int size = 20,
    String? search,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (search != null && search.isNotEmpty) params['search'] = search;

    // Try endpoints in order of preference
    final endpoints = ['/api/v1/admin/users', '/api/v1/users'];

    dynamic lastError;
    for (final endpoint in endpoints) {
      try {
        final response = await ApiService.dio.get(
          endpoint,
          queryParameters: params,
        );

        if (response.statusCode == 200) {
          final body = response.data;
          final data = body['data'] ?? body;

          if (data is Map<String, dynamic> && data.containsKey('content')) {
            return ApiResult.success(
              PageResponse.fromJson(data, AdminUserDTO.fromJson),
            );
          } else if (data is Map<String, dynamic> &&
              data.containsKey('items')) {
            // Some backends wrap list in 'items'
            final items = (data['items'] as List<dynamic>)
                .map((e) => AdminUserDTO.fromJson(e as Map<String, dynamic>))
                .toList();
            return ApiResult.success(
              PageResponse(
                content: items,
                pageNumber: page,
                pageSize: items.length,
                totalElements: items.length,
                totalPages: 1,
                last: true,
              ),
            );
          } else if (data is List) {
            final items = data
                .map((e) => AdminUserDTO.fromJson(e as Map<String, dynamic>))
                .toList();
            return ApiResult.success(
              PageResponse(
                content: items,
                pageNumber: page,
                pageSize: items.length,
                totalElements: items.length,
                totalPages: 1,
                last: true,
              ),
            );
          }
          // Unexpected response shape — try next endpoint
        }
      } catch (e) {
        lastError = e;
        // If 404 or 403, try next endpoint; otherwise stop
        final statusCode = _statusCodeOf(e);
        if (statusCode != 404 && statusCode != 403) {
          return ApiResult.fail(_extractError(e));
        }
        // Continue to next endpoint
      }
    }

    return ApiResult.fail(
      lastError != null
          ? _extractError(lastError)
          : 'Users endpoint not available',
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Warehouse / Products
  // ──────────────────────────────────────────────────────────────

  static Future<ApiResult<PageResponse<AdminWarehouseProductDTO>>>
  getWarehouseProducts({
    int page = 0,
    int size = 20,
    String sortBy = 'stockQuantity',
    String sortDir = 'ASC',
    String? search,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'size': size,
        'sortBy': sortBy,
        'sortDir': sortDir,
      };
      if (search != null && search.isNotEmpty) params['search'] = search;

      final response = await ApiService.dio.get(
        '/api/v1/products',
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data is Map<String, dynamic> && data.containsKey('content')) {
          return ApiResult.success(
            PageResponse.fromJson(data, AdminWarehouseProductDTO.fromJson),
          );
        }
      }
      return ApiResult.fail(
        response.data['message'] as String? ?? 'Failed to load products',
      );
    } catch (e) {
      return ApiResult.fail(_extractError(e));
    }
  }

  /// Update product stock via admin endpoint.
  static Future<ApiResult<bool>> updateProductStock(
    String productId,
    int newStock,
  ) async {
    try {
      // Try admin endpoint first, then fallback to general products endpoint
      final response = await ApiService.dio.patch(
        '/api/v1/admin/products/$productId/stock',
        data: {'stockQuantity': newStock},
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResult.success(true);
      }
      return ApiResult.fail(
        response.data['message'] as String? ?? 'Failed to update stock',
      );
    } catch (_) {
      // Try PUT on general products endpoint as fallback
      try {
        final fallback = await ApiService.dio.put(
          '/api/v1/products/$productId',
          data: {'stockQuantity': newStock},
        );
        if (fallback.statusCode == 200 || fallback.statusCode == 204) {
          return ApiResult.success(true);
        }
        return ApiResult.fail('Failed to update stock');
      } catch (e2) {
        return ApiResult.fail(_extractError(e2));
      }
    }
  }

  static int? _statusCodeOf(dynamic e) {
    // Works with Dio exceptions
    try {
      final str = e.toString();
      final match = RegExp(r'status(?:Code)?[:\s]+(\d{3})').firstMatch(str);
      if (match != null) return int.tryParse(match.group(1)!);
    } catch (_) {}
    return null;
  }

  static String _extractError(dynamic e) {
    final str = e.toString();
    // Try to pull a backend message field
    final msgMatch = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(str);
    if (msgMatch != null) return msgMatch.group(1)!;
    // Show HTTP status if present
    final statusMatch = RegExp(r'\[(\d{3})\]').firstMatch(str);
    if (statusMatch != null) {
      final code = statusMatch.group(1);
      if (code == '401') return 'Unauthorized — please log in again.';
      if (code == '403') return 'Access denied (403). Admin role required.';
      if (code == '404') return 'Endpoint not found (404).';
      return 'Server error ($code). Please try again.';
    }
    return 'An error occurred. Please try again.';
  }
}
