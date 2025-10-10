import 'package:get/get.dart';
import 'package:flutter/foundation.dart';

import '../../../common/widgets/loaders/tloaders.dart';
import '../../../features/products/models/product_model.dart';
import '../../../features/products/models/product_variation_model.dart';
import '../../backend/services/product_api_service.dart';
import '../../backend/services/variation_api_service.dart';
import '../../backend/models/product_api_models.dart';

/// Backend-based Product Repository using API services instead of direct Supabase
class BackendProductRepository extends GetxController {
  static BackendProductRepository get instance => Get.find();

  // API Services
  final ProductApiService _productApiService = Get.find<ProductApiService>();
  final VariationApiService _variationApiService =
      Get.find<VariationApiService>();

  // Cache mechanisms
  final Map<String, List<ProductModel>> _productCache = {};
  final Map<int, List<ProductVariationModel>> _variationCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // Cache expiry time (30 minutes)
  static const Duration _cacheExpiry = Duration(minutes: 30);

  // Pagination parameters
  static const int _defaultPageSize = 20;

  // Helper method to check if cache is valid
  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  // Clear expired cache entries
  void _clearExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = _cacheTimestamps.entries
        .where((entry) => now.difference(entry.value) >= _cacheExpiry)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _productCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  // Convert API model to domain model
  ProductModel _convertApiModelToProduct(ProductApiModel apiModel) {
    return ProductModel(
      productId: apiModel.id,
      name: apiModel.name,
      description: apiModel.description,
      basePrice: apiModel.basePrice,
      salePrice: apiModel.salePrice ?? '', // Handle nullable salePrice
      categoryId: apiModel.categoryId,
      brandID: apiModel.brandId,
      stockQuantity: apiModel.stockQuantity,
      isPopular: apiModel.isPopular,
      createdAt: apiModel.createdAt,
      priceRange: apiModel.priceRange ?? '', // Handle nullable priceRange
      productVariants: [], // Will be populated separately if needed
    );
  }

  // Convert API variation model to domain model
  ProductVariationModel _convertApiVariationToVariation(
      ProductVariationApiModel apiModel) {
    return ProductVariationModel(
      variantId: apiModel.id,
      productId: apiModel.productId,
      variantName: apiModel.variantName,
      sellPrice: apiModel.price, // Map price to sellPrice
      buyPrice: apiModel.salePrice, // Map salePrice to buyPrice
      stockQuantity: apiModel.stockQuantity.toString(),
      isVisible: apiModel.isVisible,
    );
  }

  // Fetch popular products with caching and pagination
  Future<List<ProductModel>> fetchPopularProducts({
    int limit = 10,
    int offset = 0,
  }) async {
    final cacheKey = 'popular_products_offset_$offset';

    // Check cache first
    if (_isCacheValid(cacheKey) && _productCache.containsKey(cacheKey)) {
      return _productCache[cacheKey]!;
    }

    try {
      final response = await _productApiService.getPopularProducts(
        limit: limit,
        offset: offset,
      );

      if (response.success) {
        final productModels = response.data
            .map((apiModel) => _convertApiModelToProduct(apiModel))
            .toList();

        // Cache the results
        _productCache[cacheKey] = productModels;
        _cacheTimestamps[cacheKey] = DateTime.now();

        return productModels;
      } else {
        TLoader.warningSnackBar(
          title: "Fetch Popular Products",
          message: response.message,
        );
        return [];
      }
    } catch (e) {
      TLoader.warningSnackBar(
        title: "Fetch Popular Products",
        message: e.toString(),
      );
      return [];
    }
  }

