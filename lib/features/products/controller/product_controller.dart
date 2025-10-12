import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../common/widgets/loaders/tloaders.dart';
import '../../../data/repositories/products/backend_product_repository.dart';
import '../models/product_model.dart';
import '../models/product_variation_model.dart';

class ProductController extends GetxController {
  static ProductController get instance => Get.find();
  final productRepository = Get.put(BackendProductRepository());

  // Optimized product lists
  RxList<ProductModel> popularProducts = <ProductModel>[].obs;
  RxList<ProductModel> filteredProducts = <ProductModel>[].obs;
  RxList<ProductModel> currentBrandProducts = <ProductModel>[].obs;
  RxList<ProductModel> cachedProducts = <ProductModel>[].obs;
  RxList<ProductModel> allProducts = <ProductModel>[].obs;

  // Category-based product caching
  final Map<int, RxList<ProductModel>> categoryProducts = {};

  // Current product that is being viewed or selected
  Rx<ProductModel> currentProduct = ProductModel.empty().obs;

  // Loading states
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final isSearching = false.obs;

  // Pagination tracking
  final Map<String, int> _currentPages = {};
  final Map<String, bool> _hasMoreData = {};
  final int _pageSize = 20;

  // Popular products pagination tracking
  final RxInt totalPopularProductsCount = 0.obs;
  final RxInt fetchedPopularProductsCount = 0.obs;
  final RxInt currentPopularProductsOffset = 0.obs;

  // Data loaded flags to avoid unnecessary fetches
  final RxBool popularProductsLoaded = false.obs;
  final Map<int, bool> categoryDataLoaded = {};

  // @override
  // void onInit() {

  //   super.onInit();
  // }

  //fetch required product by product id
  Future<void> fetchRequiredProductByProductId(int productId) async {
    try {
      // final product = await productRepository.fetchProductById(productId);
      final product = popularProducts
          .firstWhere((product) => product.productId == productId);
      currentProduct.value = product;
      cachedProducts.add(product);
    } catch (e) {
      TLoader.errorSnackBar(
          title: 'Product Fetch Error', message: e.toString());
    }
  }

