class ProductSummaryDTO {
  final String id;
  final String name;
  final double price;
  final String? primaryImageUrl;
  final String? brandName;
  final int stockQuantity;

  ProductSummaryDTO({
    required this.id,
    required this.name,
    required this.price,
    this.primaryImageUrl,
    this.brandName,
    required this.stockQuantity,
  });

  factory ProductSummaryDTO.fromJson(Map<String, dynamic> json) {
    return ProductSummaryDTO(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      primaryImageUrl: json['primaryImageUrl'] as String?,
      brandName: json['brandName'] as String?,
      stockQuantity: json['stockQuantity'] as int,
    );
  }
}

class ProductImageDTO {
  final String id;
  final String imageUrl;
  final bool isPrimary;

  ProductImageDTO({
    required this.id,
    required this.imageUrl,
    required this.isPrimary,
  });

  factory ProductImageDTO.fromJson(Map<String, dynamic> json) {
    return ProductImageDTO(
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String,
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }
}

class ProductDetailDTO {
  final String id;
  final String name;
  final String? description;
  final double price;
  final int stockQuantity;
  final String? sku;
  final String? categoryName;
  final String? brandName;
  final String? petTypeName;
  final List<ProductImageDTO> images;

  ProductDetailDTO({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stockQuantity,
    this.sku,
    this.categoryName,
    this.brandName,
    this.petTypeName,
    required this.images,
  });

  factory ProductDetailDTO.fromJson(Map<String, dynamic> json) {
    return ProductDetailDTO(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      stockQuantity: json['stockQuantity'] as int,
      sku: json['sku'] as String?,
      categoryName: json['categoryName'] as String?,
      brandName: json['brandName'] as String?,
      petTypeName: json['petTypeName'] as String?,
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => ProductImageDTO.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String? get primaryImageUrl {
    final primary = images.where((img) => img.isPrimary).firstOrNull;
    return primary?.imageUrl ?? images.firstOrNull?.imageUrl;
  }
}

class PageResponse<T> {
  final List<T> content;
  final int pageNumber;
  final int pageSize;
  final int totalElements;
  final int totalPages;
  final bool last;

  PageResponse({
    required this.content,
    required this.pageNumber,
    required this.pageSize,
    required this.totalElements,
    required this.totalPages,
    required this.last,
  });

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final rawContent = json['content'] as List<dynamic>? ?? [];
    return PageResponse(
      content: rawContent
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      pageNumber:
          json['pageNumber'] as int? ??
          json['number'] as int? ??
          json['page'] as int? ??
          0,
      pageSize:
          json['pageSize'] as int? ?? json['size'] as int? ?? rawContent.length,
      totalElements:
          json['totalElements'] as int? ??
          json['totalItems'] as int? ??
          rawContent.length,
      totalPages: json['totalPages'] as int? ?? json['pages'] as int? ?? 1,
      last: json['last'] as bool? ?? json['isLast'] as bool? ?? true,
    );
  }
}