  // Fetch products by category with pagination and caching
  Future<List<ProductModel>> fetchProductsByCategory(
    int categoryId, {
    int page = 0,
    int pageSize = _defaultPageSize,
  }) async {
    final cacheKey = 'category_${categoryId}_page_$page';

    // Check cache first
    if (_isCacheValid(cacheKey) && _productCache.containsKey(cacheKey)) {
      return _productCache[cacheKey]!;
    }

    try {
      final response =
          await _productApiService.getProductsByCategory(categoryId);

      if (response.success && response.data != null) {
        final productModels = response.data!
            .map((apiModel) => _convertApiModelToProduct(apiModel))
            .toList();

        // Cache the results
        _productCache[cacheKey] = productModels;
        _cacheTimestamps[cacheKey] = DateTime.now();

        return productModels;
      } else {
        TLoader.warningSnackBar(
          title: "Fetch Category Products",
          message: response.message,
        );
        return [];
      }
    } catch (e) {
      TLoader.warningSnackBar(
        title: "Fetch Category Products",
        message: e.toString(),
      );
      return [];
    }
  }

  // Fetch products by brand with caching
  Future<List<ProductModel>> fetchProductsByBrand(
    int brandId, {
    int limit = 50,
  }) async {
    final cacheKey = 'brand_$brandId';

    // Check cache first
    if (_isCacheValid(cacheKey) && _productCache.containsKey(cacheKey)) {
      return _productCache[cacheKey]!;
    }

    try {
      final response = await _productApiService.getProductsByBrand(brandId);

      if (response.success && response.data != null) {
        final productModels = response.data!
            .map((apiModel) => _convertApiModelToProduct(apiModel))
            .toList();

        // Cache the results
        _productCache[cacheKey] = productModels;
        _cacheTimestamps[cacheKey] = DateTime.now();

        return productModels;
      } else {
        TLoader.warningSnackBar(
          title: "Fetch Brand Products",
          message: response.message,
        );
        return [];
      }
    } catch (e) {
      TLoader.warningSnackBar(
        title: "Fetch Brand Products",
        message: e.toString(),
      );
      return [];
    }
  }

  // Fetch product by product ID
  Future<ProductModel> fetchProductById(int productId) async {
    try {
      final response = await _productApiService.getProductById(productId);

      if (response.success && response.data != null) {
        return _convertApiModelToProduct(response.data!);
      } else {
        TLoader.warningSnackBar(
          title: "Fetch Product By ID",
          message: response.message,
        );
        return ProductModel.empty();
      }
    } catch (e) {
      TLoader.warningSnackBar(
        title: "Fetch Product By ID",
        message: e.toString(),
      );
      return ProductModel.empty();
    }
  }

  // Search products with pagination
  Future<List<ProductModel>> searchProducts(
    String query, {
    int page = 0,
    int pageSize = _defaultPageSize,
  }) async {
    if (query.isEmpty) return [];

    try {
      final response = await _productApiService.searchProducts(query);

      if (response.success && response.data != null) {
        return response.data!
            .map((apiModel) => _convertApiModelToProduct(apiModel))
            .toList();
      } else {
        TLoader.warningSnackBar(
          title: "Search Products",
          message: response.message,
        );
        return [];
      }
    } catch (e) {
      TLoader.warningSnackBar(
        title: "Search Products",
        message: e.toString(),
      );
      return [];
    }
  }

  // Get search suggestions for auto-complete (optimized for minimal API calls)
  Future<List<String>> getSearchSuggestions(String query) async {
    if (query.isEmpty || query.length < 2) return [];

    final cacheKey = 'suggestions_$query';

    // Check cache first
    if (_isCacheValid(cacheKey)) {
      final cachedProducts = _productCache[cacheKey];
      if (cachedProducts != null) {
        return cachedProducts.map((p) => p.name).toList();
      }
    }

    try {
      final response = await _productApiService.searchProducts(query);

      if (response.success && response.data != null) {
        final suggestions = response.data!
            .map((apiModel) => apiModel.name)
            .toSet() // Remove duplicates
            .toList();

        // Cache as minimal ProductModel objects for consistency
        final suggestionProducts = response.data!
            .map((apiModel) => _convertApiModelToProduct(apiModel))
            .toList();

        _productCache[cacheKey] = suggestionProducts;
        _cacheTimestamps[cacheKey] = DateTime.now();

        return suggestions;
      } else {
        return [];
      }
    } catch (e) {
      // Silent fail for suggestions to not interrupt user experience
      return [];
    }
  }

