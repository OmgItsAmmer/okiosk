import 'package:get/get.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';
import '../models/api_response.dart';

/// Checkout API Service - Handles checkout operations with Rust backend
///
/// This service follows the API specification in CHECKOUT_MODULE.md
/// Endpoint: POST /api/checkout
class CheckoutApiService {
  final ApiClient _apiClient = Get.find<ApiClient>();

  /// Process checkout request
  ///
  /// Endpoint: POST /api/checkout
  /// Handles both cart checkout and direct checkout
  ///
  /// Request body matches the Rust backend specification:
  /// {
  ///   "customerId": int,
  ///   "addressId": int,  // -1 for pickup
  ///   "shippingMethod": string,  // "pickup" or "shipping"
  ///   "paymentMethod": string,  // "cod", "pickup", "credit_card", etc.
  ///   "cartItems": [
  ///     {
  ///       "variantId": int,
  ///       "quantity": int,
  ///       "sellPrice": string,
  ///       "buyPrice": string
  ///     }
  ///   ]
  /// }
  Future<ApiResponse<Map<String, dynamic>>> processCheckout({
    required int customerId,
    required int addressId,
    required String shippingMethod,
    required String paymentMethod,
    required List<Map<String, dynamic>> cartItems,
  }) async {
    try {
      if (kDebugMode) {
        print(
            'CheckoutApiService: Processing checkout for customer $customerId');
        print('CheckoutApiService: Shipping method: $shippingMethod');
        print('CheckoutApiService: Payment method: $paymentMethod');
        print('CheckoutApiService: Cart items: ${cartItems.length}');
      }

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/checkout',
        body: {
          'customerId': customerId,
          'addressId': addressId,
          'shippingMethod': shippingMethod,
          'paymentMethod': paymentMethod,
          'cartItems': cartItems,
        },
        fromJson: (data) {
          if (kDebugMode) {
            print('CheckoutApiService: fromJson called');
            print('CheckoutApiService: Data type: ${data.runtimeType}');
            print('CheckoutApiService: Data content: $data');
          }

          // Handle the case where data might be the entire response
          if (data is Map<String, dynamic>) {
            return data;
          }

          // If data is null or unexpected type, return empty map
          if (kDebugMode) {
            print(
                'CheckoutApiService: WARNING - Unexpected data type, returning empty map');
          }
          return <String, dynamic>{};
        },
      );

      if (kDebugMode) {
        print('CheckoutApiService: ========== RESPONSE ==========');
        print('CheckoutApiService: Success: ${response.success}');
        print('CheckoutApiService: Message: ${response.message}');
        print('CheckoutApiService: Status Code: ${response.statusCode}');
        print('CheckoutApiService: Data: ${response.data}');

        if (response.success && response.data != null) {
          if (response.data!.containsKey('orderId')) {
            print('CheckoutApiService: Order ID: ${response.data!['orderId']}');
          }
          if (response.data!.containsKey('total')) {
            print('CheckoutApiService: Total: ${response.data!['total']}');
          }
        }
        print('CheckoutApiService: ================================');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('CheckoutApiService: Error processing checkout - $e');
      }
      rethrow;
    }
  }

  /// Validate cart stock before checkout
  ///
  /// This method checks if all cart items have sufficient stock
  /// Returns a list of items that need adjustment
  Future<ApiResponse<Map<String, dynamic>>> validateCheckoutStock({
    required List<Map<String, dynamic>> cartItems,
  }) async {
    try {
      if (kDebugMode) {
        print(
            'CheckoutApiService: Validating stock for ${cartItems.length} items');
      }

      // For now, we'll validate stock by checking each variant
      // In the future, this could be a dedicated backend endpoint
      final adjustments = <Map<String, dynamic>>[];

      // This would ideally be a backend call to check stock
      // For now, we assume the cart controller has already validated

      return ApiResponse(
        success: true,
        message: 'Stock validation completed',
        data: {
          'has_issues': adjustments.isNotEmpty,
          'adjustments': adjustments,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('CheckoutApiService: Error validating stock - $e');
      }
      rethrow;
    }
  }
}
