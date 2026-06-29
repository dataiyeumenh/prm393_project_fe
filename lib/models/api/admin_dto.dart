class DashboardStatsDTO {
  final int totalOrders;
  final int pendingOrders;
  final double totalRevenue;
  final int totalUsers;
  final int lowStockProducts;
  final int totalProducts;

  const DashboardStatsDTO({
    required this.totalOrders,
    required this.pendingOrders,
    required this.totalRevenue,
    required this.totalUsers,
    required this.lowStockProducts,
    required this.totalProducts,
  });

  factory DashboardStatsDTO.fromJson(Map<String, dynamic> json) {
    return DashboardStatsDTO(
      totalOrders:
          json['totalOrders'] as int? ?? json['orderCount'] as int? ?? 0,
      pendingOrders:
          json['pendingOrders'] as int? ??
          json['pendingOrderCount'] as int? ??
          0,
      totalRevenue:
          (json['totalRevenue'] as num?)?.toDouble() ??
          (json['revenue'] as num?)?.toDouble() ??
          0.0,
      totalUsers: json['totalUsers'] as int? ?? json['userCount'] as int? ?? 0,
      lowStockProducts:
          json['lowStockProducts'] as int? ??
          json['lowStockCount'] as int? ??
          0,
      totalProducts:
          json['totalProducts'] as int? ?? json['productCount'] as int? ?? 0,
    );
  }

  factory DashboardStatsDTO.empty() => const DashboardStatsDTO(
    totalOrders: 0,
    pendingOrders: 0,
    totalRevenue: 0,
    totalUsers: 0,
    lowStockProducts: 0,
    totalProducts: 0,
  );
}

class AdminUserDTO {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final bool active;
  final DateTime? createdAt;

  const AdminUserDTO({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    required this.active,
    this.createdAt,
  });

  factory AdminUserDTO.fromJson(Map<String, dynamic> json) {
    return AdminUserDTO(
      id: json['id'] as String? ?? '',
      fullName:
          json['fullName'] as String? ?? json['name'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'USER',
      active:
          json['isActive'] as bool? ??
          json['active'] as bool? ??
          json['enabled'] as bool? ??
          true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  // Handles both 'ADMIN' and 'ROLE_ADMIN' formats
  bool get isAdmin {
    final r = role.toUpperCase();
    return r == 'ADMIN' || r == 'ROLE_ADMIN';
  }
}

class AdminWarehouseProductDTO {
  final String id;
  final String name;
  final String? sku;
  final double price;
  final int stockQuantity;
  final String? categoryName;
  final String? brandName;
  final String? primaryImageUrl;

  const AdminWarehouseProductDTO({
    required this.id,
    required this.name,
    this.sku,
    required this.price,
    required this.stockQuantity,
    this.categoryName,
    this.brandName,
    this.primaryImageUrl,
  });

  factory AdminWarehouseProductDTO.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List<dynamic>?;
    String? imageUrl = json['primaryImageUrl'] as String?;
    if (imageUrl == null && images != null && images.isNotEmpty) {
      for (final img in images) {
        final m = img as Map<String, dynamic>;
        if (m['isPrimary'] == true) {
          imageUrl = m['imageUrl'] as String?;
          break;
        }
      }
      imageUrl ??=
          (images.first as Map<String, dynamic>)['imageUrl'] as String?;
    }

    return AdminWarehouseProductDTO(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      sku: json['sku'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: json['stockQuantity'] as int? ?? 0,
      categoryName: json['categoryName'] as String?,
      brandName: json['brandName'] as String?,
      primaryImageUrl: imageUrl,
    );
  }

  StockLevel get stockLevel {
    if (stockQuantity == 0) return StockLevel.outOfStock;
    if (stockQuantity <= 10) return StockLevel.low;
    if (stockQuantity <= 50) return StockLevel.medium;
    return StockLevel.good;
  }
}

enum StockLevel { outOfStock, low, medium, good }

extension StockLevelX on StockLevel {
  String get label {
    switch (this) {
      case StockLevel.outOfStock:
        return 'Out of stock';
      case StockLevel.low:
        return 'Low';
      case StockLevel.medium:
        return 'Medium';
      case StockLevel.good:
        return 'Good';
    }
  }
}