  // Lazy load popular products only when needed
  Future<void> loadPopularProductsLazily() async {
    if (popularProductsLoaded.value) return;

    try {
      isLoading.value = true;

      // Get total count of popular products
      totalPopularProductsCount.value =
          await productRepository.getPopularProductsCount();

      // Fetch first batch of popular products
      final products = await productRepository.fetchPopularProducts(
        limit: 10,
        offset: 0,
      );

      popularProducts.assignAll(products);
      filteredProducts.assignAll(products);
      fetchedPopularProductsCount.value = products.length;
      currentPopularProductsOffset.value = 10;
      popularProductsLoaded.value = true;
    } catch (e) {
      TLoader.errorSnackBar(title: 'Oh Snap!', message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Optimized search with debouncing and caching
  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      // If query is empty, show all products for POS
      if (allProducts.isNotEmpty) {
        filteredProducts.assignAll(allProducts);
      } else {
        filteredProducts.assignAll(popularProducts);
      }
      return;
    }

    try {
      isSearching.value = true;

      // First check if we can filter from existing all products (for POS)
      if (allProducts.isNotEmpty) {
        final localResults = allProducts
            .where((product) =>
                product.name.toLowerCase().contains(query.toLowerCase()) ||
                (product.description
                        ?.toLowerCase()
                        .contains(query.toLowerCase()) ??
                    false))
            .toList();

        if (localResults.isNotEmpty) {
          filteredProducts.assignAll(localResults);
          return;
        }
      }

      // If no local results, search database
      final searchResults =
          await productRepository.searchProducts(query, page: 0);
      filteredProducts.assignAll(searchResults);
    } catch (e) {
      TLoader.errorSnackBar(title: 'Search Error', message: e.toString());
    } finally {
      isSearching.value = false;
    }
  }

  // Lazy load products by category with pagination
  Future<void> loadProductsByCategory(int categoryId,
      {bool loadMore = false}) async {
    final cacheKey = 'category_$categoryId';

    // Initialize if not exists
    if (!categoryProducts.containsKey(categoryId)) {
      categoryProducts[categoryId] = <ProductModel>[].obs;
      _currentPages[cacheKey] = 0;
      _hasMoreData[cacheKey] = true;
      categoryDataLoaded[categoryId] = false;
    }

    // Skip if already loaded and not loading more
    if (categoryDataLoaded[categoryId]! && !loadMore) return;

    // Skip if no more data available
    if (loadMore && !_hasMoreData[cacheKey]!) return;

    try {
      if (loadMore) {
        isLoadingMore.value = true;
      } else {
        isLoading.value = true;
      }

      final currentPage = _currentPages[cacheKey]!;
      final products = await productRepository.fetchProductsByCategory(
        categoryId,
        page: currentPage,
        pageSize: _pageSize,
      );

      if (products.isEmpty) {
        _hasMoreData[cacheKey] = false;
      } else {
        if (loadMore) {
          categoryProducts[categoryId]!.addAll(products);
        } else {
          categoryProducts[categoryId]!.assignAll(products);
        }

        _currentPages[cacheKey] = currentPage + 1;
        categoryDataLoaded[categoryId] = true;

        // Check if we got fewer products than requested (indicates end of data)
        if (products.length < _pageSize) {
          _hasMoreData[cacheKey] = false;
        }
      }
    } catch (e) {
      TLoader.errorSnackBar(
          title: 'Category Load Error', message: e.toString());
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  // Get products for a specific category (lazy loading)
  RxList<ProductModel> getProductsByCategory(int categoryId) {
    if (!categoryProducts.containsKey(categoryId)) {
      loadProductsByCategory(categoryId);
      return <ProductModel>[].obs;
    }
    return categoryProducts[categoryId]!;
  }

  // Load products by brand (optimized)
  Future<void> loadProductsByBrand(int brandId) async {
    try {
      isLoading.value = true;
      final products = await productRepository.fetchProductsByBrand(brandId);
      currentBrandProducts.assignAll(products);
    } catch (e) {
      TLoader.errorSnackBar(
          title: 'Brand Products Error', message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Load more products for pagination
  Future<void> loadMoreProducts(String type,
      {int? categoryId, int? brandId}) async {
    switch (type) {
      case 'category':
        if (categoryId != null) {
          await loadProductsByCategory(categoryId, loadMore: true);
        }
        break;
      case 'popular':
        await _loadMorePopularProducts();
        break;
    }
  }

  Future<void> _loadMorePopularProducts() async {
    try {
      isLoadingMore.value = true;

      // Check if we've fetched all products
      if (fetchedPopularProductsCount.value >=
          totalPopularProductsCount.value) {
        return;
      }

      final products = await productRepository.fetchPopularProducts(
        limit: 10,
        offset: currentPopularProductsOffset.value,
      );

      if (products.isNotEmpty) {
        popularProducts.addAll(products);
        filteredProducts.addAll(products);
        fetchedPopularProductsCount.value += products.length;
        currentPopularProductsOffset.value += 10;
      }
    } catch (e) {
      TLoader.errorSnackBar(title: 'Load More Error', message: e.toString());
    } finally {
      isLoadingMore.value = false;
    }
  }

  // Check if more data is available
  bool hasMoreData(String type, {int? categoryId}) {
    switch (type) {
      case 'category':
        return categoryId != null
            ? (_hasMoreData['category_$categoryId'] ?? true)
            : false;
      case 'popular':
        return fetchedPopularProductsCount.value <
            totalPopularProductsCount.value;
      default:
        return false;
    }
  }

  // Check if all popular products have been loaded
  bool get allPopularProductsLoaded {
    return totalPopularProductsCount.value > 0 &&
        fetchedPopularProductsCount.value >= totalPopularProductsCount.value;
  }

  // Get pagination status for debugging
  String get popularProductsStatus {
    return 'Fetched: ${fetchedPopularProductsCount.value} / Total: ${totalPopularProductsCount.value}';
  }

  // Force refresh data (clear cache and reload)
  Future<void> refreshData({String? type, int? categoryId}) async {
    if (type == 'popular') {
      popularProductsLoaded.value = false;
      popularProducts.clear();
      filteredProducts.clear();
      fetchedPopularProductsCount.value = 0;
      currentPopularProductsOffset.value = 0;
      totalPopularProductsCount.value = 0;
      await loadPopularProductsLazily();
    } else if (type == 'category' && categoryId != null) {
      categoryDataLoaded[categoryId] = false;
      categoryProducts[categoryId]?.clear();
      _currentPages['category_$categoryId'] = 0;
      _hasMoreData['category_$categoryId'] = true;
      await loadProductsByCategory(categoryId);
    } else {
      // Clear all cache
      productRepository.clearCache();
      popularProductsLoaded.value = false;
      categoryDataLoaded.clear();
      categoryProducts.clear();
      _currentPages.clear();
      _hasMoreData.clear();
      fetchedPopularProductsCount.value = 0;
      currentPopularProductsOffset.value = 0;
      totalPopularProductsCount.value = 0;
      await loadPopularProductsLazily();
    }
  }

  // // Optimized method: Only fetch when needed and use smart filtering
  // void fetchCurrentBrandProducts() {
  //   try {
  //     if (brandController.currentBrand?.value == null) return;

  //     final brandId = brandController.currentBrand?.value['brandID'];
  //     if (brandId == null) return;

  //     loadProductsByBrand(brandId);
  //   } catch (e) {
  //     TLoader.errorSnackBar(
  //         title: 'Brand Product Error', message: e.toString());
  //   }
  // }

  // Preload data for better UX (call this strategically)
  Future<void> preloadCriticalData() async {
    // Preload only essential data in background
    if (!popularProductsLoaded.value) {
      await loadPopularProductsLazily();
    }
  }

  // Memory management
  void clearMemoryCache() {
    categoryProducts.clear();
    _currentPages.clear();
    _hasMoreData.clear();
    categoryDataLoaded.clear();
  }

  @override
  void onClose() {
    clearMemoryCache();
    super.onClose();
  }

  ///Services
  ///get product name from the product id
  getProductName(int? productId) {
    try {
      if (productId == null) return '';
      return popularProducts
          .firstWhere((product) => product.productId == productId)
          .name;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return '';
    }
  }

  // //get product brand from the product id
  // getProductBrand(int? productId) {
  //   try {
  //     if (productId == null) return '';
  //     return popularProducts.firstWhere((product) => product.id == productId).bra;
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print(e);
  //     }
  //     return '';
  //   }
  // }

  // New method to get product by ID from cached products or popular products
  ProductModel? getProductById(int productId) {
    try {
      return cachedProducts.firstWhere(
          (product) => product.productId == productId,
          orElse: () => popularProducts.firstWhere(
              (product) => product.productId == productId,
              orElse: () => ProductModel.empty()));
    } catch (e) {
      if (kDebugMode) {
        print('Error getting product by ID: $e');
      }
      return null;
    }
  }

  // New method to get product variant by ID
  ProductVariationModel? getProductVariantById(int? variantId) {
    if (variantId == null) return null;
    try {
      return currentProduct.value.productVariants.firstWhere(
          (variant) => variant.variantId == variantId,
          orElse: () => ProductVariationModel.empty());
    } catch (e) {
      if (kDebugMode) {
        print('Error getting product variant by ID: $e');
      }
      return null;
    }
  }

  // POS System Methods
  /// Load all products for POS system
  Future<void> loadAllProductsForPOS() async {
    try {
      isLoading.value = true;

      if (kDebugMode) {
        print('Loading all products for POS...');
      }

      // Fetch ALL products from the database (not just popular ones)
      final products = await productRepository.fetchAllProductsForPOS();

      if (kDebugMode) {
        print('Fetched ${products.length} products from database');
      }

      // Assign products to both allProducts and filteredProducts for POS
      allProducts.assignAll(products);
      filteredProducts.assignAll(products);

      if (kDebugMode) {
        print('POS Products loaded: ${products.length} products');
        print('allProducts length: ${allProducts.length}');
        print('filteredProducts length: ${filteredProducts.length}');

        // Print first few products for debugging
        if (products.isNotEmpty) {
          print('Sample products:');
          for (int i = 0;
              i < (products.length > 3 ? 3 : products.length);
              i++) {
            final product = products[i];
            print(
                '  ${i + 1}. ${product.name} (ID: ${product.productId}, Category: ${product.categoryId})');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading POS products: $e');
      }
      TLoader.errorSnackBar(
          title: 'Error', message: 'Failed to load products: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// Get all products for POS system
  List<ProductModel> get allProductsForPOS => allProducts;

  /// Get filtered products for POS system
  List<ProductModel> get filteredProductsForPOS => filteredProducts;

  /// Set products for category filtering (called by CategoryController)
  void setProductsForCategoryFiltering(List<ProductModel> products) {
    filteredProducts.assignAll(products);
  }

  /// Fetch product variations by product ID
  Future<List<ProductVariationModel>> fetchProductVariations(
      int productId) async {
    try {
      if (kDebugMode) {
        print('Fetching variations for product ID: $productId');
      }

      final variations =
          await productRepository.fetchProductVariationsWithID(productId);

      if (kDebugMode) {
        print('Fetched ${variations.length} variations for product $productId');
        if (variations.isNotEmpty) {
          print(
              'Sample variation: ${variations.first.variantName} (Price: ${variations.first.sellPrice}, Stock: ${variations.first.stockQuantity})');
        }
      }

      return variations;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching variations for product $productId: $e');
      }
      TLoader.errorSnackBar(
          title: 'Error',
          message: 'Failed to fetch product variations: ${e.toString()}');
      return [];
    }
  }
}
