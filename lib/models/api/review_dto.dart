class ProductReviewDTO {
  final String id;
  final String productId;
  final String userId;
  final String? userFullName;
  final String? userAvatarUrl;
  final double rating;
  final String comment;
  final List<String> imageUrls;
  final DateTime? createdAt;

  ProductReviewDTO({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userFullName,
    required this.userAvatarUrl,
    required this.rating,
    required this.comment,
    required this.imageUrls,
    required this.createdAt,
  });

  factory ProductReviewDTO.fromJson(Map<String, dynamic> json) {
    final rawImages = json['imageUrls'];
    return ProductReviewDTO(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userFullName: json['userFullName']?.toString(),
      userAvatarUrl: json['userAvatarUrl']?.toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      comment: json['comment']?.toString() ?? '',
      imageUrls: rawImages is List
          ? rawImages.map((e) => e.toString()).toList()
          : <String>[],
      createdAt: _tryParseDate(json['createdAt']),
    );
  }
}

class ProductReviewPageDTO {
  final double averageRating;
  final List<ProductReviewDTO> reviews;
  final int currentPage;
  final int totalPages;

  ProductReviewPageDTO({
    required this.averageRating,
    required this.reviews,
    required this.currentPage,
    required this.totalPages,
  });

  factory ProductReviewPageDTO.fromJson(Map<String, dynamic> json) {
    final rawReviews = json['reviews'];
    return ProductReviewPageDTO(
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      reviews: rawReviews is List
          ? rawReviews
                .whereType<Map<String, dynamic>>()
                .map(ProductReviewDTO.fromJson)
                .toList()
          : <ProductReviewDTO>[],
      currentPage: json['currentPage'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }
}

class ReviewUploadImage {
  final List<int> bytes;
  final String fileName;

  ReviewUploadImage({required this.bytes, required this.fileName});
}

DateTime? _tryParseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}
