import 'package:get/get.dart';
import 'package:flutter/foundation.dart';

import '../../../common/widgets/loaders/tloaders.dart';
import '../../../features/products/models/product_model.dart';
import '../../../features/products/models/product_variation_model.dart';
import '../../../main.dart';

class ProductRepository extends GetxController {
  static ProductRepository get instance => Get.find();

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
      final List<Map<String, dynamic>> products = await supabase
          .from('products')
          .select()
          .eq('ispopular', true)
          .range(offset, offset + limit - 1);

      final productModels =
          products.map((product) => ProductModel.fromJson(product)).toList();

      // Cache the results
      _productCache[cacheKey] = productModels;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return productModels;
    } catch (e) {
      TLoader.warningSnackBar(
          title: "Fetch Popular Products", message: e.toString());
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
      final List<Map<String, dynamic>> products = await supabase
          .from('products')
          .select()
          .eq('category_id', categoryId)
          .range(page * pageSize, (page + 1) * pageSize - 1);

      final productModels =
          products.map((product) => ProductModel.fromJson(product)).toList();

      // Cache the results
      _productCache[cacheKey] = productModels;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return productModels;
    } catch (e) {
      TLoader.warningSnackBar(
          title: "Fetch Category Products", message: e.toString());
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
      final List<Map<String, dynamic>> products = await supabase
          .from('products')
          .select()
          .eq('brandID', brandId)
          .limit(limit);

      final productModels =
          products.map((product) => ProductModel.fromJson(product)).toList();

      // Cache the results
      _productCache[cacheKey] = productModels;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return productModels;
    } catch (e) {
      TLoader.warningSnackBar(
          title: "Fetch Brand Products", message: e.toString());
      return [];
    }
  }

  //fetch product by product id
  Future<ProductModel> fetchProductById(int productId) async {
    try {
      final product = await supabase
          .from('products')
          .select()
          .eq('product_id', productId)
          .single();
      return ProductModel.fromJson(product);
    } catch (e) {
      TLoader.warningSnackBar(
          title: "Fetch Product By ID", message: e.toString());
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
      final List<Map<String, dynamic>> products = await supabase
          .from('products')
          .select()
          .ilike('name', '%$query%')
          .range(page * pageSize, (page + 1) * pageSize - 1);

      return products.map((product) => ProductModel.fromJson(product)).toList();
    } catch (e) {
      TLoader.warningSnackBar(title: "Search Products", message: e.toString());
      return [];
    }
  }

  // Get search suggestions for auto-complete (optimized for minimal DB calls)
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
      // Fetch limited products for suggestions (only 5-10 for efficiency)
      final List<Map<String, dynamic>> products = await supabase
          .from('products')
          .select('name')
          .ilike('name', '%$query%')
          .limit(10);

      final suggestions = products
          .map((product) => product['name'] as String)
          .toSet() // Remove duplicates
          .toList();

      // Cache as minimal ProductModel objects for consistency
      final suggestionProducts = products
          .map((product) => ProductModel(
                productId: 0,
                name: product['name'],
                description: '',
                basePrice: '0',
                salePrice: '0',
                categoryId: 0,
                brandID: 0,
                stockQuantity: 0,
                isPopular: false,
                createdAt: DateTime.now(),
                priceRange: '',
              ))
          .toList();

      _productCache[cacheKey] = suggestionProducts;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return suggestions;
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
      // Fetch all products without pagination
      final List<Map<String, dynamic>> products =
          await supabase.from('products').select();

      final productModels =
          products.map((product) => ProductModel.fromJson(product)).toList();

      // Cache the results
      _productCache[cacheKey] = productModels;
      _cacheTimestamps[cacheKey] = DateTime.now();

      if (kDebugMode) {
        print('Fetched ${productModels.length} products for POS system');
      }

      return productModels;
    } catch (e) {
      TLoader.warningSnackBar(
          title: "Fetch All Products", message: e.toString());
      return [];
    }
  }

  // Optimized method: Only fetch all products when absolutely necessary
  Future<List<ProductModel>> fetchProductTable({
    int page = 0,
    int pageSize = _defaultPageSize,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'all_products_page_$page';

    // Check cache first (unless force refresh is requested)
    if (!forceRefresh &&
        _isCacheValid(cacheKey) &&
        _productCache.containsKey(cacheKey)) {
      return _productCache[cacheKey]!;
    }

    try {
      final List<Map<String, dynamic>> products = await supabase
          .from('products')
          .select()
          .range(page * pageSize, (page + 1) * pageSize - 1);

      final productModels =
          products.map((product) => ProductModel.fromJson(product)).toList();

      // Cache the results
      _productCache[cacheKey] = productModels;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return productModels;
    } catch (e) {
      TLoader.warningSnackBar(title: "Fetch Products", message: e.toString());
      return [];
    }
  }

  //Fetch product variations by variant id
  Future<List<ProductVariationModel>> fetchProductVariationsByVariantId(
      int variantId) async {
    try {
      final cacheKey = 'variations_$variantId';
      if (_isCacheValid(cacheKey) && _variationCache.containsKey(variantId)) {
        return _variationCache[variantId]!;
      }

      final List<Map<String, dynamic>> variations = await supabase
          .from('product_variants')
          .select()
          .eq('variant_id', variantId);

      final variationModels = variations
          .map((variation) => ProductVariationModel.fromJson(variation))
          .toList();

      // Cache the results
      _variationCache[variantId] = variationModels;
      _cacheTimestamps['variations_$variantId'] = DateTime.now();

      return variationModels;
    } catch (e) {
      TLoader.warningSnackBar(
          title: "Fetch Product Variations", message: e.toString());
      return [];
    }
  }

  // Optimized product variations with caching - fetches only visible variants (regardless of stock)
  Future<List<ProductVariationModel>> fetchProductVariationsWithID(
      int productId) async {
    // Check cache first
    // if (_isCacheValid('variations_$productId') &&
    //     _variationCache.containsKey(productId)) {
    //   return _variationCache[productId]!;
    // }

    try {
      final List<Map<String, dynamic>> variations = await supabase
          .from('product_variants')
          .select()
          .eq('product_id', productId)
          .eq('is_visible', true);

      final variationModels = variations
          .map((variation) => ProductVariationModel.fromJson(variation))
          .toList();

      // Cache the results
      _variationCache[productId] = variationModels;
      _cacheTimestamps['variations_$productId'] = DateTime.now();

      return variationModels;
    } catch (e) {
      TLoader.warningSnackBar(
          title: "Fetch Product Variations", message: e.toString());
      return [];
    }
  }

  // Fetch all product variations (including out of stock and hidden) - for admin purposes
  Future<List<ProductVariationModel>> fetchAllProductVariationsWithID(
      int productId) async {
    try {
      final List<Map<String, dynamic>> variations = await supabase
          .from('product_variants')
          .select()
          .eq('product_id', productId);

      final variationModels = variations
          .map((variation) => ProductVariationModel.fromJson(variation))
          .toList();

      return variationModels;
    } catch (e) {
      TLoader.warningSnackBar(
          title: "Fetch All Product Variations", message: e.toString());
      return [];
    }
  }

  // Batch fetch multiple products by IDs (for wishlist, cart, etc.)
  Future<List<ProductModel>> fetchProductsByIds(List<int> productIds) async {
    if (productIds.isEmpty) return [];

    try {
      final List<Map<String, dynamic>> products = await supabase
          .from('products')
          .select()
          .inFilter('product_id', productIds);

      return products.map((product) => ProductModel.fromJson(product)).toList();
    } catch (e) {
      TLoader.warningSnackBar(
          title: "Fetch Products by IDs", message: e.toString());
      return [];
    }
  }

  // Get product count for pagination
  Future<int> getProductCount({int? categoryId, int? brandId}) async {
    try {
      var query = supabase.from('products').select('product_id');

      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }
      if (brandId != null) {
        query = query.eq('brandID', brandId);
      }

      final response = await query;
      return response.length;
    } catch (e) {
      return 0;
    }
  }

  // Get total count of popular products
  Future<int> getPopularProductsCount() async {
    try {
      final response = await supabase
          .from('products')
          .select('product_id')
          .eq('ispopular', true);

      return response.length;
    } catch (e) {
      TLoader.warningSnackBar(
          title: "Get Popular Products Count", message: e.toString());
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
