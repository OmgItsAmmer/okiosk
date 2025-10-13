class ProductVariationModel {
  final int variantId;
  final String sellPrice;
  final String? buyPrice;
  final int productId;
  final String? variantName;
  final String stockQuantity;
  final bool isVisible;
  final Map<String, dynamic>? attributes;

  ProductVariationModel({
    required this.variantId,
    this.sellPrice = '',
    this.buyPrice,
    required this.productId,
    this.variantName = '',
    this.stockQuantity = '',
    this.isVisible = false,
    this.attributes,
  });

  // Empty constructor
  static ProductVariationModel empty() => ProductVariationModel(
        variantId: 0,
        productId: 0,
        isVisible: false,
      );

  /// Converts the ProductVariationModel to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'variant_id': variantId,
      'sell_price': sellPrice,
      'buy_price': buyPrice,
      'product_id': productId,
      'variant_name': variantName,
      'stock': stockQuantity,
      'is_visible': isVisible,
      'attributes': attributes,
    };
  }

  /// Factory method to create a ProductVariationModel from a JSON map.
  factory ProductVariationModel.fromJson(Map<String, dynamic> data) {
    if (data.isEmpty) return ProductVariationModel.empty();

    return ProductVariationModel(
      variantId: data['variant_id'] ?? 0,
      sellPrice: data['sell_price']?.toString() ?? '',
      buyPrice: data['buy_price']?.toString(),
      productId: data['product_id'] ?? 0,
      variantName: data['variant_name'] ?? '',
      stockQuantity: data['stock']?.toString() ?? '',
      isVisible: data['is_visible'] ?? false,
      attributes: data['attributes'],
    );
  }

  void addAll(ProductVariationModel firstWhere) {}

  /// Get stock as integer (for AI action compatibility)
  int get stockAsInt {
    try {
      return int.parse(stockQuantity.isEmpty ? '0' : stockQuantity);
    } catch (e) {
      return 0;
    }
  }

  /// Get sell price as double (for AI action compatibility)
  double get sellPriceAsDouble {
    try {
      return double.parse(sellPrice.isEmpty ? '0' : sellPrice);
    } catch (e) {
      return 0.0;
    }
  }

  /// Check if variant is out of stock
  bool get isOutOfStock => stockAsInt <= 0;

  /// Get formatted price string
  String get formattedPrice => '\$${sellPriceAsDouble.toStringAsFixed(2)}';

  /// Get stock status text
  String get stockStatus {
    final stock = stockAsInt;
    if (isOutOfStock) return 'Out of Stock';
    if (stock < 5) return 'Low Stock ($stock)';
    return 'In Stock ($stock)';
  }
}
