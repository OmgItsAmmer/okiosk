import 'package:get/get.dart';

import '../services/api_client.dart';
import '../services/product_api_service.dart';
import '../services/variation_api_service.dart';
import '../services/cart_api_service.dart';
import '../services/category_api_service.dart';
import '../services/checkout_api_service.dart';
import '../services/ai_command_service.dart';
import '../../repositories/products/backend_product_repository.dart';
import '../../repositories/cart/backend_cart_repository.dart';
import '../../repositories/categories/backend_category_repository.dart';

/// Dependency injection setup for backend services
class BackendDependencyInjection {
  static void init() {
    // Register API Client
    Get.lazyPut<ApiClient>(() => ApiClient());

    // Register API Services
    Get.lazyPut<ProductApiService>(() => ProductApiService());
    Get.lazyPut<VariationApiService>(() => VariationApiService());
    Get.lazyPut<CartApiService>(() => CartApiService());
    Get.lazyPut<CategoryApiService>(() => CategoryApiService());
    Get.lazyPut<CheckoutApiService>(() => CheckoutApiService());
    Get.lazyPut<AiCommandService>(() => AiCommandService());

    // Register Backend Repositories
    Get.lazyPut<BackendProductRepository>(() => BackendProductRepository());
    Get.lazyPut<BackendCartRepository>(() => BackendCartRepository());
    Get.put<BackendCategoryRepository>(BackendCategoryRepository());
  }

  /// Initialize with custom base URL
  static void initWithBaseUrl(String baseUrl) {
    // Register API Client with custom base URL
    Get.lazyPut<ApiClient>(() => ApiClient());

    // Register API Services
    Get.lazyPut<ProductApiService>(() => ProductApiService());
    Get.lazyPut<VariationApiService>(() => VariationApiService());
    Get.lazyPut<CartApiService>(() => CartApiService());
    Get.lazyPut<CategoryApiService>(() => CategoryApiService());
    Get.lazyPut<CheckoutApiService>(() => CheckoutApiService());
    Get.lazyPut<AiCommandService>(() => AiCommandService());

    // Register Backend Repositories
    Get.lazyPut<BackendProductRepository>(() => BackendProductRepository());
    Get.lazyPut<BackendCartRepository>(() => BackendCartRepository());
    Get.lazyPut<BackendCategoryRepository>(() => BackendCategoryRepository());
  }
}
