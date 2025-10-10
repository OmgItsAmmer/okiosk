import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../common/widgets/loaders/tloaders.dart';
import '../../../features/cart/model/cart_model.dart';
import '../../backend/services/cart_api_service.dart';

/// Backend Cart Repository - Handles all cart-related API operations
///
/// This repository uses the backend API instead of direct Supabase calls.
/// It follows the Repository Pattern and provides a clean interface for cart operations.
class BackendCartRepository {
  final CartApiService _cartApiService = Get.find<CartApiService>();

  // ========== Customer Cart Methods ==========

  /// Fetches complete cart items with product and variant details
  ///
  /// Calls: GET /api/cart/:customer_id
  /// Returns complete cart items from backend with all necessary data
  Future<List<CartItemModel>> fetchCompleteCartItems(int customerId) async {
    try {
      if (kDebugMode) {
        print('BackendCartRepository: Fetching cart for customer $customerId');
      }

      final response = await _cartApiService.getCart(customerId);

      if (!response.success || response.data == null) {
        throw Exception(response.message);
      }

      final items = response.data!['items'] as List<dynamic>;

      if (kDebugMode) {
        print('BackendCartRepository: Received ${items.length} items from API');
      }

      return items
          .map<CartItemModel>((json) {
            // Map backend field names to the expected format for fromMergedData
            final mappedData = {
              'cart_id': json['cart_id'],
              'variant_id': json['variant_id'],
              'quantity': json['quantity'],
              'customer_id': json['customer_id'],
              'kiosk_session_id': json['kiosk_session_id'],
              'name': json['product_name'], // Map product_name to name
              'description': json[
                  'product_description'], // Map product_description to description
              'base_price': json['base_price'],
              'sale_price': json['sale_price'],
              'brandID': json['brand_id'], // Map brand_id to brandID
              'variant_name': json['variant_name'],
              'sell_price': json['sell_price'],
              'buy_price': json['buy_price'],
              'stock': json['stock'],
              'is_visible': json['is_visible'],
            };
            return CartItemModel.fromMergedData(mappedData);
          })
          .where((item) => item.cart.isValid)
          .toList();
    } catch (e) {
      _handleError('fetchCompleteCartItems', e);
      return [];
    }
  }

  /// Adds a new item to the cart or updates quantity if item already exists
  ///
  /// Calls: POST /api/cart/:customer_id/add
  Future<bool> addToCart(int customerId, int variantId, int quantity) async {
    try {
      if (variantId <= 0 || quantity <= 0) {
        throw Exception('Invalid parameters for adding to cart');
      }

      if (kDebugMode) {
        print(
            'BackendCartRepository: Adding to cart - customer: $customerId, variant: $variantId, qty: $quantity');
      }

      final response = await _cartApiService.addToCart(
        customerId: customerId,
        variantId: variantId,
        quantity: quantity,
      );

      if (kDebugMode) {
        print(
            'BackendCartRepository: Add to cart result - success: ${response.success}');
      }

      return response.success;
    } catch (e) {
      _handleError('addToCart', e);
      return false;
    }
  }

  /// Updates the quantity of a specific cart item
  ///
  /// Calls: PUT /api/cart/item/:cart_id
  Future<bool> updateCartItemQuantity(int cartId, int newQuantity) async {
    try {
      if (cartId <= 0 || newQuantity <= 0) {
        throw Exception('Invalid parameters for updating cart item');
      }

      if (kDebugMode) {
        print(
            'BackendCartRepository: Updating cart item $cartId to quantity $newQuantity');
      }

      final response = await _cartApiService.updateCartItemQuantity(
        cartId: cartId,
        quantity: newQuantity,
      );

      return response.success;
    } catch (e) {
      _handleError('updateCartItemQuantity', e);
      return false;
    }
  }

  /// Removes a specific item from the cart
  ///
  /// Calls: DELETE /api/cart/item/:cart_id
  Future<bool> removeCartItem(int cartId) async {
    try {
      if (cartId <= 0) {
        throw Exception('Invalid cart ID for removal');
      }

      if (kDebugMode) {
        print('BackendCartRepository: Removing cart item $cartId');
      }

      final response = await _cartApiService.removeCartItem(cartId);

      return response.success;
    } catch (e) {
      _handleError('removeCartItem', e);
      return false;
    }
  }

