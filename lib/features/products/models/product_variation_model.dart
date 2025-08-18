class ProductVariationModel {
  final int variantId;
  final String sellPrice;
  final String? buyPrice;
  final int productId;
  final String? variantName;
  final String stockQuantity;
  final bool isVisible;

  ProductVariationModel({
    required this.variantId,
    this.sellPrice = '',
    this.buyPrice,
    required this.productId,
    this.variantName = '',
    this.stockQuantity = '',
    this.isVisible = false,
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
    );
  }

  void addAll(ProductVariationModel firstWhere) {}
}
