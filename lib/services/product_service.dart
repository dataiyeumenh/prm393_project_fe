import '../models/api/product_dto.dart';
import 'api_service.dart';

class ProductService {
  static Future<ApiResult<PageResponse<ProductSummaryDTO>>> getProducts({
    int? categoryId,
    int? brandId,
    int? petTypeId,
    int page = 0,
    int size = 10,
    String sortBy = 'createdAt',
    String sortDir = 'DESC',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
        'sortBy': sortBy,
        'sortDir': sortDir,
      };

      if (categoryId != null) queryParams['categoryId'] = categoryId;
      if (brandId != null) queryParams['brandId'] = brandId;
      if (petTypeId != null) queryParams['petTypeId'] = petTypeId;

      final response = await ApiService.dio.get(
        '/api/v1/products',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final pageData = PageResponse.fromJson(
          response.data['data'] as Map<String, dynamic>,
          ProductSummaryDTO.fromJson,
        );
        return ApiResult.success(pageData);
      }
      return ApiResult.fail(response.data['message'] ?? 'Failed to load products');
    } catch (e) {
      return ApiResult.fail(_extractError(e));
    }
  }

  static Future<ApiResult<ProductDetailDTO>> getProductById(String id) async {
    try {
      final response = await ApiService.dio.get('/api/v1/products/$id');

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final product = ProductDetailDTO.fromJson(data as Map<String, dynamic>);
        return ApiResult.success(product);
      }
      return ApiResult.fail(response.data['message'] ?? 'Failed to load product');
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
