/// Backend API model for Product
class ProductApiModel {
  final int id;
  final String name;
  final String? description;
  final String basePrice;
  final String? salePrice;
  final int categoryId;
  final int? brandId;
  final int stockQuantity;
  final bool isPopular;
  final DateTime createdAt;
  final String? priceRange;
  final String? imageUrl;
  final bool isVisible;
  final Map<String, dynamic>? metadata;

  const ProductApiModel({
    required this.id,
    required this.name,
    this.description,
    required this.basePrice,
    this.salePrice,
    required this.categoryId,
    this.brandId,
    required this.stockQuantity,
    required this.isPopular,
    required this.createdAt,
    this.priceRange,
    this.imageUrl,
    required this.isVisible,
    this.metadata,
  });

  factory ProductApiModel.fromJson(Map<String, dynamic> json) {
    // Helper function to get value with multiple possible key names
    dynamic getValueMultiple(List<String> possibleKeys) {
      for (var key in possibleKeys) {
        if (json.containsKey(key) && json[key] != null) {
          return json[key];
        }
      }
      return null;
    }

    // Helper to convert to string if needed
    String toStringValue(dynamic value, String defaultValue) {
      if (value == null) return defaultValue;
      return value.toString();
    }

    // Helper to convert to int if needed
    int toIntValue(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      if (value is double) return value.toInt();
      return defaultValue;
    }

    // Helper to convert to bool if needed
    bool toBoolValue(dynamic value, bool defaultValue) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) {
        return value.toLowerCase() == 'true' || value == '1';
      }
      return defaultValue;
    }

    return ProductApiModel(
      // Backend uses 'product_id' or 'id'
      id: toIntValue(getValueMultiple(['product_id', 'id']), 0),

      name: toStringValue(json['name'], ''),

      description: json['description']?.toString(),

      // Backend uses 'base_price'
      basePrice: toStringValue(
        getValueMultiple(['base_price', 'basePrice']),
        '0',
      ),

      // Backend uses 'sale_price'
      salePrice: getValueMultiple(['sale_price', 'salePrice'])?.toString(),

      // Backend uses 'category_id'
      categoryId: toIntValue(
        getValueMultiple(['category_id', 'categoryId']),
        0,
      ),

      // Backend uses 'brandID' (mixed case!)
      brandId: getValueMultiple(['brandID', 'brand_id', 'brandId']) != null
          ? toIntValue(getValueMultiple(['brandID', 'brand_id', 'brandId']), 0)
          : null,

      // Backend uses 'stock_quantity'
      stockQuantity: toIntValue(
        getValueMultiple(['stock_quantity', 'stockQuantity']),
        0,
      ),

      // Backend uses 'ispopular' (lowercase!)
      isPopular: toBoolValue(
        getValueMultiple(['ispopular', 'isPopular', 'is_popular']),
        false,
      ),

      // Backend uses 'created_at'
      createdAt: DateTime.tryParse(
            getValueMultiple(['created_at', 'createdAt'])?.toString() ?? '',
          ) ??
          DateTime.now(),

      // Backend uses 'price_range'
      priceRange: getValueMultiple(['price_range', 'priceRange'])?.toString(),

      // Backend uses 'image_url'
      imageUrl: getValueMultiple(['image_url', 'imageUrl'])?.toString(),

      // Backend uses 'isVisible' (camelCase)
      isVisible: toBoolValue(
        getValueMultiple(['isVisible', 'is_visible']),
        true,
      ),

      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'basePrice': basePrice,
      'salePrice': salePrice,
      'categoryId': categoryId,
      'brandId': brandId,
      'stockQuantity': stockQuantity,
      'isPopular': isPopular,
      'createdAt': createdAt.toIso8601String(),
      'priceRange': priceRange,
      'imageUrl': imageUrl,
      'isVisible': isVisible,
      'metadata': metadata,
    };
  }
}

/// Backend API model for Product Variation
class ProductVariationApiModel {
  final int variantId;
  final String sellPrice;
  final String? buyPrice;
  final int productId;
  final String? variantName;
  final int stock;
  final bool isVisible;

  const ProductVariationApiModel({
    required this.variantId,
    required this.sellPrice,
    this.buyPrice,
    required this.productId,
    this.variantName,
    required this.stock,
    required this.isVisible,
  });

