import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../common/widgets/loaders/tloaders.dart';
import '../../../data/repositories/cart/cart_repository.dart';
import '../../customer/controller/customer_controller.dart';
import '../model/cart_model.dart';

/// Cart Controller - Manages cart state and operations
///
/// This controller follows the Single Responsibility Principle by focusing solely on
/// cart-related state management and user interactions. It serves as a bridge between
/// the UI and the data layer, implementing the Command pattern for cart operations.
///
/// Responsibilities:
/// - Cart state management
/// - User interaction handling
/// - UI updates coordination
/// - Business logic for cart operations
class CartController extends GetxController {
  // Singleton pattern for global access
  static CartController get instance => Get.find();

  // Dependencies - Dependency Injection following SOLID principles
  late final CustomerController _customerController;
  late final CartRepository _cartRepository;

  // Reactive state variables
  final RxBool isLoading = false.obs;
  final RxList<CartItemModel> cartItems = <CartItemModel>[].obs;
  final Rx<CartSummary> cartSummary = CartSummary.empty().obs;
  final RxString errorMessage = ''.obs;
  final RxList<CartStockValidation> stockAdjustments =
      <CartStockValidation>[].obs;
  final RxBool hasStockIssues = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeDependencies();
  }

  /// Initialize dependencies with proper error handling
  ///
  /// Uses dependency injection to maintain loose coupling and testability
  void _initializeDependencies() {
    try {
      //   _customerController = Get.find<CustomerController>();
      //  _cartRepository = Get.find<CartRepository>();
    } catch (e) {
      if (kDebugMode) {
        print('CartController: Failed to initialize dependencies - $e');
      }
      // Handle gracefully - dependencies might not be ready yet
    }
  }

  /// Fetches complete cart data with optimized single query
  ///
  /// This method replaces the old approach of multiple separate queries with
  /// a single optimized query that fetches all necessary data at once.
  /// Follows the Command pattern for complex operations.
  Future<void> fetchCart() async {
    try {
      _setLoadingState(true);
      errorMessage.value = '';

      final customerId = _customerController.currentCustomer.value.customerId;
      final fetchedItems =
          await _cartRepository.fetchCompleteCartItems(customerId!);

      // Update reactive state
      cartItems.assignAll(fetchedItems);
      _updateCartSummary();

      if (kDebugMode) {
        print('CartController: Fetched ${fetchedItems.length} cart items');
      }
    } catch (e) {
      _handleError('Failed to fetch cart: ${e.toString()}');
    } finally {
      _setLoadingState(false);
    }
  }

  /// Adds an item to the cart with validation and optimistic updates
  ///
  /// Implements optimistic UI updates for better user experience while
  /// maintaining data consistency through proper error handling.
  ///
  /// @param variantId The ID of the product variant to add
  /// @param quantity The quantity to add (default: 1)
  Future<bool> addToCart(int variantId, {int quantity = 1}) async {
    try {
      final customerId = _customerController.currentCustomer.value.customerId;

      // Validate variant availability
      final isValidVariant =
          await _cartRepository.canAddToCart(variantId, quantity);
      if (!isValidVariant) {
        TLoader.errorSnackBar(
            title: 'Whoa, Slow Down!',
            message: " You've already hit the max quantity for this item");
        return false;
      }

      // Add to cart through repository
      final success =
          await _cartRepository.addToCart(customerId!, variantId, quantity);

      if (success) {
        // Refresh cart to get updated data
        await fetchCart();
        // TLoader.successSnackBar(title: 'Item added to cart successfully');
        return true;
      } else {
        _handleError('Failed to add item to cart');
        return false;
      }
    } catch (e) {
      _handleError('Error adding item to cart: ${e.toString()}');
      return false;
    }
  }

  /// Updates the quantity of a cart item with validation
  ///
  /// @param cartItemModel The cart item to update
  /// @param newQuantity The new quantity (must be > 0)
  Future<bool> updateCartItemQuantity(
      CartItemModel cartItemModel, int newQuantity) async {
    if (newQuantity <= 0) {
      return await removeCartItem(cartItemModel);
    }

    try {
      final success = await _cartRepository.updateCartItemQuantity(
        cartItemModel.cart.cartId,
        newQuantity,
      );

      if (success) {
        // Update local state optimistically
        final updatedItems = cartItems.map((item) {
          if (item.cart.cartId == cartItemModel.cart.cartId) {
            return item.updateQuantity(newQuantity);
          }
          return item;
        }).toList();

        cartItems.assignAll(updatedItems);
        _updateCartSummary();
        return true;
      } else {
        _handleError('Failed to update item quantity');
        return false;
      }
    } catch (e) {
      _handleError('Error updating item quantity: ${e.toString()}');
      return false;
    }
  }

  /// Removes an item from the cart with confirmation
  ///
  /// @param cartItemModel The cart item to remove
  Future<bool> removeCartItem(CartItemModel cartItemModel) async {
    try {
      final success =
          await _cartRepository.removeCartItem(cartItemModel.cart.cartId);

      if (success) {
        // Update local state immediately
        cartItems.removeWhere(
            (item) => item.cart.cartId == cartItemModel.cart.cartId);
        _updateCartSummary();
        TLoader.successSnackBar(title: 'Item removed from cart');
        return true;
      } else {
        _handleError('Failed to remove item from cart');
        return false;
      }
    } catch (e) {
      _handleError('Error removing item from cart: ${e.toString()}');
      return false;
    }
  }

  /// Clears all items from the cart
  Future<bool> clearCart() async {
    try {
      final customerId = _customerController.currentCustomer.value.customerId;
      final success = await _cartRepository.clearCart(customerId!);

      if (success) {
        // Clear local state
        cartItems.clear();
        _updateCartSummary();
        //  TLoader.successSnackBar(title: 'Cart cleared successfully');
        return true;
      } else {
        _handleError('Failed to clear cart');
        return false;
      }
    } catch (e) {
      _handleError('Error clearing cart: ${e.toString()}');
      return false;
    }
  }

  /// Gets the total number of items in the cart
  int get totalCartItems => cartSummary.value.totalItems;

  /// Gets the total price of the cart
  double get totalCartPrice => cartSummary.value.subtotal;

  /// Checks if the cart is empty
  bool get isCartEmpty => cartItems.isEmpty;

  /// Gets cart item by variant ID (for compatibility)
  CartItemModel? getCartItemByVariantId(int variantId) {
    try {
      return cartItems.firstWhere(
        (item) => item.cart.variantId == variantId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Validates cart stock and identifies items that need adjustment
  ///
  /// This method should be called when opening the cart or proceeding to checkout
  /// to ensure all items are still available in the requested quantities.
  ///
  /// @return Future<bool> True if adjustments are needed, false otherwise
  Future<bool> validateCartStock() async {
    try {
      _setLoadingState(true);

      final customerId = _customerController.currentCustomer.value.customerId;
      if (customerId == null) {
        throw Exception('Customer not logged in');
      }

      final validationResults =
          await _cartRepository.validateCartStock(customerId);

      // Filter only items that need adjustment
      final itemsNeedingAdjustment =
          validationResults.where((result) => result.needsAdjustment).toList();

      stockAdjustments.assignAll(itemsNeedingAdjustment);
      hasStockIssues.value = itemsNeedingAdjustment.isNotEmpty;

      if (kDebugMode) {
        print(
            'CartController: Found ${itemsNeedingAdjustment.length} items needing adjustment');
      }

      return itemsNeedingAdjustment.isNotEmpty;
    } catch (e) {
      _handleError('Failed to validate cart stock: ${e.toString()}');
      return false;
    } finally {
      _setLoadingState(false);
    }
  }

  /// Applies stock adjustments to cart items
  ///
  /// This method applies the suggested stock adjustments and refreshes the cart.
  /// Should be called after user confirms the adjustments.
  ///
  /// @return Future<bool> Success status
  Future<bool> applyStockAdjustments() async {
    try {
      _setLoadingState(true);

      final customerId = _customerController.currentCustomer.value.customerId;
      if (customerId == null) {
        throw Exception('Customer not logged in');
      }

      final success = await _cartRepository.applyCartAdjustments(
        customerId,
        stockAdjustments.toList(),
      );

      if (success) {
        // Clear adjustments and refresh cart
        stockAdjustments.clear();
        hasStockIssues.value = false;
        await fetchCart(); // Refresh cart with updated quantities

        if (kDebugMode) {
          print('CartController: Stock adjustments applied successfully');
        }
      }

      return success;
    } catch (e) {
      _handleError('Failed to apply stock adjustments: ${e.toString()}');
      return false;
    } finally {
      _setLoadingState(false);
    }
  }

  /// Gets adjustment information for a specific cart item
  ///
  /// Used by the UI to display adjustment indicators for individual items.
  ///
  /// @param cartId The cart item ID
  /// @return CartStockValidation? The adjustment info if exists
  CartStockValidation? getAdjustmentForCartItem(int cartId) {
    try {
      return stockAdjustments.firstWhere(
        (adjustment) => adjustment.cartId == cartId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Clears all stock adjustment data
  ///
  /// Used when adjustments are no longer relevant or have been handled.
  void clearStockAdjustments() {
    stockAdjustments.clear();
    hasStockIssues.value = false;
  }

  /// Updates the cart summary based on current cart items
  ///
  /// Follows the Observer pattern to automatically update dependent calculations
  void _updateCartSummary() {
    cartSummary.value = CartSummary.fromItems(cartItems);
  }

  /// Sets loading state with proper UI feedback
  ///
  /// @param loading Whether the controller is in a loading state
  void _setLoadingState(bool loading) {
    isLoading.value = loading;
  }

  /// Handles errors with consistent logging and user feedback
  ///
  /// @param message The error message to handle
  void _handleError(String message) {
    if (kDebugMode) {
      print('CartController Error: $message');
    }
    errorMessage.value = message;
    TLoader.errorSnackBar(title: 'Cart Error', message: message);
  }
}