  /// Clears all items from user's cart
  ///
  /// Calls: DELETE /api/cart/:customer_id/clear
  Future<bool> clearCart(int customerId) async {
    try {
      if (kDebugMode) {
        print('BackendCartRepository: Clearing cart for customer $customerId');
      }

      final response = await _cartApiService.clearCart(customerId);

      return response.success;
    } catch (e) {
      _handleError('clearCart', e);
      return false;
    }
  }

  /// Validates cart stock and returns adjustment suggestions
  ///
  /// Calls: GET /api/cart/:customer_id/validate
  Future<List<CartStockValidation>> validateCartStock(int customerId) async {
    try {
      if (kDebugMode) {
        print(
            'BackendCartRepository: Validating cart stock for customer $customerId');
      }

      final response = await _cartApiService.validateCartStock(customerId);

      if (!response.success || response.data == null) {
        throw Exception(response.message);
      }

      final adjustments = response.data!['adjustments'] as List<dynamic>;

      return adjustments
          .map<CartStockValidation>(
              (json) => CartStockValidation.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('BackendCartRepository: validateCartStock error - $e');
      }
      rethrow;
    }
  }

  /// Applies cart stock adjustments
  ///
  /// Note: This method should be implemented in the backend API
  /// For now, it updates items individually
  Future<bool> applyCartAdjustments(
    int customerId,
    List<CartStockValidation> adjustments,
  ) async {
    try {
      // Apply adjustments by updating quantities or removing items
      for (final adjustment in adjustments) {
        if (adjustment.needsAdjustment) {
          if (adjustment.shouldRemove) {
            await removeCartItem(adjustment.cartId);
          } else {
            await updateCartItemQuantity(
              adjustment.cartId,
              adjustment.suggestedQuantity,
            );
          }
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('BackendCartRepository: applyCartAdjustments error - $e');
      }
      return false;
    }
  }

  /// Validates if a variant can be added to cart
  ///
  /// Note: This validation is now done on the backend when adding to cart
  /// Returns true by default, actual validation happens during addToCart
  Future<bool> canAddToCart(int variantId, int newQuantity) async {
    // Backend will validate this when we call addToCart
    // For now, we return true and let the backend handle validation
    return true;
  }

  /// Validates variant stock availability
  ///
  /// Note: This validation is now done on the backend
  /// Returns true by default, actual validation happens during addToCart
  Future<bool> validateVariantStock(int variantId, int quantity) async {
    // Backend will validate this when we call addToCart
    // For now, we return true and let the backend handle validation
    return true;
  }

  // ========== Kiosk Cart Methods ==========

  /// Fetches complete kiosk cart items with product and variant details
  ///
  /// Calls: GET /api/cart/kiosk/:session_id
  Future<List<CartItemModel>> fetchCompleteKioskCartItems(
      String kioskSessionId) async {
    try {
      if (kioskSessionId.isEmpty) {
        throw Exception('Kiosk session ID cannot be empty');
      }

      if (kDebugMode) {
        print(
            'BackendCartRepository: Fetching kiosk cart for session: $kioskSessionId');
      }

      final response = await _cartApiService.getKioskCart(kioskSessionId);

      if (!response.success || response.data == null) {
        throw Exception(response.message);
      }

      final items = response.data!['items'] as List<dynamic>;

      if (kDebugMode) {
        print(
            'BackendCartRepository: Received ${items.length} kiosk items from API');
      }

      return items
          .map<CartItemModel>((json) {
            // Map backend field names to the expected format for fromMergedData
            final mappedData = {
              'cart_id': json['kiosk_id'] ??
                  json['cart_id'], // Use kiosk_id as cart_id for kiosk carts
              'variant_id': json['variant_id'],
              'quantity': json['quantity'],
              'customer_id': json['customer_id'],
              'kiosk_session_id': json['kiosk_session_id'],
              'name': json['product_name'], // Map product_name to name
              'description': json[
                  'product_description'], // Map product_description to description
              'base_price': json['base_price'],
              'sale_price': json['sale_price'],
              'brandID': json['brand_id'], // Map brand_id to brandID
              'variant_name': json['variant_name'],
              'sell_price': json['sell_price'],
              'buy_price': json['buy_price'],
              'stock': json['stock'],
              'is_visible': json['is_visible'],
            };
            return CartItemModel.fromMergedData(mappedData);
          })
          .where((item) => item.cart.isValid)
          .toList();
    } catch (e) {
      _handleError('fetchCompleteKioskCartItems', e);
      return [];
    }
  }

  /// Adds a new item to the kiosk cart or updates quantity if item already exists
  ///
  /// Calls: POST /api/cart/kiosk/add
  Future<bool> addToKioskCart(
      String kioskSessionId, int variantId, int quantity) async {
    try {
      if (kioskSessionId.isEmpty || variantId <= 0 || quantity <= 0) {
        throw Exception('Invalid parameters for adding to kiosk cart');
      }

      if (kDebugMode) {
        print(
            'BackendCartRepository: Adding to kiosk cart - session: $kioskSessionId, variant: $variantId, qty: $quantity');
      }

      final response = await _cartApiService.addToKioskCart(
        kioskSessionId: kioskSessionId,
        variantId: variantId,
        quantity: quantity,
      );

      return response.success;
    } catch (e) {
      _handleError('addToKioskCart', e);
      return false;
    }
  }

  /// Updates the quantity of a specific kiosk cart item
  ///
  /// Calls: PUT /api/cart/kiosk/item/:kiosk_id
  Future<bool> updateKioskCartItemQuantity(int kioskId, int newQuantity) async {
    try {
      if (kioskId <= 0 || newQuantity <= 0) {
        throw Exception('Invalid parameters for updating kiosk cart item');
      }

      if (kDebugMode) {
        print(
            'BackendCartRepository: Updating kiosk cart item $kioskId to quantity $newQuantity');
      }

      final response = await _cartApiService.updateKioskCartItemQuantity(
        kioskId: kioskId,
        quantity: newQuantity,
      );

      return response.success;
    } catch (e) {
      _handleError('updateKioskCartItemQuantity', e);
      return false;
    }
  }

  /// Removes a specific item from the kiosk cart
  ///
  /// Calls: DELETE /api/cart/kiosk/item/:kiosk_id
  Future<bool> removeKioskCartItem(int kioskId) async {
    try {
      if (kioskId <= 0) {
        throw Exception('Invalid kiosk cart ID for removal');
      }

      if (kDebugMode) {
        print('BackendCartRepository: Removing kiosk cart item $kioskId');
      }

      final response = await _cartApiService.removeKioskCartItem(kioskId);

      return response.success;
    } catch (e) {
      _handleError('removeKioskCartItem', e);
      return false;
    }
  }

  /// Clears all items from kiosk session cart
  ///
  /// Calls: DELETE /api/cart/kiosk/:session_id/clear
  Future<bool> clearKioskCart(String kioskSessionId) async {
    try {
      if (kDebugMode) {
        print(
            'BackendCartRepository: Clearing kiosk cart for session $kioskSessionId');
      }

      final response = await _cartApiService.clearKioskCart(kioskSessionId);

      return response.success;
    } catch (e) {
      _handleError('clearKioskCart', e);
      return false;
    }
  }

  // ========== Error Handling ==========

  /// Centralized error handling for repository operations
  void _handleError(String operation, dynamic error) {
    final errorMessage =
        'Cart operation failed: $operation - ${error.toString()}';

    if (kDebugMode) {
      print('BackendCartRepository Error: $errorMessage');
    }

    // Check if it's a network error
    final errorString = error.toString().toLowerCase();
    final isNetworkError = errorString.contains('522') ||
        errorString.contains('525') ||
        errorString.contains('timeout') ||
        errorString.contains('network') ||
        errorString.contains('connection');

    // Don't show error snackbar for network errors during background operations
    if (!isNetworkError ||
        operation == 'addToCart' ||
        operation == 'removeCartItem') {
      TLoader.errorSnackBar(
        title: 'Cart Error',
        message: _getErrorUserMessage(operation),
      );
    }
  }

  /// Gets user-friendly error messages for different operations
  String _getErrorUserMessage(String operation) {
    switch (operation) {
      case 'fetchCompleteCartItems':
      case 'fetchCompleteKioskCartItems':
        return 'Unable to load cart items. Please try again.';
      case 'addToCart':
      case 'addToKioskCart':
        return 'Unable to add item to cart. Please try again.';
      case 'updateCartItemQuantity':
      case 'updateKioskCartItemQuantity':
        return 'Unable to update item quantity. Please try again.';
      case 'removeCartItem':
      case 'removeKioskCartItem':
        return 'Unable to remove item from cart. Please try again.';
      case 'clearCart':
      case 'clearKioskCart':
        return 'Unable to clear cart. Please try again.';
      default:
        return 'An error occurred with your cart. Please try again.';
    }
  }
}
