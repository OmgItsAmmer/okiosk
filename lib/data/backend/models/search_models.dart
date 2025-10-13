/// Search Models
///
/// Contains models related to search functionality in AI actions

/// Search Product Action Data
///
/// Specific data structure for search_product actions
class SearchProductActionData {
  final String query;
  final List<SearchResult> results;

  SearchProductActionData({
    required this.query,
    required this.results,
  });

  factory SearchProductActionData.fromJson(Map<String, dynamic> json) {
    return SearchProductActionData(
      query: json['query'] ?? '',
      results: json['results'] != null
          ? (json['results'] as List)
              .map((result) => SearchResult.fromJson(result))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'results': results.map((result) => result.toJson()).toList(),
    };
  }
}

/// Search Result Model
///
/// Individual search result within SearchProductActionData
class SearchResult {
  final int productId;
  final String productName;
  final int variantId;
  final String variantName;
  final double sellPrice;
  final int stock;

  SearchResult({
    required this.productId,
    required this.productName,
    required this.variantId,
    required this.variantName,
    required this.sellPrice,
    required this.stock,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      variantId: json['variant_id'] ?? 0,
      variantName: json['variant_name'] ?? '',
      sellPrice: (json['sell_price'] ?? 0.0).toDouble(),
      stock: json['stock'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'variant_id': variantId,
      'variant_name': variantName,
      'sell_price': sellPrice,
      'stock': stock,
    };
  }
}

