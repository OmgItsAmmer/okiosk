class OrderItemModel {
  final int productId;
  final double price;
  final int quantity;
  final int orderId;
  final String? unit;
  final double totalBuyPrice;
  final DateTime? createdAt;
  final int? variantId;

  OrderItemModel({
    required this.productId,
    required this.price,
    required this.quantity,
    required this.orderId,
    this.unit,
    this.totalBuyPrice = 0.0,
    this.createdAt,
    this.variantId,
  });

  // Static function to create an empty order item model
  static OrderItemModel empty() => OrderItemModel(
        productId: 0,
        price: 0.0,
        quantity: 0,
        orderId: 0,
        unit: null,
        totalBuyPrice: 0.0,
        createdAt: null,
        variantId: null,
      );

  // Convert model to JSON for database insertion
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'product_id': productId,
      'price': price,
      'quantity': quantity,
      'order_id': orderId,
      'unit': unit,
      'total_buy_price': totalBuyPrice,
    };

    if (createdAt != null) {
      data['created_at'] = createdAt?.toIso8601String();
    }

    if (variantId != null) {
      data['variant_id'] = variantId;
    }

    return data;
  }

  // Factory method to create an OrderItemModel from JSON response
  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json['product_id'] as int,
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price'].toString()) ?? 0.0,
      quantity: json['quantity'] as int,
      orderId: json['order_id'] as int,
      unit: json['unit'] as String?,
      totalBuyPrice: json['total_buy_price'] != null
          ? (json['total_buy_price'] is num)
              ? (json['total_buy_price'] as num).toDouble()
              : double.tryParse(json['total_buy_price'].toString()) ?? 0.0
          : 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      variantId: json['variant_id'] as int?,
    );
  }

  // Method to handle a list of OrderItemModel from JSON
  static List<OrderItemModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => OrderItemModel.fromJson(json)).toList();
  }

  // CopyWith method
  OrderItemModel copyWith({
    int? productId,
    double? price,
    int? quantity,
    int? orderId,
    String? unit,
    double? totalBuyPrice,
    DateTime? createdAt,
    int? variantId,
  }) {
    return OrderItemModel(
      productId: productId ?? this.productId,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      orderId: orderId ?? this.orderId,
      unit: unit ?? this.unit,
      totalBuyPrice: totalBuyPrice ?? this.totalBuyPrice,
      createdAt: createdAt ?? this.createdAt,
      variantId: variantId ?? this.variantId,
    );
  }
}
