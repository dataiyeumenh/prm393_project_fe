class CartItemDTO {
  final String id;
  final String productId;
  final String productName;
  final double price;
  final String? primaryImageUrl;
  final int quantity;
  final double subTotal;

  CartItemDTO({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    this.primaryImageUrl,
    required this.quantity,
    required this.subTotal,
  });

  factory CartItemDTO.fromJson(Map<String, dynamic> json) {
    return CartItemDTO(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      price: (json['price'] as num).toDouble(),
      primaryImageUrl: json['primaryImageUrl'] as String?,
      quantity: json['quantity'] as int,
      subTotal: (json['subTotal'] as num).toDouble(),
    );
  }
}

class CartResponse {
  final List<CartItemDTO> items;
  final double totalAmount;

  CartResponse({
    required this.items,
    required this.totalAmount,
  });

  factory CartResponse.fromJson(Map<String, dynamic> json) {
    return CartResponse(
      items: (json['items'] as List<dynamic>)
          .map((e) => CartItemDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
    );
  }
}

class CartItemRequest {
  final String productId;
  final int quantity;

  CartItemRequest({required this.productId, required this.quantity});

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
    };
  }
}