  factory ProductVariationApiModel.fromJson(Map<String, dynamic> json) {
    // Helper function to get value with multiple possible key names
    dynamic getValueMultiple(List<String> possibleKeys) {
      for (var key in possibleKeys) {
        if (json.containsKey(key) && json[key] != null) {
          return json[key];
        }
      }
      return null;
    }

    // Helper to convert to string if needed
    String toStringValue(dynamic value, String defaultValue) {
      if (value == null) return defaultValue;
      return value.toString();
    }

    // Helper to convert to int if needed
    int toIntValue(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      if (value is double) return value.toInt();
      return defaultValue;
    }

    // Helper to convert to bool if needed
    bool toBoolValue(dynamic value, bool defaultValue) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) {
        return value.toLowerCase() == 'true' || value == '1';
      }
      return defaultValue;
    }

    return ProductVariationApiModel(
      // Backend uses 'variant_id'
      variantId: toIntValue(
        getValueMultiple(['variant_id', 'variantId', 'id']),
        0,
      ),

      // Backend uses 'sell_price'
      sellPrice: toStringValue(
        getValueMultiple(['sell_price', 'sellPrice']),
        '0',
      ),

      // Backend uses 'buy_price'
      buyPrice: getValueMultiple(['buy_price', 'buyPrice'])?.toString(),

      // Backend uses 'product_id'
      productId: toIntValue(
        getValueMultiple(['product_id', 'productId']),
        0,
      ),

      // Backend uses 'variant_name'
      variantName:
          getValueMultiple(['variant_name', 'variantName'])?.toString(),

      // Backend uses 'stock'
      stock: toIntValue(
        getValueMultiple(['stock', 'stockQuantity', 'stock_quantity']),
        0,
      ),

      // Backend uses 'is_visible'
      isVisible: toBoolValue(
        getValueMultiple(['is_visible', 'isVisible']),
        true,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'variant_id': variantId,
      'sell_price': sellPrice,
      'buy_price': buyPrice,
      'product_id': productId,
      'variant_name': variantName,
      'stock': stock,
      'is_visible': isVisible,
    };
  }
}

/// Backend API model for Product Stats
class ProductStatsApiModel {
  final int totalProducts;
  final int popularProducts;
  final int outOfStockProducts;
  final int lowStockProducts;
  final int totalVariations;
  final Map<String, int> categoryCounts;
  final Map<String, int> brandCounts;

  const ProductStatsApiModel({
    required this.totalProducts,
    required this.popularProducts,
    required this.outOfStockProducts,
    required this.lowStockProducts,
    required this.totalVariations,
    required this.categoryCounts,
    required this.brandCounts,
  });

  factory ProductStatsApiModel.fromJson(Map<String, dynamic> json) {
    return ProductStatsApiModel(
      totalProducts: json['totalProducts'] ?? 0,
      popularProducts: json['popularProducts'] ?? 0,
      outOfStockProducts: json['outOfStockProducts'] ?? 0,
      lowStockProducts: json['lowStockProducts'] ?? 0,
      totalVariations: json['totalVariations'] ?? 0,
      categoryCounts: json['categoryCounts'] != null
          ? Map<String, int>.from(json['categoryCounts'])
          : {},
      brandCounts: json['brandCounts'] != null
          ? Map<String, int>.from(json['brandCounts'])
          : {},
    );
  }
}

/// Backend API model for Related Variations
class RelatedVariationApiModel {
  final int id;
  final String variantName;
  final String price;
  final String? salePrice;
  final int stockQuantity;
  final bool isVisible;
  final String? imageUrl;

  const RelatedVariationApiModel({
    required this.id,
    required this.variantName,
    required this.price,
    this.salePrice,
    required this.stockQuantity,
    required this.isVisible,
    this.imageUrl,
  });

  factory RelatedVariationApiModel.fromJson(Map<String, dynamic> json) {
    return RelatedVariationApiModel(
      id: json['id'] ?? 0,
      variantName: json['variantName'] ?? '',
      price: json['price'] ?? '0',
      salePrice: json['salePrice'],
      stockQuantity: json['stockQuantity'] ?? 0,
      isVisible: json['isVisible'] ?? true,
      imageUrl: json['imageUrl'],
    );
  }
}
