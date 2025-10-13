import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/ai_action_model.dart';
import '../../../features/cart/controller/cart_controller.dart';
import '../../../features/checkout/screens/checkout_screen.dart';

/// AI Action Executor Service
///
/// This service is responsible for executing AI actions returned from the AI command service.
/// It acts as a bridge between the AI service and the appropriate controllers/services
/// to execute the actions locally without requiring database persistence.
///
/// ## Supported Actions:
///
/// - `add_to_cart`: Adds items to local cart using AI-validated data
/// - `remove_from_cart`: Removes items from local cart
/// - `update_quantity`: Updates item quantities in local cart
/// - `clear_cart`: Clears all items from local cart
/// - `view_cart`: Displays cart contents (message-only)
/// - `search_product`: Shows search results (message-only)
/// - `show_menu`: Displays menu items (message-only)
/// - `generate_bill`: Opens checkout screen dialog
/// - `checkout`: Opens checkout screen dialog
class AiActionExecutor {
  // Singleton pattern for global access
  static AiActionExecutor get instance => Get.find<AiActionExecutor>();

  // Dependencies
  final CartController _cartController = Get.find<CartController>();

  /// Executes a single AI action
  ///
  /// @param action The AI action to execute
  /// @return Future<bool> Success status
  Future<bool> executeAction(AiAction action) async {
    try {
      if (kDebugMode) {
        print(
            'AiActionExecutor: Executing action - Type: ${action.actionType}, Success: ${action.success}');
      }

      if (!action.success) {
        if (kDebugMode) {
          print('AiActionExecutor: Action failed - Error: ${action.error}');
          print('AiActionExecutor: Action message: ${action.message}');
        }
        // Don't show snackbar for failed actions - let the chat display the error
        // The AI response message will be displayed in the chat
        return false;
      }

      switch (action.actionType) {
        case 'add_to_cart':
          return await _executeAddToCartAction(action);
        case 'remove_from_cart':
          return await _executeRemoveFromCartAction(action);
        case 'update_quantity':
          return await _executeUpdateQuantityAction(action);
        case 'clear_cart':
          return await _executeClearCartAction(action);
        case 'view_cart':
          return await _executeViewCartAction(action);
        case 'search_product':
          return await _executeSearchProductAction(action);
        case 'show_menu':
          return await _executeShowMenuAction(action);
        case 'generate_bill':
          return await _executeGenerateBillAction(action);
        case 'checkout':
          return await _executeCheckoutAction(action);
        default:
          if (kDebugMode) {
            print(
                'AiActionExecutor: Unknown action type: ${action.actionType}');
          }
          return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('AiActionExecutor: Execution error: $e');
      }
      // Don't show snackbar for execution errors - let the chat display the error
      return false;
    }
  }

  /// Executes multiple AI actions from JSON strings (as returned by backend)
  ///
  /// @param actionStrings List of JSON strings containing actions
  /// @return Future<List<bool>> Success status for each action
  Future<List<bool>> executeActionsFromStrings(
      List<String> actionStrings) async {
    if (kDebugMode) {
      print(
          'AiActionExecutor: Received ${actionStrings.length} action strings to execute');
    }

    final List<bool> results = [];

    for (int i = 0; i < actionStrings.length; i++) {
      final actionString = actionStrings[i];
      try {
        // Parse the JSON string to get the action object
        final action = AiAction.fromJsonString(actionString);
        final result = await executeAction(action);
        results.add(result);
      } catch (e) {
        if (kDebugMode) {
          print('AiActionExecutor: Error parsing action string $i: $e');
        }
        results.add(false);
      }
    }

    if (kDebugMode) {
      print('AiActionExecutor: Execution results: $results');
    }

    return results;
  }

  /// Executes multiple AI actions in sequence
  ///
  /// @param actions List of AI actions to execute
  /// @return Future<List<bool>> Success status for each action
  Future<List<bool>> executeActions(List<AiAction> actions) async {
    if (kDebugMode) {
      print('AiActionExecutor: Received ${actions.length} actions to execute');
      for (int i = 0; i < actions.length; i++) {
        final action = actions[i];
        print(
            'AiActionExecutor: Action $i - Type: ${action.actionType}, Success: ${action.success}');
        if (action.error != null) {
          print('AiActionExecutor: Action $i - Error: ${action.error}');
        }
        if (action.data != null) {
          print('AiActionExecutor: Action $i - Data: ${action.data}');
        }
      }
    }

    final List<bool> results = [];

    for (final action in actions) {
      final result = await executeAction(action);
      results.add(result);
    }

    if (kDebugMode) {
      print('AiActionExecutor: Execution results: $results');
    }

    return results;
  }

