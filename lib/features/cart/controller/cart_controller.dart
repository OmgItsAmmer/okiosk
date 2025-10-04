import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../common/widgets/loaders/tloaders.dart';
import '../../../data/repositories/cart/cart_repository.dart';
import '../../../data/realtime/kiosk_cart_realtime.dart';
import '../../../main.dart';
import '../../customer/controller/customer_controller.dart';
import '../../products/controller/product_controller.dart';
import '../../products/controller/product_varaintion_controller.dart';
import '../../products/models/product_variation_model.dart';
import '../../shop/controller/shop_controller.dart';
import '../model/cart_model.dart';

import '../../../utils/helpers/helper_functions.dart';

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
  final CustomerController _customerController = Get.find<CustomerController>();
  final CartRepository _cartRepository = Get.put(CartRepository());
  final ProductController _productController = Get.find<ProductController>();
  final ProductVariationController _variationController =
      Get.find<ProductVariationController>();
  final ShopController _shopController = Get.find<ShopController>();

  // Reactive state variables
  final RxBool isLoading = false.obs;
  final RxList<CartItemModel> cartItems = <CartItemModel>[].obs;
  // Search state for filtering cart items in UI
  final RxString _cartSearchQuery = ''.obs;
  final RxList<CartItemModel> _filteredCartItems = <CartItemModel>[].obs;
  final Rx<CartSummary> cartSummary = CartSummary.empty().obs;
  final RxString errorMessage = ''.obs;
  final RxList<CartStockValidation> stockAdjustments =
      <CartStockValidation>[].obs;
  final RxBool hasStockIssues = false.obs;

  // Kiosk-specific state
  final RxInt _scannedCustomerId = 0.obs;
  final RxBool isKioskMode = true.obs; // Set to true for kiosk app
  final RxInt _localCartIdCounter = 1.obs; // For generating local cart IDs
  final RxString _kioskUUID = ''.obs; // Store the kiosk UUID for QR code
  final RxString _scannedKioskSessionId =
      ''.obs; // Store scanned kiosk session ID
  final RxBool _isFetchingKioskCart = false.obs; // Track if fetching kiosk cart

  @override
  void onInit() {
    super.onInit();
    generateKioskUUID(); // Generate kiosk UUID on initialization
    _initializeKioskCart(); // Initialize kiosk cart functionality
    // _initializeDependencies();

    // Keep filtered list in sync with items and query
    ever<List<CartItemModel>>(cartItems, (_) => _recomputeFilteredCartItems());
    ever<String>(_cartSearchQuery, (_) => _recomputeFilteredCartItems());
    // Initial compute
    _recomputeFilteredCartItems();
  }

  @override
  void onClose() {
    // Stop realtime subscription to prevent memory leaks
    stopCartRealtime();
    super.onClose();
  }

  /// Initialize dependencies with proper error handling
  ///
  /// Uses dependency injection to maintain loose coupling and testability
  // void _initializeDependencies() {
  //   try {
  //       _customerController = Get.find<CustomerController>();
  //      _cartRepository = Get.find<CartRepository>();
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print('CartController: Failed to initialize dependencies - $e');
  //     }
  //     // Handle gracefully - dependencies might not be ready yet
  //   }
  // }

  /// Generates a unique UUID for this kiosk instance
  ///
  /// This UUID is used to identify this specific kiosk when customers scan the QR code.
  /// The UUID is generated once when the controller is initialized and remains constant
  /// throughout the kiosk session.
  void generateKioskUUID() {
    if (_kioskUUID.value.isEmpty) {
      _kioskUUID.value = THelperFunctions.generateRandomUUID();
      if (kDebugMode) {
        print('CartController: Generated kiosk UUID: ${_kioskUUID.value}');
      }
    }
  }

  /// Initializes kiosk cart functionality
  ///
  /// Sets up realtime subscription to listen for cart changes for this kiosk's UUID.
  /// Does not perform initial fetch to avoid startup network errors.
  void _initializeKioskCart() {
    try {
      if (kDebugMode) {
        print('CartController: Initializing kiosk cart functionality');
      }

      // Delay the realtime subscription to avoid startup network issues
      Future.delayed(const Duration(seconds: 2), () {
        try {
          // Start realtime subscription for kiosk cart changes
          startCartRealtime();

          if (kDebugMode) {
            print('CartController: Realtime subscription started');
          }
        } catch (e) {
          if (kDebugMode) {
            print('CartController: Error starting realtime: ${e.toString()}');
          }
        }
      });

      if (kDebugMode) {
        print('CartController: Kiosk cart initialization scheduled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('CartController: Error initializing kiosk cart: ${e.toString()}');
      }
      // Don't show error to user for initialization issues
    }
  }

  /// Gets the current kiosk UUID
  ///
  /// This UUID can be used to generate QR codes that customers can scan
  /// to connect to this specific kiosk instance.
  String get kioskUUID => _kioskUUID.value;

  /// Public getter for current search query
  String get cartSearchQuery => _cartSearchQuery.value;

  /// Public getter for filtered cart items (reactive via Obx)
  List<CartItemModel> get filteredCartItems => _filteredCartItems;

  /// Updates the cart search query and triggers filtering
  void setCartSearchQuery(String query) {
    _cartSearchQuery.value = query.trim().toLowerCase();
  }

  /// Clears the cart search query
  void clearCartSearch() {
    _cartSearchQuery.value = '';
  }

  /// Recomputes the filtered cart items list based on query and items
  void _recomputeFilteredCartItems() {
    final query = _cartSearchQuery.value;
    if (query.isEmpty) {
      _filteredCartItems.assignAll(cartItems);
      return;
    }

    final List<CartItemModel> results = cartItems.where((item) {
      final product = item.productName.toLowerCase();
      final variant = item.variantName.toLowerCase();
      final description = item.productDescription.toLowerCase();
      return product.contains(query) ||
          variant.contains(query) ||
          description.contains(query);
    }).toList();

    _filteredCartItems.assignAll(results);
  }

  /// Fetches complete cart data with optimized single query
  ///
  /// This method replaces the old approach of multiple separate queries with
  /// a single optimized query that fetches all necessary data at once.
  /// Follows the Command pattern for complex operations.
  ///
  /// In kiosk mode, it fetches from database only when a customer QR is scanned
  Future<void> fetchCart() async {
    try {
      _setLoadingState(true);
      errorMessage.value = '';

      if (isKioskMode.value) {
        // In kiosk mode, only fetch from database if customer is scanned
        if (_scannedCustomerId.value > 0) {
          final fetchedItems = await _cartRepository
              .fetchCompleteCartItems(_scannedCustomerId.value);
          cartItems.assignAll(fetchedItems);
        }
        // If no customer scanned, keep local cart as is
      } else {
        // Normal mode - fetch from database
        final customerId = _customerController.currentCustomer.value.customerId;
        final fetchedItems =
            await _cartRepository.fetchCompleteCartItems(customerId!);
        cartItems.assignAll(fetchedItems);
      }

      _updateCartSummary();

      if (kDebugMode) {
        print('CartController: Fetched ${cartItems.length} cart items');
      }
    } catch (e) {
      _handleError('Failed to fetch cart: ${e.toString()}');
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> fetchKioskCart() async {
    try {
      _setLoadingState(true);
      final fetchedItems = await _cartRepository
          .fetchCompleteKioskCartItems(_scannedKioskSessionId.value);
      cartItems.assignAll(fetchedItems);
      errorMessage.value = '';
      _updateCartSummary();
      cartItems.refresh();
    } catch (e) {
      _handleError('Failed to fetch kiosk cart: ${e.toString()}');
    } finally {
      _setLoadingState(false);
    }
  }

  /// Fetches kiosk cart by specific session ID
  ///
  /// This method is used by the realtime listener to fetch cart items
  /// for the current kiosk session when changes are detected.
  ///
  /// @param sessionId The kiosk session UUID to fetch cart for
  Future<void> fetchKioskCartBySession(String sessionId) async {
    try {
      _setLoadingState(true);

      if (kDebugMode) {
        print('CartController: Fetching kiosk cart for session: $sessionId');
      }

      // Also check if the specific session has any data
      if (kDebugMode) {
        final directCheck = await supabase
            .from('kiosk_cart')
            .select('*')
            .eq('kiosk_session_id', sessionId);
        print(
            'CartController: Direct check found ${directCheck.length} items for session: $sessionId');
      }

      final fetchedItems =
          await _cartRepository.fetchCompleteKioskCartItems(sessionId);

      // Always update the scanned session ID to match the session we're fetching
      // This ensures the UI knows we're connected to this specific session
      if (_scannedKioskSessionId.value != sessionId) {
        _scannedKioskSessionId.value = sessionId;
        if (kDebugMode) {
          print('CartController: Updated scanned session ID to: $sessionId');
        }
      }

      cartItems.assignAll(fetchedItems);
      errorMessage.value = '';
      _updateCartSummary();
      cartItems.refresh();

      if (kDebugMode) {
        print(
            'CartController: ✅ Successfully fetched ${fetchedItems.length} items for session: $sessionId');
        print(
            'CartController: cartItems list updated with ${cartItems.length} items');
        print(
            'CartController: Cart summary updated - Total: ${cartSummary.value.totalItems} items');
        for (int i = 0; i < fetchedItems.length; i++) {
          print(
              'CartController: Item $i - ${fetchedItems[i].productName} (Qty: ${fetchedItems[i].cart.quantityAsInt})');
        }
      }

      // Show success message if items were loaded from e-commerce
      if (fetchedItems.isNotEmpty && sessionId == _kioskUUID.value) {
        TLoader.successSnackBar(
          title: 'Cart Loaded',
          message:
              'Successfully loaded ${fetchedItems.length} items from customer cart.',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('CartController: Error fetching kiosk cart: ${e.toString()}');
      }

      // Don't show network error messages to user during realtime operations
      // Only log them for debugging
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('522') ||
          errorString.contains('525') ||
          errorString.contains('timeout') ||
          errorString.contains('network')) {
        // Network errors - just log, don't show to user
        if (kDebugMode) {
          print('CartController: Network error ignored: $e');
        }
      } else {
        // Other errors - show to user
        _handleError('Failed to fetch kiosk cart: ${e.toString()}');
      }
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
      // Check if we have an active kiosk session first
      if (_scannedKioskSessionId.value.isNotEmpty) {
        return await addToKioskCart(variantId, quantity: quantity);
      }

      if (isKioskMode.value) {
        return await _addToLocalCart(variantId, quantity);
      } else {
        // Normal e-commerce mode
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
          return true;
        } else {
          _handleError('Failed to add item to cart');
          return false;
        }
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
      // Check if we have an active kiosk session first
      if (_scannedKioskSessionId.value.isNotEmpty) {
        return await updateKioskCartItemQuantity(cartItemModel, newQuantity);
      }

      if (isKioskMode.value) {
        // Kiosk mode - update local cart
        final maxAllowedQuantity = await _shopController.maxAllowedQuantity();

        if (newQuantity > maxAllowedQuantity) {
          TLoader.errorSnackBar(
            title: 'Whoa, Slow Down!',
            message:
                "Quantity exceeds maximum allowed (Max: $maxAllowedQuantity)",
          );
          return false;
        }

        // Validate variant stock
        final isValid = await _validateVariantForLocalCart(
            cartItemModel.cart.variantId!, newQuantity);
        if (!isValid) {
          return false;
        }

        // Update local cart item
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
        // Normal mode - update database
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
      // Check if we have an active kiosk session first
      if (_scannedKioskSessionId.value.isNotEmpty) {
        return await removeKioskCartItem(cartItemModel);
      }

      if (isKioskMode.value) {
        // Kiosk mode - remove from local cart
        cartItems.removeWhere(
            (item) => item.cart.cartId == cartItemModel.cart.cartId);
        _updateCartSummary();
        TLoader.successSnackBar(title: 'Item removed from cart');
        return true;
      } else {
        // Normal mode - remove from database
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
      }
    } catch (e) {
      _handleError('Error removing item from cart: ${e.toString()}');
      return false;
    }
  }

  /// Clears all items from the cart
  Future<bool> clearCart() async {
    try {
      if (isKioskMode.value) {
        // Kiosk mode - clear local cart only
        cartItems.clear();
        _updateCartSummary();
        return true;
      } else {
        // Normal mode - clear database cart
        final customerId = _customerController.currentCustomer.value.customerId;
        final success = await _cartRepository.clearCart(customerId!);

        if (success) {
          // Clear local state
          cartItems.clear();
          _updateCartSummary();
          return true;
        } else {
          _handleError('Failed to clear cart');
          return false;
        }
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

      if (isKioskMode.value) {
        // Kiosk mode - validate local cart items against current stock
        return await _validateLocalCartStock();
      } else {
        // Normal mode - use database validation
        final customerId = _customerController.currentCustomer.value.customerId;
        if (customerId == null) {
          throw Exception('Customer not logged in');
        }

        final validationResults =
            await _cartRepository.validateCartStock(customerId);

        // Filter only items that need adjustment
        final itemsNeedingAdjustment = validationResults
            .where((result) => result.needsAdjustment)
            .toList();

        stockAdjustments.assignAll(itemsNeedingAdjustment);
        hasStockIssues.value = itemsNeedingAdjustment.isNotEmpty;

        if (kDebugMode) {
          print(
              'CartController: Found ${itemsNeedingAdjustment.length} items needing adjustment');
        }

        return itemsNeedingAdjustment.isNotEmpty;
      }
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
    TLoader.errorSnackBar(
        title: 'Cart Error from Controller', message: message);
  }

  // KIOSK MODE METHODS

  /// Adds an item to local cart (kiosk mode)
  ///
  /// @param variantId The ID of the product variant to add
  /// @param quantity The quantity to add
  Future<bool> _addToLocalCart(int variantId, int quantity) async {
    try {
      // Validate variant availability and stock first

      // Validate variant availability and stock
      final isValid = await _validateVariantForLocalCart(variantId, quantity);
      if (!isValid) {
        return false;
      }

      // Check max quantity limit from shop controller
      final maxAllowedQuantity = await _shopController.maxAllowedQuantity();

      // Check if item already exists in local cart
      final existingItemIndex = cartItems.indexWhere(
        (item) => item.cart.variantId == variantId,
      );

      if (existingItemIndex != -1) {
        // Update existing item quantity
        final existingItem = cartItems[existingItemIndex];
        final currentQuantity = existingItem.cart.quantityAsInt;
        final newQuantity = currentQuantity + quantity;

        if (newQuantity > maxAllowedQuantity) {
          TLoader.errorSnackBar(
            title: 'Whoa, Slow Down!',
            message:
                "You've already hit the max quantity for this item (Max: $maxAllowedQuantity)",
          );
          return false;
        }

        final updatedItem = existingItem.updateQuantity(newQuantity);
        cartItems[existingItemIndex] = updatedItem;
      } else {
        // Add new item to local cart
        if (quantity > maxAllowedQuantity) {
          TLoader.errorSnackBar(
            title: 'Whoa, Slow Down!',
            message:
                "Quantity exceeds maximum allowed (Max: $maxAllowedQuantity)",
          );
          return false;
        }

        final cartItemModel = await _createLocalCartItem(variantId, quantity);
        if (cartItemModel != null) {
          cartItems.add(cartItemModel);
        } else {
          return false;
        }
      }

      _updateCartSummary();
      return true;
    } catch (e) {
      _handleError('Error adding item to local cart: ${e.toString()}');
      return false;
    }
  }

  /// Creates a local cart item model from variant data
  ///
  /// @param variantId The ID of the product variant
  /// @param quantity The quantity
  Future<CartItemModel?> _createLocalCartItem(
      int variantId, int quantity) async {
    try {
      // Resolve variant and product details even if current product has no variants populated
      var product = _productController.currentProduct.value;
      var variant = product.productVariants.isNotEmpty
          ? product.productVariants.firstWhere(
              (v) => v.variantId == variantId,
              orElse: () => ProductVariationModel.empty(),
            )
          : ProductVariationModel.empty();

      if (variant.variantId == 0) {
        // Fetch variant by ID via variation controller
        final fetchedVariant = await _variationController
            .fetchProductVariantByVariantId(variantId);
        if (fetchedVariant == null || fetchedVariant.variantId == 0) {
          TLoader.errorSnackBar(
            title: 'Variant Not Found',
            message: 'Unable to locate the selected variant.',
          );
          return null;
        }
        variant = fetchedVariant;
      }

      // Ensure product corresponds to the variant's productId
      if (product.productId != variant.productId || product.productId <= 0) {
        final fetchedProduct = await _productController.productRepository
            .fetchProductById(variant.productId);
        product = fetchedProduct;
      }

      // Create local cart model with temporary ID
      final localCart = CartModel(
        cartId: _localCartIdCounter.value++,
        variantId: variantId,
        quantity: quantity.toString(),
        customerId:
            _scannedCustomerId.value > 0 ? _scannedCustomerId.value : null,
      );

      // Create cart item model
      return CartItemModel(
        cart: localCart,
        productName: product.name,
        productDescription: product.description ?? '',
        basePrice: product.basePrice,
        salePrice: (product.salePrice.isNotEmpty
            ? product.salePrice
            : product.basePrice),
        brandId: product.brandID,
        variantName: variant.variantName ?? '',
        sellPrice: double.tryParse(variant.sellPrice) ?? 0.0,
        buyPrice: variant.buyPrice != null
            ? double.tryParse(variant.buyPrice!)
            : null,
        stock: int.tryParse(variant.stockQuantity) ?? 0,
        isVisible: variant.isVisible,
      );
    } catch (e) {
      _handleError('Error creating local cart item: ${e.toString()}');

      return null;
    }
  }

  /// Validates variant for local cart operations
  ///
  /// @param variantId The ID of the product variant
  /// @param quantity The quantity to validate
  Future<bool> _validateVariantForLocalCart(int variantId, int quantity) async {
    try {
      // Validate variant exists and has sufficient stock using repository
      final isValid =
          await _cartRepository.validateVariantStock(variantId, quantity);
      if (!isValid) {
        TLoader.errorSnackBar(
          title: 'Stock Unavailable',
          message: 'Insufficient stock for this item',
        );
        return false;
      }
      return true;
    } catch (e) {
      _handleError('Error validating variant: ${e.toString()}');
      return false;
    }
  }

  /// Validates local cart stock for kiosk mode
  ///
  /// This method validates all items in the local cart against current stock levels
  /// @return Future<bool> True if adjustments are needed, false otherwise
  Future<bool> _validateLocalCartStock() async {
    try {
      final List<CartStockValidation> adjustments = [];

      for (final cartItem in cartItems) {
        final variantId = cartItem.cart.variantId!;
        final currentQuantity = cartItem.cart.quantityAsInt;

        // Get current stock from database
        final response = await supabase
            .from('product_variants')
            .select('stock, is_visible')
            .eq('variant_id', variantId)
            .single();

        final availableStock = response['stock'] as int;
        final isVisible = response['is_visible'] as bool;

        if (!isVisible) {
          // Product is no longer visible - should be removed
          adjustments.add(CartStockValidation(
            cartId: cartItem.cart.cartId,
            variantId: variantId,
            productName: cartItem.productName,
            variantName: cartItem.variantName,
            currentQuantity: currentQuantity,
            availableStock: availableStock,
            suggestedQuantity: 0,
            needsAdjustment: true,
            adjustmentReason: 'Product is no longer available',
            shouldRemove: true,
          ));
        } else if (availableStock < currentQuantity) {
          // Insufficient stock - reduce quantity or remove if no stock
          final suggestedQuantity = availableStock > 0 ? availableStock : 0;
          adjustments.add(CartStockValidation(
            cartId: cartItem.cart.cartId,
            variantId: variantId,
            productName: cartItem.productName,
            variantName: cartItem.variantName,
            currentQuantity: currentQuantity,
            availableStock: availableStock,
            suggestedQuantity: suggestedQuantity,
            needsAdjustment: true,
            adjustmentReason: availableStock > 0
                ? 'Only $availableStock items available'
                : 'Out of stock',
            shouldRemove: availableStock == 0,
          ));
        }
      }

      stockAdjustments.assignAll(adjustments);
      hasStockIssues.value = adjustments.isNotEmpty;

      if (kDebugMode) {
        print(
            'CartController: Found ${adjustments.length} local cart items needing adjustment');
      }

      return adjustments.isNotEmpty;
    } catch (e) {
      _handleError('Error validating local cart stock: ${e.toString()}');
      return false;
    }
  }

  /// Scans QR code and loads customer cart
  ///
  /// @param customerId The customer ID from QR code
  Future<bool> scanCustomerQR(int customerId) async {
    try {
      _setLoadingState(true);
      _scannedCustomerId.value = customerId;

      // Fetch customer's cart from database
      final fetchedItems =
          await _cartRepository.fetchCompleteCartItems(customerId);

      // Clear local cart and load customer cart
      cartItems.assignAll(fetchedItems);
      _updateCartSummary();

      TLoader.successSnackBar(
        title: 'Cart Loaded',
        message: 'Customer cart loaded successfully',
      );

      return true;
    } catch (e) {
      _handleError('Error loading customer cart: ${e.toString()}');
      return false;
    } finally {
      _setLoadingState(false);
    }
  }

  /// Clears local cart and resets to kiosk mode
  void resetToKioskMode() {
    _scannedCustomerId.value = 0;
    cartItems.clear();
    _localCartIdCounter.value = 1;
    _updateCartSummary();
    clearStockAdjustments();
  }

  /// Gets the current customer ID (for kiosk operations)
  int get currentCustomerId => _scannedCustomerId.value;

  /// Checks if a customer cart is loaded
  bool get isCustomerCartLoaded => _scannedCustomerId.value > 0;

  /// Handles when a customer scans the kiosk QR code
  ///
  /// This method is called when a customer scans the QR code displayed on the kiosk.
  /// The QR code contains the kiosk UUID which can be used to establish a connection
  /// between the customer's mobile app and this kiosk instance.
  ///
  /// @param scannedUUID The UUID that was scanned from the QR code
  /// @return bool True if the UUID matches this kiosk, false otherwise
  bool handleCustomerQRScan(String scannedUUID) {
    if (scannedUUID == _kioskUUID.value) {
      if (kDebugMode) {
        print(
            'CartController: Customer scanned matching kiosk UUID: $scannedUUID');
      }
      // Here you can implement additional logic for customer connection
      // For example, sending a notification to the kiosk that a customer is connected
      return true;
    } else {
      if (kDebugMode) {
        print(
            'CartController: Customer scanned non-matching UUID: $scannedUUID (expected: ${_kioskUUID.value})');
      }
      return false;
    }
  }

  /// Handles QR code scan for kiosk cart loading
  ///
  /// This method is called when a QR code is scanned from the cart sidebar.
  /// It extracts the kiosk session ID from the QR code and fetches the corresponding
  /// cart data from the kiosk_cart table after a 5-second delay.
  ///
  /// @param scannedData The data scanned from the QR code
  /// @return bool True if the scan was processed successfully, false otherwise
  Future<bool> handleKioskCartQRScan(String scannedData) async {
    try {
      if (scannedData.isEmpty) {
        TLoader.errorSnackBar(
          title: 'Invalid QR Code',
          message: 'The scanned QR code is empty or invalid.',
        );
        return false;
      }

      // Extract kiosk session ID from scanned data
      // Assuming the QR code contains the kiosk session ID directly
      final kioskSessionId = scannedData.trim();

      if (kDebugMode) {
        print(
            'CartController: Processing kiosk cart QR scan for session: $kioskSessionId');
      }

      // Store the scanned session ID
      _scannedKioskSessionId.value = kioskSessionId;

      // Show loading message
      TLoader.successSnackBar(
        title: 'QR Code Scanned',
        message: 'Loading cart data in 5 seconds...',
      );

      // Wait for 5 seconds before fetching cart data
      await Future.delayed(const Duration(seconds: 5));

      // Fetch kiosk cart data
      return await _fetchKioskCartData(kioskSessionId);
    } catch (e) {
      _handleError('Error processing kiosk cart QR scan: ${e.toString()}');
      return false;
    }
  }

  /// Fetches kiosk cart data from the database
  ///
  /// @param kioskSessionId The kiosk session ID to fetch cart for
  /// @return Future<bool> True if cart was loaded successfully, false otherwise
  Future<bool> _fetchKioskCartData(String kioskSessionId) async {
    try {
      _setLoadingState(true);
      _isFetchingKioskCart.value = true;

      if (kDebugMode) {
        print(
            'CartController: Fetching kiosk cart data for session: $kioskSessionId');
      }

      // Fetch complete kiosk cart items with product details
      final fetchedItems =
          await _cartRepository.fetchCompleteKioskCartItems(kioskSessionId);

      if (fetchedItems.isEmpty) {
        TLoader.warningSnackBar(
          title: 'Empty Cart',
          message: 'No items found in the scanned kiosk cart.',
        );
        return false;
      }

      // Clear current cart and load kiosk cart items
      cartItems.assignAll(fetchedItems);
      _updateCartSummary();

      TLoader.successSnackBar(
        title: 'Cart Loaded',
        message:
            'Successfully loaded ${fetchedItems.length} items from kiosk cart.',
      );

      if (kDebugMode) {
        print(
            'CartController: Successfully loaded ${fetchedItems.length} kiosk cart items');
      }

      return true;
    } catch (e) {
      _handleError('Error fetching kiosk cart data: ${e.toString()}');
      return false;
    } finally {
      _setLoadingState(false);
      _isFetchingKioskCart.value = false;
    }
  }

  /// Gets the current scanned kiosk session ID
  String get scannedKioskSessionId => _scannedKioskSessionId.value;

  /// Manually checks for existing kiosk cart items
  ///
  /// This method can be called manually (e.g., from a button) to check if there are
  /// any existing cart items for this kiosk session without causing startup errors.
  Future<void> checkForExistingKioskCart() async {
    try {
      if (kDebugMode) {
        print('CartController: Manually checking for existing kiosk cart');
        print('CartController: Current kiosk UUID: ${_kioskUUID.value}');
        print(
            'CartController: Current scanned session ID: ${_scannedKioskSessionId.value}');
      }

      await fetchKioskCartBySession(_kioskUUID.value);
    } catch (e) {
      if (kDebugMode) {
        print(
            'CartController: Error checking for existing cart: ${e.toString()}');
      }
      // Show error for manual operations
      _handleError('Failed to check for existing cart: ${e.toString()}');
    }
  }

  /// Manual test method to verify realtime subscription is working
  ///
  /// This method can be called from a debug button to test realtime functionality
  Future<void> testRealtimeConnection() async {
    try {
      if (kDebugMode) {
        print('CartController: === TESTING REALTIME CONNECTION ===');
        print('CartController: Current kiosk UUID: ${_kioskUUID.value}');
        print('CartController: Current cart items count: ${cartItems.length}');

        // Check realtime status
        print('CartController: Realtime active: ${isRealtimeActive()}');

        // Test direct database insertion for debugging
        print('CartController: Testing direct database insertion...');
        final testResult = await supabase.from('kiosk_cart').insert({
          'kiosk_session_id': _kioskUUID.value,
          'variant_id': 15, // Test with variant ID 1
          'quantity': 1,
        });
        print('CartController: Test insertion result: $testResult');

        // Wait 2 seconds to see if realtime triggers
        await Future.delayed(const Duration(seconds: 2));

        print('CartController: === END REALTIME TEST ===');
      }
    } catch (e) {
      if (kDebugMode) {
        print('CartController: Test realtime error: $e');
      }
    }
  }

  /// Debug method to check for any kiosk cart items with any session ID
  ///
  /// This is useful for debugging to see if there are any items in the kiosk_cart table
  Future<void> debugCheckAllKioskCartItems() async {
    try {
      if (kDebugMode) {
        print('CartController: DEBUG - Checking all kiosk cart items');
      }

      final response = await supabase
          .from('kiosk_cart')
          .select('*')
          .order('created_at', ascending: false)
          .limit(10);

      if (kDebugMode) {
        print(
            'CartController: DEBUG - Found ${response.length} total kiosk cart items:');
        for (var item in response) {
          print('CartController: DEBUG - Item: $item');
        }
      }

      // Also check if the product_variants and products exist for the variant_ids
      if (response.isNotEmpty) {
        final variantIds = response.map((item) => item['variant_id']).toSet();

        for (var variantId in variantIds) {
          try {
            final variantCheck = await supabase
                .from('product_variants')
                .select('*, products(*)')
                .eq('variant_id', variantId)
                .single();

            if (kDebugMode) {
              print(
                  'CartController: DEBUG - Variant $variantId data: $variantCheck');
            }
          } catch (e) {
            if (kDebugMode) {
              print(
                  'CartController: DEBUG - No variant/product data for variant_id $variantId: $e');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('CartController: DEBUG - Error: ${e.toString()}');
      }
    }
  }

  /// Checks if currently fetching kiosk cart data
  bool get isFetchingKioskCart => _isFetchingKioskCart.value;

  /// Clears the scanned kiosk session and resets to local cart mode
  void clearKioskSession() {
    _scannedKioskSessionId.value = '';
    cartItems.clear();
    _localCartIdCounter.value = 1;
    _updateCartSummary();
    clearStockAdjustments();

    if (kDebugMode) {
      print(
          'CartController: Cleared kiosk session and reset to local cart mode');
    }
  }

  /// Adds an item to the current kiosk cart (if a session is active)
  ///
  /// @param variantId The ID of the product variant to add
  /// @param quantity The quantity to add
  /// @return Future<bool> Success status
  Future<bool> addToKioskCart(int variantId, {int quantity = 1}) async {
    try {
      if (_scannedKioskSessionId.value.isEmpty) {
        // No active kiosk session, add to local cart instead
        return await _addToLocalCart(variantId, quantity);
      }

      // Validate variant availability and stock
      final isValid = await _validateVariantForLocalCart(variantId, quantity);
      if (!isValid) {
        return false;
      }

      // Check max quantity limit from shop controller
      final maxAllowedQuantity = await _shopController.maxAllowedQuantity();

      if (quantity > maxAllowedQuantity) {
        TLoader.errorSnackBar(
          title: 'Whoa, Slow Down!',
          message:
              'Quantity exceeds maximum allowed (Max: $maxAllowedQuantity)',
        );
        return false;
      }

      // Add to kiosk cart in database
      final success = await _cartRepository.addToKioskCart(
        _scannedKioskSessionId.value,
        variantId,
        quantity,
      );

      if (success) {
        // Refresh cart to get updated data
        await _fetchKioskCartData(_scannedKioskSessionId.value);
        return true;
      } else {
        _handleError('Failed to add item to kiosk cart');
        return false;
      }
    } catch (e) {
      _handleError('Error adding item to kiosk cart: ${e.toString()}');
      return false;
    }
  }

  /// Updates the quantity of a kiosk cart item
  ///
  /// @param cartItemModel The cart item to update
  /// @param newQuantity The new quantity (must be > 0)
  /// @return Future<bool> Success status
  Future<bool> updateKioskCartItemQuantity(
      CartItemModel cartItemModel, int newQuantity) async {
    if (newQuantity <= 0) {
      return await removeKioskCartItem(cartItemModel);
    }

    try {
      if (_scannedKioskSessionId.value.isEmpty) {
        // No active kiosk session, update local cart instead
        return await updateCartItemQuantity(cartItemModel, newQuantity);
      }

      // Validate max quantity limit
      final maxAllowedQuantity = await _shopController.maxAllowedQuantity();

      if (newQuantity > maxAllowedQuantity) {
        TLoader.errorSnackBar(
          title: 'Whoa, Slow Down!',
          message:
              'Quantity exceeds maximum allowed (Max: $maxAllowedQuantity)',
        );
        return false;
      }

      // Update kiosk cart item in database
      final success = await _cartRepository.updateKioskCartItemQuantity(
        cartItemModel.cart.cartId, // This is actually kiosk_id in kiosk cart
        newQuantity,
      );

      if (success) {
        // Refresh cart to get updated data
        await _fetchKioskCartData(_scannedKioskSessionId.value);
        return true;
      } else {
        _handleError('Failed to update kiosk cart item quantity');
        return false;
      }
    } catch (e) {
      _handleError('Error updating kiosk cart item quantity: ${e.toString()}');
      return false;
    }
  }

  /// Removes an item from the kiosk cart
  ///
  /// @param cartItemModel The cart item to remove
  /// @return Future<bool> Success status
  Future<bool> removeKioskCartItem(CartItemModel cartItemModel) async {
    try {
      if (_scannedKioskSessionId.value.isEmpty) {
        // No active kiosk session, remove from local cart instead
        return await removeCartItem(cartItemModel);
      }

      // Remove from kiosk cart in database
      final success = await _cartRepository.removeKioskCartItem(
        cartItemModel.cart.cartId, // This is actually kiosk_id in kiosk cart
      );

      if (success) {
        // Refresh cart to get updated data
        await _fetchKioskCartData(_scannedKioskSessionId.value);
        TLoader.successSnackBar(title: 'Item removed from kiosk cart');
        return true;
      } else {
        _handleError('Failed to remove item from kiosk cart');
        return false;
      }
    } catch (e) {
      _handleError('Error removing item from kiosk cart: ${e.toString()}');
      return false;
    }
  }
}
