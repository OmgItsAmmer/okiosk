import 'package:get/get.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';
import '../models/api_response.dart';

/// Cart API Service - Handles all cart-related backend API calls
///
/// This service follows the API specification in CART_MODULE.md and provides
/// methods for both customer carts and kiosk carts.
class CartApiService {
  final ApiClient _apiClient = Get.find<ApiClient>();

  // ========== Customer Cart Endpoints ==========

  /// Get cart items for a customer
  ///
  /// Endpoint: GET /api/cart/:customer_id
  /// Returns complete cart with product and variant details
  Future<ApiResponse<Map<String, dynamic>>> getCart(int customerId) async {
    try {
      if (kDebugMode) {
        print('CartApiService: Fetching cart for customer $customerId');
      }

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/cart/$customerId',
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (kDebugMode) {
        print('CartApiService: Response - ${response.message}');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('CartApiService: Error fetching cart - $e');
      }
      rethrow;
    }
  }

  /// Add item to customer cart
  ///
  /// Endpoint: POST /api/cart/:customer_id/add
  /// Request body: { "variant_id": int, "quantity": int }
  Future<ApiResponse<Map<String, dynamic>>> addToCart({
    required int customerId,
    required int variantId,
    required int quantity,
  }) async {
    try {
      if (kDebugMode) {
        print(
            'CartApiService: Adding to cart - customer: $customerId, variant: $variantId, qty: $quantity');
      }

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/cart/$customerId/add',
        body: {
          'variant_id': variantId,
          'quantity': quantity,
        },
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (kDebugMode) {
        print('CartApiService: Add to cart response - ${response.message}');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('CartApiService: Error adding to cart - $e');
      }
      rethrow;
    }
  }

