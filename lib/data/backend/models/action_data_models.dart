/// Action Data Models
///
/// Contains all the specific data structures for different AI action types
/// Each model represents the structured data that comes with specific actions

/// Add to Cart Action Data
///
/// Specific data structure for add_to_cart actions
class AddToCartActionData {
  final int variantId;
  final String productName;
  final String variantName;
  final int quantity;
  final int availableStock;
  final double sellPrice;
  final String? sessionId;
  final int? customerId;

  AddToCartActionData({
    required this.variantId,
    required this.productName,
    required this.variantName,
    required this.quantity,
    required this.availableStock,
    required this.sellPrice,
    this.sessionId,
    this.customerId,
  });

  factory AddToCartActionData.fromJson(Map<String, dynamic> json) {
    return AddToCartActionData(
      variantId: json['variant_id'] ?? 0,
      productName: json['product_name'] ?? '',
      variantName: json['variant_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      availableStock: json['available_stock'] ?? 0,
      sellPrice: (json['sell_price'] ?? 0.0).toDouble(),
      sessionId: json['session_id'],
      customerId: json['customer_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'variant_id': variantId,
      'product_name': productName,
      'variant_name': variantName,
      'quantity': quantity,
      'available_stock': availableStock,
      'sell_price': sellPrice,
      'session_id': sessionId,
      'customer_id': customerId,
    };
  }
}

/// Remove from Cart Action Data
///
/// Specific data structure for remove_from_cart actions
class RemoveFromCartActionData {
  final int variantId;
  final String productName;
  final String variantName;

  RemoveFromCartActionData({
    required this.variantId,
    required this.productName,
    required this.variantName,
  });

  factory RemoveFromCartActionData.fromJson(Map<String, dynamic> json) {
    return RemoveFromCartActionData(
      variantId: json['variant_id'] ?? 0,
      productName: json['product_name'] ?? '',
      variantName: json['variant_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'variant_id': variantId,
      'product_name': productName,
      'variant_name': variantName,
    };
  }
}

/// Update Quantity Action Data
///
/// Specific data structure for update_quantity actions
class UpdateQuantityActionData {
  final int variantId;
  final String productName;
  final String variantName;
  final int quantity;
  final int availableStock;
  final double sellPrice;

  UpdateQuantityActionData({
    required this.variantId,
    required this.productName,
    required this.variantName,
    required this.quantity,
    required this.availableStock,
    required this.sellPrice,
  });

  factory UpdateQuantityActionData.fromJson(Map<String, dynamic> json) {
    return UpdateQuantityActionData(
      variantId: json['variant_id'] ?? 0,
      productName: json['product_name'] ?? '',
      variantName: json['variant_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      availableStock: json['available_stock'] ?? 0,
      sellPrice: (json['sell_price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'variant_id': variantId,
      'product_name': productName,
      'variant_name': variantName,
      'quantity': quantity,
      'available_stock': availableStock,
      'sell_price': sellPrice,
    };
  }
}

