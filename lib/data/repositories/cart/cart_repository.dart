
import 'package:flutter/foundation.dart';
import '../../../common/widgets/loaders/tloaders.dart';
import '../../../features/cart/model/cart_model.dart';
import '../../../main.dart';

/// Cart Repository - Handles all cart-related database operations
///
/// This repository follows the Repository Pattern and Single Responsibility Principle.
/// It provides a clean interface for cart operations and abstracts database complexity.
///
/// Responsibilities:
/// - Cart CRUD operations
/// - Data validation and transformation
/// - Error handling and logging
/// - Database query optimization
class CartRepository {
  /// Fetches all cart items for a specific user
  ///
  /// Returns a list of CartModel objects representing the user's cart.
  /// Uses proper error handling and null safety.
  ///
  /// @param userID The UUID of the user
  /// @return Future<List<CartModel>> List of cart items
  Future<List<CartModel>> fetchCartItems(String userID) async {
    try {
      if (userID.isEmpty) {
        throw Exception('User ID cannot be empty');
      }

      final response = await supabase
          .from('cart')
          .select('cart_id, variant_id, quantity, user_id')
          .eq('user_id', userID)
          .order('cart_id', ascending: true);

      return response
          .map<CartModel>((json) => CartModel.fromJson(json))
          .where((cart) => cart.isValid)
          .toList();
    } catch (e) {
      _handleError('fetchCartItems', e);
      return [];
    }
  }

