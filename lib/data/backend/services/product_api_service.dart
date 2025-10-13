import 'package:get/get.dart';
import 'package:flutter/foundation.dart';

import '../models/api_response.dart';
import '../models/product_api_models.dart';
import 'api_client.dart';

/// Service class for Product API operations
class ProductApiService extends GetxService {
  static ProductApiService get instance => Get.find();

  final ApiClient _apiClient = ApiClient();

  /// Get popular products count
  Future<ApiResponse<int>> getPopularProductsCount() async {
    try {
      final response = await _apiClient.get<int>(
        '/api/products/popular/count',
        fromJson: (data) => data as int,
      );
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Get popular products count error: $e');
      }
      return ApiResponse<int>(
        success: false,
        message: 'Failed to get popular products count',
      );
    }
  }

  /// Get popular products with pagination
  Future<PaginatedApiResponse<ProductApiModel>> getPopularProducts({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/products/popular',
        queryParams: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.success && response.data != null) {
        return PaginatedApiResponse<ProductApiModel>.fromJson(
          response.data!,
          (data) => ProductApiModel.fromJson(data),
        );
      } else {
        return PaginatedApiResponse<ProductApiModel>(
          success: false,
          message: response.message,
          data: [],
          pagination: const PaginationMeta(
            currentPage: 1,
            totalPages: 1,
            totalItems: 0,
            itemsPerPage: 10,
            hasNextPage: false,
            hasPreviousPage: false,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Get popular products error: $e');
      }
      return PaginatedApiResponse<ProductApiModel>(
        success: false,
        message: 'Failed to get popular products',
        data: [],
        pagination: const PaginationMeta(
          currentPage: 1,
          totalPages: 1,
          totalItems: 0,
          itemsPerPage: 10,
          hasNextPage: false,
          hasPreviousPage: false,
        ),
      );
    }
  }

  /// Get all products for POS
  Future<ApiResponse<List<ProductApiModel>>> getAllProductsForPOS() async {
    try {
      if (kDebugMode) {
        print('Fetching all products for POS...');
      }

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/products/pos/all',
      );

      if (kDebugMode) {
        print('Raw response success: ${response.success}');
        print('Raw response message: ${response.message}');
        print('Raw response data type: ${response.data?.runtimeType}');
      }

      if (response.success && response.data != null) {
        try {
          final Map<String, dynamic> responseData = response.data!;

          if (kDebugMode) {
            print('Response data keys: ${responseData.keys.toList()}');
          }

          // Backend returns ProductListResponse: {products: [...], total_count, fetched_count, offset, has_more}
          final productsJson = responseData['products'] as List?;

          if (productsJson == null) {
            if (kDebugMode) {
              print('No "products" key found in response');
            }
            return ApiResponse<List<ProductApiModel>>(
              success: false,
              message: 'Invalid response format: missing "products" field',
            );
          }

          if (kDebugMode) {
            print('Found ${productsJson.length} products in response');
            if (productsJson.isNotEmpty) {
              print(
                  'First product keys: ${(productsJson.first as Map).keys.toList()}');
              print('First product sample: ${productsJson.first}');
            }
          }

          final productModels = productsJson.map((item) {
            try {
              return ProductApiModel.fromJson(item as Map<String, dynamic>);
            } catch (e) {
              if (kDebugMode) {
                print('Error parsing product item: $e');
                print('Problematic item: $item');
              }
              rethrow;
            }
          }).toList();

          if (kDebugMode) {
            print('Successfully parsed ${productModels.length} products');
          }

          return ApiResponse<List<ProductApiModel>>(
            success: true,
            message: 'Success',
            data: productModels,
          );
        } catch (parseError, stackTrace) {
          if (kDebugMode) {
            print('Error parsing product list: $parseError');
            print('Stack trace: $stackTrace');
          }
          return ApiResponse<List<ProductApiModel>>(
            success: false,
            message: 'Failed to parse products: ${parseError.toString()}',
          );
        }
      } else {
        return ApiResponse<List<ProductApiModel>>(
          success: false,
          message: response.message,
        );
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Get all products for POS error: $e');
        print('Stack trace: $stackTrace');
      }
      return ApiResponse<List<ProductApiModel>>(
        success: false,
        message: 'Failed to get all products for POS: ${e.toString()}',
      );
    }
  }

  /// Search products
  Future<ApiResponse<List<ProductApiModel>>> searchProducts(
      String query) async {
    try {
      final response = await _apiClient.get<List<ProductApiModel>>(
        '/api/products/search',
        queryParams: {'query': query},
        fromJson: (data) => (data as List)
            .map((item) => ProductApiModel.fromJson(item))
            .toList(),
      );
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Search products error: $e');
      }
      return ApiResponse<List<ProductApiModel>>(
        success: false,
        message: 'Failed to search products',
      );
    }
  }

  /// Get product statistics
  Future<ApiResponse<ProductStatsApiModel>> getProductStats() async {
    try {
      final response = await _apiClient.get<ProductStatsApiModel>(
        '/api/products/stats',
        fromJson: (data) => ProductStatsApiModel.fromJson(data),
      );
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Get product stats error: $e');
      }
      return ApiResponse<ProductStatsApiModel>(
        success: false,
        message: 'Failed to get product stats',
      );
    }
  }

  /// Get products by category
  Future<ApiResponse<List<ProductApiModel>>> getProductsByCategory(
      int categoryId) async {
    try {
      final response = await _apiClient.get<List<ProductApiModel>>(
        '/api/products/category/$categoryId',
        fromJson: (data) => (data as List)
            .map((item) => ProductApiModel.fromJson(item))
            .toList(),
      );
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Get products by category error: $e');
      }
      return ApiResponse<List<ProductApiModel>>(
        success: false,
        message: 'Failed to get products by category',
      );
    }
  }

  /// Get products by brand
  Future<ApiResponse<List<ProductApiModel>>> getProductsByBrand(
      int brandId) async {
    try {
      final response = await _apiClient.get<List<ProductApiModel>>(
        '/api/products/brand/$brandId',
        fromJson: (data) => (data as List)
            .map((item) => ProductApiModel.fromJson(item))
            .toList(),
      );
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Get products by brand error: $e');
      }
      return ApiResponse<List<ProductApiModel>>(
        success: false,
        message: 'Failed to get products by brand',
      );
    }
  }

  /// Get product by ID
  Future<ApiResponse<ProductApiModel>> getProductById(int productId) async {
    try {
      final response = await _apiClient.get<ProductApiModel>(
        '/api/products/$productId',
        fromJson: (data) => ProductApiModel.fromJson(data),
      );
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Get product by ID error: $e');
      }
      return ApiResponse<ProductApiModel>(
        success: false,
        message: 'Failed to get product by ID',
      );
    }
  }

  /// Get product variations by product ID
  Future<ApiResponse<List<ProductVariationApiModel>>> getProductVariations(
      int productId) async {
    try {
      if (kDebugMode) {
        print('Fetching product variations for product ID: $productId');
      }

      final response = await _apiClient.get<List<ProductVariationApiModel>>(
        '/api/products/$productId/variations',
        fromJson: (data) => (data as List)
            .map((item) =>
                ProductVariationApiModel.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

      if (kDebugMode) {
        print('Raw response success: ${response.success}');
        print('Raw response message: ${response.message}');
        print('Raw response data type: ${response.data?.runtimeType}');
        if (response.data != null) {
          print('Found ${response.data!.length} variations');
          if (response.data!.isNotEmpty) {
            print('First variation: ${response.data!.first.toJson()}');
          }
        }
      }

      return response;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Get product variations error: $e');
        print('Stack trace: $stackTrace');
      }
      return ApiResponse<List<ProductVariationApiModel>>(
        success: false,
        message: 'Failed to get product variations: ${e.toString()}',
      );
    }
  }

  /// Check stock for a specific variant
  Future<ApiResponse<Map<String, dynamic>>> validateVariantStock(
      int variantId, int quantity) async {
    try {
      if (kDebugMode) {
        print(
            'Validating stock for variant ID: $variantId, quantity: $quantity');
      }

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/variations/$variantId/stock',
        queryParams: {'quantity': quantity},
      );

      if (kDebugMode) {
        print('Stock validation response success: ${response.success}');
        print('Stock validation response message: ${response.message}');
        print('Stock validation response data: ${response.data}');
      }

      return response;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Validate variant stock error: $e');
        print('Stack trace: $stackTrace');
      }
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Failed to validate variant stock: ${e.toString()}',
      );
    }
  }

  @override
  void onClose() {
    _apiClient.dispose();
    super.onClose();
  }
}