  // Fetch ALL products without pagination (for POS system)
  Future<List<ProductModel>> fetchAllProductsForPOS() async {
    final cacheKey = 'all_products_pos';

    // Check cache first
    if (_isCacheValid(cacheKey) && _productCache.containsKey(cacheKey)) {
      return _productCache[cacheKey]!;
    }

    try {
      final response = await _productApiService.getAllProductsForPOS();

      if (response.success && response.data != null) {
        final productModels = response.data!
            .map((apiModel) => _convertApiModelToProduct(apiModel))
            .toList();

        // Cache the results
        _productCache[cacheKey] = productModels;
        _cacheTimestamps[cacheKey] = DateTime.now();

        if (kDebugMode) {
          print('Fetched ${productModels.length} products for POS system');
        }

        return productModels;
      } else {
        TLoader.warningSnackBar(
          title: "Fetch All Products",
          message: response.message,
        );
        return [];
      }
    } catch (e) {
      TLoader.warningSnackBar(
        title: "Fetch All Products",
        message: e.toString(),
      );
      return [];
    }
  }

  // Fetch product variations by variant ID
  Future<List<ProductVariationModel>> fetchProductVariationsByVariantId(
      int variantId) async {
    try {
      final cacheKey = 'variations_$variantId';
      if (_isCacheValid(cacheKey) && _variationCache.containsKey(variantId)) {
        return _variationCache[variantId]!;
      }

      final response = await _variationApiService.getVariationById(variantId);

      if (response.success && response.data != null) {
        final variationModel = _convertApiVariationToVariation(response.data!);
        final variations = [variationModel];

        // Cache the results
        _variationCache[variantId] = variations;
        _cacheTimestamps['variations_$variantId'] = DateTime.now();

        return variations;
      } else {
        TLoader.warningSnackBar(
          title: "Fetch Product Variations",
          message: response.message,
        );
        return [];
      }
    } catch (e) {
      TLoader.warningSnackBar(
        title: "Fetch Product Variations",
        message: e.toString(),
      );
      return [];
    }
  }

  // Fetch product variations with product ID
  Future<List<ProductVariationModel>> fetchProductVariationsWithID(
      int productId) async {
    try {
      final response = await _productApiService.getProductVariations(productId);

      if (response.success && response.data != null) {
        final variationModels = response.data!
            .map((apiModel) => _convertApiVariationToVariation(apiModel))
            .toList();

        // Cache the results
        _variationCache[productId] = variationModels;
        _cacheTimestamps['variations_$productId'] = DateTime.now();

        return variationModels;
      } else {
        TLoader.warningSnackBar(
          title: "Fetch Product Variations",
          message: response.message,
        );
        return [];
      }
    } catch (e) {
      TLoader.warningSnackBar(
        title: "Fetch Product Variations",
        message: e.toString(),
      );
      return [];
    }
  }

  // Get total count of popular products
  Future<int> getPopularProductsCount() async {
    try {
      final response = await _productApiService.getPopularProductsCount();

      if (response.success && response.data != null) {
        return response.data!;
      } else {
        TLoader.warningSnackBar(
          title: "Get Popular Products Count",
          message: response.message,
        );
        return 0;
      }
    } catch (e) {
      TLoader.warningSnackBar(
        title: "Get Popular Products Count",
        message: e.toString(),
      );
      return 0;
    }
  }

  // Clear all cache
  void clearCache() {
    _productCache.clear();
    _variationCache.clear();
    _cacheTimestamps.clear();
  }

  // Clear specific cache
  void clearCacheByKey(String pattern) {
    final keysToRemove =
        _productCache.keys.where((key) => key.contains(pattern)).toList();
    for (final key in keysToRemove) {
      _productCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Clear expired cache periodically
    ever(RxBool(true), (_) {
      Future.delayed(const Duration(minutes: 5), () {
        _clearExpiredCache();
      });
    });
  }
}
