import 'package:flutter/material.dart';

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled,
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get viLabel {
    switch (this) {
      case OrderStatus.pending:
        return 'Chờ thanh toán';
      case OrderStatus.confirmed:
        return 'Đã xác nhận';
      case OrderStatus.processing:
        return 'Đang xử lý';
      case OrderStatus.shipped:
        return 'Đang giao';
      case OrderStatus.delivered:
        return 'Đã giao';
      case OrderStatus.cancelled:
        return 'Đã huỷ';
    }
  }

  String get apiValue {
    return name.toUpperCase();
  }

  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return const Color(0xFFFF9A45);
      case OrderStatus.confirmed:
        return const Color(0xFF5B7AFE);
      case OrderStatus.processing:
        return const Color(0xFF9C7AFF);
      case OrderStatus.shipped:
        return const Color(0xFF4FB8C0);
      case OrderStatus.delivered:
        return const Color(0xFF3DAE73);
      case OrderStatus.cancelled:
        return const Color(0xFFFF5C8A);
    }
  }

  Color get bgColor {
    return color.withValues(alpha: 0.12);
  }

  static OrderStatus fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'PENDING':
        return OrderStatus.pending;
      case 'CONFIRMED':
        return OrderStatus.confirmed;
      case 'PROCESSING':
        return OrderStatus.processing;
      case 'SHIPPED':
        return OrderStatus.shipped;
      case 'DELIVERED':
        return OrderStatus.delivered;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  List<OrderStatus> get nextStatuses {
    switch (this) {
      case OrderStatus.pending:
        return [OrderStatus.confirmed, OrderStatus.cancelled];
      case OrderStatus.confirmed:
        return [OrderStatus.processing, OrderStatus.cancelled];
      case OrderStatus.processing:
        return [OrderStatus.shipped, OrderStatus.cancelled];
      case OrderStatus.shipped:
        return [OrderStatus.delivered];
      case OrderStatus.delivered:
        return [];
      case OrderStatus.cancelled:
        return [];
    }
  }
}

class OrderItemDTO {
  final String id;
  final String productId;
  final String productName;
  final String? productImageUrl;
  final int quantity;
  final double unitPrice;
  final double subTotal;

  const OrderItemDTO({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImageUrl,
    required this.quantity,
    required this.unitPrice,
    required this.subTotal,
  });

  factory OrderItemDTO.fromJson(Map<String, dynamic> json) {
    return OrderItemDTO(
      id: json['id'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? 'Unknown Product',
      productImageUrl: json['productImageUrl'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      unitPrice:
          (json['unitPrice'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ??
          0.0,
      subTotal: (json['subTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class OrderSummaryDTO {
  final String id;
  final String orderCode;
  final String customerName;
  final String customerEmail;
  final OrderStatus status;
  final double totalAmount;
  final int itemCount;
  final DateTime createdAt;

  const OrderSummaryDTO({
    required this.id,
    required this.orderCode,
    required this.customerName,
    required this.customerEmail,
    required this.status,
    required this.totalAmount,
    required this.itemCount,
    required this.createdAt,
  });

  factory OrderSummaryDTO.fromJson(Map<String, dynamic> json) {
    return OrderSummaryDTO(
      id: json['id'] as String? ?? '',
      orderCode:
          json['orderCode'] as String? ??
          json['code'] as String? ??
          '#${(json['id'] as String? ?? '').substring(0, 8)}',
      customerName:
          json['customerName'] as String? ??
          json['userName'] as String? ??
          'Unknown',
      customerEmail:
          json['customerEmail'] as String? ??
          json['userEmail'] as String? ??
          '',
      status: OrderStatusX.fromApi(json['status'] as String?),
      totalAmount:
          (json['totalAmount'] as num?)?.toDouble() ??
          (json['total'] as num?)?.toDouble() ??
          0.0,
      itemCount: json['itemCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class OrderDetailDTO {
  final String id;
  final String orderCode;
  final String customerName;
  final String customerEmail;
  final String? customerPhone;
  final String? shippingAddress;
  final OrderStatus status;
  final double totalAmount;
  final double? shippingFee;
  final List<OrderItemDTO> items;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes;

  const OrderDetailDTO({
    required this.id,
    required this.orderCode,
    required this.customerName,
    required this.customerEmail,
    this.customerPhone,
    this.shippingAddress,
    required this.status,
    required this.totalAmount,
    this.shippingFee,
    required this.items,
    required this.createdAt,
    this.updatedAt,
    this.notes,
  });

  factory OrderDetailDTO.fromJson(Map<String, dynamic> json) {
    final itemsRaw =
        json['items'] as List<dynamic>? ??
        json['orderItems'] as List<dynamic>? ??
        [];
    return OrderDetailDTO(
      id: json['id'] as String? ?? '',
      orderCode:
          json['orderCode'] as String? ??
          json['code'] as String? ??
          '#${(json['id'] as String? ?? '').substring(0, 8)}',
      customerName:
          json['customerName'] as String? ??
          json['userName'] as String? ??
          json['receiverName'] as String? ??
          'Unknown',
      customerEmail:
          json['customerEmail'] as String? ??
          json['userEmail'] as String? ??
          '',
      customerPhone:
          json['customerPhone'] as String? ?? json['phone'] as String?,
      shippingAddress:
          json['shippingAddress'] as String? ??
          json['address'] as String? ??
          json['streetAddress'] as String?,
      status: OrderStatusX.fromApi(json['status'] as String?),
      totalAmount:
          (json['totalAmount'] as num?)?.toDouble() ??
          (json['total'] as num?)?.toDouble() ??
          0.0,
      shippingFee: (json['shippingFee'] as num?)?.toDouble(),
      items: itemsRaw
          .map((e) => OrderItemDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      notes: json['notes'] as String? ?? json['note'] as String?,
    );
  }
}

class UpdateOrderStatusRequest {
  final String status;

  const UpdateOrderStatusRequest({required this.status});

  Map<String, dynamic> toJson() => {'status': status};
}

/// Body for `POST /api/v1/orders/checkout`.
class CheckoutRequest {
  final String addressId;
  final String note;

  const CheckoutRequest({required this.addressId, this.note = ''});

  Map<String, dynamic> toJson() => {'addressId': addressId, 'note': note};
}

/// Response of `GET /api/v1/payments/vnpay/create-url`.
class PaymentUrlResponse {
  final String paymentUrl;

  PaymentUrlResponse({required this.paymentUrl});

  factory PaymentUrlResponse.fromJson(Map<String, dynamic> json) {
    return PaymentUrlResponse(
      paymentUrl:
          json['paymentUrl'] as String? ?? json['url'] as String? ?? '',
    );
  }
}