  /// Executes add_to_cart action using pre-validated data from AI
  Future<bool> _executeAddToCartAction(AiAction action) async {
    try {
      final data = action.addToCartData;
      if (data == null) {
        if (kDebugMode) {
          print('AiActionExecutor: Missing data for add_to_cart action');
        }
        return false;
      }

      // Use the specialized AI function that skips validation
      final success = await _cartController.addToCartFromAI(
        variantId: data.variantId,
        quantity: data.quantity,
        sellPrice: data.sellPrice,
        availableStock: data.availableStock,
        productName: data.productName,
        variantName: data.variantName,
      );

      // Don't show snackbar here - message is displayed in chat
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('AiActionExecutor: Add to cart error: $e');
      }
      return false;
    }
  }

  /// Executes remove_from_cart action
  Future<bool> _executeRemoveFromCartAction(AiAction action) async {
    try {
      final data = action.removeFromCartData;
      if (data == null) {
        if (kDebugMode) {
          print('AiActionExecutor: Missing data for remove_from_cart action');
        }
        return false;
      }

      // Find the cart item by variant ID
      final cartItem = _cartController.getCartItemByVariantId(data.variantId);
      if (cartItem == null) {
        if (kDebugMode) {
          print(
              'AiActionExecutor: Item not found in cart: ${data.productName} (${data.variantName})');
        }
        return false;
      }

      final success = await _cartController.removeCartItem(cartItem);

      // Don't show snackbar here - message is displayed in chat
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('AiActionExecutor: Remove from cart error: $e');
      }
      return false;
    }
  }

  /// Executes update_quantity action
  Future<bool> _executeUpdateQuantityAction(AiAction action) async {
    try {
      final data = action.updateQuantityData;
      if (data == null) {
        if (kDebugMode) {
          print('AiActionExecutor: Missing data for update_quantity action');
        }
        return false;
      }

      // Find the cart item by variant ID
      final cartItem = _cartController.getCartItemByVariantId(data.variantId);
      if (cartItem == null) {
        if (kDebugMode) {
          print(
              'AiActionExecutor: Item not found in cart: ${data.productName} (${data.variantName})');
        }
        return false;
      }

      final success =
          await _cartController.updateCartItemQuantity(cartItem, data.quantity);

      // Don't show snackbar here - message is displayed in chat
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('AiActionExecutor: Update quantity error: $e');
      }
      return false;
    }
  }

  /// Executes clear_cart action
  Future<bool> _executeClearCartAction(AiAction action) async {
    try {
      final success = await _cartController.clearCart();

      // Don't show snackbar here - message is displayed in chat
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('AiActionExecutor: Clear cart error: $e');
      }
      return false;
    }
  }

  /// Executes view_cart action - displays current cart contents
  Future<bool> _executeViewCartAction(AiAction action) async {
    try {
      // For view_cart, we don't need to do anything special
      // The AI message will be displayed in chat with cart details
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('AiActionExecutor: View cart error: $e');
      }
      return false;
    }
  }

  /// Executes search_product action - displays search results
  Future<bool> _executeSearchProductAction(AiAction action) async {
    try {
      final data = action.searchProductData;
      if (data == null) {
        if (kDebugMode) {
          print('AiActionExecutor: Missing data for search_product action');
        }
        return false;
      }

      // For search_product, we don't need to do anything special
      // The AI message will be displayed in chat with search results
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('AiActionExecutor: Search product error: $e');
      }
      return false;
    }
  }

  /// Executes show_menu action - displays menu items
  Future<bool> _executeShowMenuAction(AiAction action) async {
    try {
      // For show_menu, we don't need to do anything special
      // The AI message will be displayed in chat with menu items
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('AiActionExecutor: Show menu error: $e');
      }
      return false;
    }
  }

  /// Executes generate_bill action - opens checkout screen dialog
  Future<bool> _executeGenerateBillAction(AiAction action) async {
    try {
      if (kDebugMode) {
        print('AiActionExecutor: Opening checkout screen for bill generation');
      }

      // Show the checkout screen (it's already a dialog)
      Get.to(() => const CheckoutScreen());

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('AiActionExecutor: Generate bill error: $e');
      }
      return false;
    }
  }

  /// Executes checkout action - opens checkout screen dialog
  Future<bool> _executeCheckoutAction(AiAction action) async {
    try {
      if (kDebugMode) {
        print('AiActionExecutor: Opening checkout screen for checkout process');
      }

      // Show the checkout screen (it's already a dialog)
      Get.to(() => const CheckoutScreen());

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('AiActionExecutor: Checkout error: $e');
      }
      return false;
    }
  }
}
