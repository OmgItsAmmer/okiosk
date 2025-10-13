/// Action Data Models
///
/// Contains all the specific data structures for different AI action types
/// Each model represents the structured data that comes with specific actions

import '../../../features/products/models/product_variation_model.dart';

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

/// Product Variant Alias
///
/// Using the existing ProductVariationModel for variant selection
typedef ProductVariant = ProductVariationModel;

/// Variant Selection Action Data
///
/// Data structure for variant_selection actions when user needs to choose a variant
/// Updated to match the new backend response format from CART_AI_MODULE.md
class VariantSelectionActionData {
  final int productId;
  final String productName;
  final int quantity;
  final String? sessionId;
  final int? customerId;
  final List<ProductVariant> availableVariants;

  VariantSelectionActionData({
    required this.productId,
    required this.productName,
    required this.quantity,
    this.sessionId,
    this.customerId,
    required this.availableVariants,
  });

  factory VariantSelectionActionData.fromJson(Map<String, dynamic> json) {
    return VariantSelectionActionData(
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      quantity: json['quantity'] ?? 1,
      sessionId: json['session_id'],
      customerId: json['customer_id'],
      availableVariants: json['available_variants'] != null
          ? (json['available_variants'] as List)
              .map((variant) => _convertToProductVariationModel(variant))
              .toList()
          : [],
    );
  }

  /// Convert AI response variant format to ProductVariationModel
  /// Updated to handle the new backend response structure
  static ProductVariationModel _convertToProductVariationModel(
      Map<String, dynamic> variantJson) {
    return ProductVariationModel(
      variantId: variantJson['variant_id'] ?? 0,
      productId: 0, // Not provided in AI response, will be set later if needed
      sellPrice: (variantJson['sell_price'] ?? 0.0).toString(),
      variantName: variantJson['variant_name'] ?? '',
      stockQuantity: (variantJson['stock'] ?? 0).toString(),
      isVisible: true, // Assume visible if provided by AI
      attributes: variantJson['attributes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'session_id': sessionId,
      'customer_id': customerId,
      'available_variants': availableVariants.map((v) => v.toJson()).toList(),
    };
  }

  /// Get variants that are in stock
  List<ProductVariationModel> get inStockVariants =>
      availableVariants.where((v) => !v.isOutOfStock).toList();

  /// Get variants that are out of stock
  List<ProductVariationModel> get outOfStockVariants =>
      availableVariants.where((v) => v.isOutOfStock).toList();

  /// Check if there are any available variants
  bool get hasVariants => availableVariants.isNotEmpty;

  /// Check if there are any in-stock variants
  bool get hasInStockVariants => inStockVariants.isNotEmpty;

  /// Get the total number of variants
  int get totalVariants => availableVariants.length;

  /// Get variant by ID
  ProductVariationModel? getVariantById(int variantId) {
    try {
      return availableVariants.firstWhere((v) => v.variantId == variantId);
    } catch (e) {
      return null;
    }
  }

  /// Get variant by name (case-insensitive)
  ProductVariationModel? getVariantByName(String variantName) {
    try {
      return availableVariants.firstWhere(
        (v) =>
            (v.variantName?.toLowerCase() ?? '') == variantName.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
}