  /// Fetches complete cart items with product and variant details
  ///
  /// This method performs an optimized join query to fetch all necessary data
  /// in a single database call, reducing network overhead and improving performance.
  ///
  /// @param userID The UUID of the user
  /// @return Future<List<CartItemModel>> Complete cart items with all details
  Future<List<CartItemModel>> fetchCompleteCartItems(int customerId) async {
    try {
      // Optimized query with joins to fetch all data in one call
      final response = await supabase.from('cart').select('''
            cart_id,
            variant_id,
            quantity,
            customer_id,
            product_variants!inner(
              variant_id,
              sell_price,
              buy_price,
              product_id,
              variant_name,
              stock,
              is_visible,
              products!inner(
                product_id,
                name,
                description,
                base_price,
                sale_price,
                brandID
              )
            )
          ''').eq('customer_id', customerId).order('cart_id', ascending: true);

      return response
          .map<CartItemModel>((data) {
            // Flatten the nested structure for easier access
            final variant = data['product_variants'];
            final product = variant['products'];

            final flattenedData = {
              'cart_id': data['cart_id'],
              'variant_id': data['variant_id'],
              'quantity': data['quantity'] as String, // Quantity is text in DB
              'customer_id': data['customer_id'],
              'sell_price': variant['sell_price'],
              'buy_price': variant['buy_price'],
              'product_id': variant['product_id'],
              'variant_name': variant['variant_name'],
              'stock': variant['stock'] as int, // Stock is integer in DB
              'is_visible': variant['is_visible'],
              'name': product['name'],
              'description': product['description'],
              'base_price': product['base_price'],
              'sale_price': product['sale_price'],
              'brandID': product['brandID'],
            };

            return CartItemModel.fromMergedData(flattenedData);
          })
          .where((item) => item.cart.isValid)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print(e);
        _handleError('fetchCompleteCartItems', e);
      }
      return [];
    }
  }

  /// Adds a new item to the cart or updates quantity if item already exists
  ///
  /// Implements upsert logic to handle both new additions and quantity updates.
  /// This prevents duplicate entries and maintains data consistency.
  ///
  /// @param userId The UUID of the user
  /// @param variantId The ID of the product variant
  /// @param quantity The quantity to add/set
  /// @return Future<bool> Success status
  Future<bool> addToCart(int customerId, int variantId, int quantity) async {
    try {
      if (variantId <= 0 || quantity <= 0) {
        throw Exception('Invalid parameters for adding to cart');
      }

      // Check if item already exists in cart
      final existingItems = await supabase
          .from('cart')
          .select('cart_id, quantity')
          .eq('customer_id', customerId)
          .eq('variant_id', variantId)
          .limit(1);

      if (existingItems.isNotEmpty) {
        // Update existing item quantity
        final existingQuantity =
            int.tryParse(existingItems.first['quantity'] as String) ?? 0;
        final newQuantity = existingQuantity + quantity;

        await supabase
            .from('cart')
            .update({'quantity': newQuantity.toString()}).eq(
                'cart_id', existingItems.first['cart_id']);
      } else {
        // Add new item to cart
        final cartItem = CartModel(
          cartId: -1, // Will be auto-generated by database
          variantId: variantId,
          quantity: quantity.toString(),
          customerId: customerId,
        );

        await supabase.from('cart').insert(cartItem.toJson());
      }

      return true;
    } catch (e) {
      _handleError('addToCart', e);
      return false;
    }
  }

  /// Updates the quantity of a specific cart item
  ///
  /// @param cartId The ID of the cart item
  /// @param newQuantity The new quantity (must be > 0)
  /// @return Future<bool> Success status
  Future<bool> updateCartItemQuantity(int cartId, int newQuantity) async {
    try {
      if (cartId <= 0 || newQuantity <= 0) {
        throw Exception('Invalid parameters for updating cart item');
      }

      await supabase
          .from('cart')
          .update({'quantity': newQuantity.toString()}).eq('cart_id', cartId);

      return true;
    } catch (e) {
      _handleError('updateCartItemQuantity', e);
      return false;
    }
  }

  /// Updates cart item quantity by variant ID (legacy method for backward compatibility)
  ///
  /// @param variantId The ID of the product variant
  /// @param userId The UUID of the user
  /// @param newQuantity The new quantity
  /// @return Future<bool> Success status
  Future<bool> updateCartItemByVariant(
      int variantId, int customerId, int newQuantity) async {
    try {
      if (variantId <= 0 || newQuantity <= 0) {
        throw Exception('Invalid parameters for updating cart item by variant');
      }

      await supabase
          .from('cart')
          .update({'quantity': newQuantity.toString()})
          .eq('variant_id', variantId)
          .eq('customer_id', customerId);

      return true;
    } catch (e) {
      _handleError('updateCartItemByVariant', e);
      return false;
    }
  }

  /// Removes a specific item from the cart
  ///
  /// @param cartId The ID of the cart item to remove
  /// @return Future<bool> Success status
  Future<bool> removeCartItem(int cartId) async {
    try {
      if (cartId <= 0) {
        throw Exception('Invalid cart ID for removal');
      }

      await supabase.from('cart').delete().eq('cart_id', cartId);

      return true;
    } catch (e) {
      _handleError('removeCartItem', e);
      return false;
    }
  }

  /// Removes cart item by variant ID and user ID (legacy method)
  ///
  /// @param variantId The ID of the product variant
  /// @param userId The UUID of the user
  /// @return Future<bool> Success status
  Future<bool> removeCartItemByVariant(int variantId, int customerId) async {
    try {
      if (variantId <= 0) {
        throw Exception('Invalid parameters for removing cart item by variant');
      }

      await supabase
          .from('cart')
          .delete()
          .eq('variant_id', variantId)
          .eq('customer_id', customerId);

      return true;
    } catch (e) {
      _handleError('removeCartItemByVariant', e);
      return false;
    }
  }

  /// Clears all items from user's cart
  ///
  /// @param userId The UUID of the user
  /// @return Future<bool> Success status
  Future<bool> clearCart(int customerId) async {
    try {
      await supabase.from('cart').delete().eq('customer_id', customerId);

      return true;
    } catch (e) {
      _handleError('clearCart', e);
      return false;
    }
  }

  /// Gets the total count of items in user's cart
  ///
  /// @param userId The UUID of the user
  /// @return Future<int> Total number of distinct items in cart
  Future<int> getCartItemCount(int customerId) async {
    try {
      final response = await supabase
          .from('cart')
          .select('cart_id')
          .eq('customer_id', customerId);

      return response.length;
    } catch (e) {
      _handleError('getCartItemCount', e);
      return 0;
    }
  }

  /// Validates if a variant exists and is available for stock update
  ///
  /// @param variantId The ID of the product variant
  /// @param newStock The new stock quantity to set
  /// @return Future<bool> True if variant exists and stock can be safely updated
  Future<bool> validateVariant(
      int variantId, int newStock, int customerId) async {
    try {
      // print('validateVariant: $variantId, $newStock, $customerId');
      final response = await supabase.rpc(
        'update_variant_stock_with_validation',
        params: {
          'p_variant_id_input': variantId,
          'p_new_stock_value_input': newStock,
          'p_customer_id_input': customerId,
        },
      );

      if (response == null || response is! bool) {
        throw Exception('Invalid response from Supabase RPC');
      }
      return response;
    } catch (e) {
      _handleError('validateVariant', e);
      return false;
    }
  }

  Future<bool> canAddToCart(int variantId, int newQuantity) async {
    try {
      final response = await supabase.rpc(
        'add_to_cart_validation',
        params: {
          'p_variant_id_input': variantId,
          'p_new_quantity_input': newQuantity,
        },
      );
      return response as bool;
    } catch (e) {
      _handleError('canAddToCart', e);
      return false;
    }
  }

  /// Centralized error handling for repository operations
  ///
  /// Logs errors and shows user-friendly messages while maintaining
  /// system stability and providing debugging information.
  ///
  /// @param operation The name of the operation that failed
  /// @param error The error object
  void _handleError(String operation, dynamic error) {
    final errorMessage =
        'Cart operation failed: $operation - ${error.toString()}';

    // Log error for debugging (in production, this should go to a logging service)
    if (kDebugMode) {
      print('CartRepository Error: $errorMessage');
    }

    // Show user-friendly error message
    TLoader.errorSnackBar(
      title: 'Cart Error',
      message: _getErrorUserMessage(operation),
    );
  }

  /// Gets user-friendly error messages for different operations
  ///
  /// @param operation The operation that failed
  /// @return String User-friendly error message
  String _getErrorUserMessage(String operation) {
    switch (operation) {
      case 'fetchCartItems':
      case 'fetchCompleteCartItems':
        return 'Unable to load cart items. Please try again.';
      case 'addToCart':
        return 'Unable to add item to cart. Please try again.';
      case 'updateCartItemQuantity':
      case 'updateCartItemByVariant':
        return 'Unable to update item quantity. Please try again.';
      case 'removeCartItem':
      case 'removeCartItemByVariant':
        return 'Unable to remove item from cart. Please try again.';
      case 'clearCart':
        return 'Unable to clear cart. Please try again.';
      default:
        return 'An error occurred with your cart. Please try again.';
    }
  }

  // Legacy methods for backward compatibility
  // These will be deprecated in future versions

  @Deprecated('Use fetchCartItems instead')
  Future<List<CartModel>> fetchCart(String userID) => fetchCartItems(userID);

  /// Validates cart stock and returns adjustment suggestions
  ///
  /// This method calls the database function to validate all cart items
  /// for a customer and returns suggestions for stock adjustments.
  ///
  /// @param customerId The customer ID to validate cart for
  /// @return Future<List<CartStockValidation>> List of validation results
  Future<List<CartStockValidation>> validateCartStock(int customerId) async {
    try {
      final response = await supabase.rpc(
        'validate_and_adjust_cart_stock',
        params: {'p_customer_id': customerId},
      );

      return (response as List<dynamic>)
          .map((item) => CartStockValidation.fromJson(item))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('CartRepository: validateCartStock error - $e');
      }
      rethrow;
    }
  }

  /// Applies cart stock adjustments
  ///
  /// This method applies the suggested adjustments to the cart items,
  /// either updating quantities or removing items as needed.
  ///
  /// @param customerId The customer ID
  /// @param adjustments List of adjustments to apply
  /// @return Future<bool> Success status
  Future<bool> applyCartAdjustments(
    int customerId,
    List<CartStockValidation> adjustments,
  ) async {
    try {
      // Convert adjustments to JSON format expected by the database function
      final adjustmentData = adjustments
          .where((adj) => adj.needsAdjustment)
          .map((adj) => {
                'cart_id': adj.cartId,
                'suggested_quantity': adj.suggestedQuantity,
                'should_remove': adj.shouldRemove,
              })
          .toList();

      if (adjustmentData.isEmpty) {
        return true; // No adjustments needed
      }

      final result = await supabase.rpc(
        'apply_cart_adjustments',
        params: {
          'p_customer_id': customerId,
          'p_adjustments': adjustmentData,
        },
      );

      return result == true;
    } catch (e) {
      if (kDebugMode) {
        print('CartRepository: applyCartAdjustments error - $e');
      }
      return false;
    }
  }

  @Deprecated('Use fetchCompleteCartItems instead')
  Future<List<Map<String, dynamic>>> fetchProductsVariantTable(
      String userID) async {
    // This method is kept for backward compatibility but should not be used
    // in new implementations
    return [];
  }

  @Deprecated('Use fetchCompleteCartItems instead')
  Future<List<Map<String, dynamic>>> fetchProductsTable() async {
    // This method is kept for backward compatibility but should not be used
    // in new implementations
    return [];
  }

  @Deprecated('Use addToCart instead')
  Future<void> uploadDataToCart(
      int customerId, int variantId, int quantity) async {
    await addToCart(customerId, variantId, quantity);
  }

  @Deprecated('Use updateCartItemByVariant instead')
  Future<void> updateDataToCart(int variantId, String currentQuantity) async {
    // This method lacks user context, so it cannot be properly implemented
    // It's kept for backward compatibility but will not function correctly
  }

  @Deprecated('Use removeCartItemByVariant instead')
  Future<void> deleteItemFromCart(int variantId, int customerId) async {
    await removeCartItemByVariant(variantId, customerId);
  }
}