  /// Update cart item quantity
  ///
  /// Endpoint: PUT /api/cart/item/:cart_id
  /// Request body: { "quantity": int }
  Future<ApiResponse<Map<String, dynamic>>> updateCartItemQuantity({
    required int cartId,
    required int quantity,
  }) async {
    try {
      if (kDebugMode) {
        print(
            'CartApiService: Updating cart item $cartId to quantity $quantity');
      }

      final response = await _apiClient.put<Map<String, dynamic>>(
        '/cart/item/$cartId',
        body: {
          'quantity': quantity,
        },
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (kDebugMode) {
        print('CartApiService: Update quantity response - ${response.message}');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('CartApiService: Error updating quantity - $e');
      }
      rethrow;
    }
  }

  /// Remove item from cart
  ///
  /// Endpoint: DELETE /api/cart/item/:cart_id
  Future<ApiResponse<Map<String, dynamic>>> removeCartItem(int cartId) async {
    try {
      if (kDebugMode) {
        print('CartApiService: Removing cart item $cartId');
      }

      final response = await _apiClient.delete<Map<String, dynamic>>(
        '/cart/item/$cartId',
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (kDebugMode) {
        print('CartApiService: Remove item response - ${response.message}');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('CartApiService: Error removing item - $e');
      }
      rethrow;
    }
  }

  /// Clear entire cart for a customer
  ///
  /// Endpoint: DELETE /api/cart/:customer_id/clear
  Future<ApiResponse<Map<String, dynamic>>> clearCart(int customerId) async {
    try {
      if (kDebugMode) {
        print('CartApiService: Clearing cart for customer $customerId');
      }

      final response = await _apiClient.delete<Map<String, dynamic>>(
        '/cart/$customerId/clear',
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (kDebugMode) {
        print('CartApiService: Clear cart response - ${response.message}');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('CartApiService: Error clearing cart - $e');
      }
      rethrow;
    }
  }

  /// Validate cart stock
  ///
  /// Endpoint: GET /api/cart/:customer_id/validate
  /// Returns list of items that need stock adjustments
  Future<ApiResponse<Map<String, dynamic>>> validateCartStock(
      int customerId) async {
    try {
      if (kDebugMode) {
        print('CartApiService: Validating cart stock for customer $customerId');
      }

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/cart/$customerId/validate',
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (kDebugMode) {
        print('CartApiService: Validate response - ${response.message}');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('CartApiService: Error validating cart - $e');
      }
      rethrow;
    }
  }

  // ========== Kiosk Cart Endpoints ==========

  /// Get kiosk cart items for a session
  ///
  /// Endpoint: GET /api/cart/kiosk/:session_id
  Future<ApiResponse<Map<String, dynamic>>> getKioskCart(
      String sessionId) async {
    try {
      if (kDebugMode) {
        print('CartApiService: Fetching kiosk cart for session $sessionId');
      }

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/cart/kiosk/$sessionId',
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (kDebugMode) {
        print('CartApiService: Kiosk cart response - ${response.message}');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('CartApiService: Error fetching kiosk cart - $e');
      }
      rethrow;
    }
  }

  /// Add item to kiosk cart
  ///
  /// Endpoint: POST /api/cart/kiosk/add
  /// Request body: { "kiosk_session_id": string, "variant_id": int, "quantity": int }
  Future<ApiResponse<Map<String, dynamic>>> addToKioskCart({
    required String kioskSessionId,
    required int variantId,
    required int quantity,
  }) async {
    try {
      if (kDebugMode) {
        print(
            'CartApiService: Adding to kiosk cart - session: $kioskSessionId, variant: $variantId, qty: $quantity');
      }

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/cart/kiosk/add',
        body: {
          'kiosk_session_id': kioskSessionId,
          'variant_id': variantId,
          'quantity': quantity,
        },
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (kDebugMode) {
        print(
            'CartApiService: Add to kiosk cart response - ${response.message}');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('CartApiService: Error adding to kiosk cart - $e');
      }
      rethrow;
    }
  }

  /// Update kiosk cart item quantity
  ///
  /// Endpoint: PUT /api/cart/kiosk/item/:kiosk_id
  /// Request body: { "quantity": int }
  Future<ApiResponse<Map<String, dynamic>>> updateKioskCartItemQuantity({
    required int kioskId,
    required int quantity,
  }) async {
    try {
      if (kDebugMode) {
        print(
            'CartApiService: Updating kiosk cart item $kioskId to quantity $quantity');
      }

      final response = await _apiClient.put<Map<String, dynamic>>(
        '/cart/kiosk/item/$kioskId',
        body: {
          'quantity': quantity,
        },
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (kDebugMode) {
        print(
            'CartApiService: Update kiosk quantity response - ${response.message}');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('CartApiService: Error updating kiosk quantity - $e');
      }
      rethrow;
    }
  }

  /// Remove item from kiosk cart
  ///
  /// Endpoint: DELETE /api/cart/kiosk/item/:kiosk_id
  Future<ApiResponse<Map<String, dynamic>>> removeKioskCartItem(
      int kioskId) async {
    try {
      if (kDebugMode) {
        print('CartApiService: Removing kiosk cart item $kioskId');
      }

      final response = await _apiClient.delete<Map<String, dynamic>>(
        '/cart/kiosk/item/$kioskId',
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (kDebugMode) {
        print(
            'CartApiService: Remove kiosk item response - ${response.message}');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('CartApiService: Error removing kiosk item - $e');
      }
      rethrow;
    }
  }

  /// Clear entire kiosk cart for a session
  ///
  /// Endpoint: DELETE /api/cart/kiosk/:session_id/clear
  Future<ApiResponse<Map<String, dynamic>>> clearKioskCart(
      String sessionId) async {
    try {
      if (kDebugMode) {
        print('CartApiService: Clearing kiosk cart for session $sessionId');
      }

      final response = await _apiClient.delete<Map<String, dynamic>>(
        '/cart/kiosk/$sessionId/clear',
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (kDebugMode) {
        print(
            'CartApiService: Clear kiosk cart response - ${response.message}');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('CartApiService: Error clearing kiosk cart - $e');
      }
      rethrow;
    }
  }
}
