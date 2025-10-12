import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:okiosk/features/cart/controller/cart_controller.dart';
import 'package:okiosk/features/pos/controller/pos_controller.dart';
import 'package:okiosk/utils/constants/enums.dart';
import 'package:okiosk/data/backend/services/checkout_api_service.dart';
import 'package:okiosk/common/widgets/loaders/tloaders.dart';

/// Checkout Controller for handling checkout process
///
/// Manages checkout-specific state, stock validation, and backend integration
class CheckoutController extends GetxController {
  static CheckoutController get instance => Get.find();

  // Observable state variables
  final _selectedPaymentMethod = PaymentMethods.cash.obs;
  final _selectedShippingMethod = ShippingMethods.pickup.obs;
  final _isProcessing = false.obs;
  final _includeBag = false.obs;
  final _bagQuantity = 0.obs;
  final _bagPrice = 50.0; // Rs 50 per bag

  // Get controllers and services
  final PosController posController = Get.find<PosController>();
  final CartController cartController = Get.find<CartController>();
  final CheckoutApiService _checkoutApiService = Get.find<CheckoutApiService>();

  // Getters for reactive state
  PaymentMethods get selectedPaymentMethod => _selectedPaymentMethod.value;
  ShippingMethods get selectedShippingMethod => _selectedShippingMethod.value;
  bool get isProcessing => _isProcessing.value;
  bool get includeBag => _includeBag.value;
  int get bagQuantity => _bagQuantity.value;
  double get bagTotal => _bagQuantity.value * _bagPrice;

  @override
  void onInit() {
    super.onInit();
    // Initialize with pickup as default (only option for now)
    _selectedPaymentMethod.value = PaymentMethods.cash;
    _selectedShippingMethod.value = ShippingMethods.pickup;
    _includeBag.value = false;
    _bagQuantity.value = 0;
  }

  /// Toggle include bag option
  void toggleIncludeBag(bool value) {
    _includeBag.value = value;
    if (!value) {
      _bagQuantity.value = 0;
    } else if (_bagQuantity.value == 0) {
      _bagQuantity.value = 1; // Start with 1 bag
    }
  }

  /// Increment bag quantity
  void incrementBagQuantity() {
    if (_includeBag.value) {
      _bagQuantity.value++;
    }
  }

  /// Decrement bag quantity
  void decrementBagQuantity() {
    if (_includeBag.value && _bagQuantity.value > 1) {
      _bagQuantity.value--;
    } else if (_bagQuantity.value == 1) {
      // If decreasing to 0, turn off bag option
      _bagQuantity.value = 0;
      _includeBag.value = false;
    }
  }

  /// Select payment method
  void selectPaymentMethod(PaymentMethods method) {
    _selectedPaymentMethod.value = method;
    // Also update POS controller to keep them in sync
    posController.selectPaymentMethod(method);
  }

  /// Select shipping method
  void selectShippingMethod(ShippingMethods method) {
    _selectedShippingMethod.value = method;
    // Also update POS controller to keep them in sync
    posController.selectShippingMethod(method);
  }

  /// Calculate total including bags
  double get totalWithBags {
    return cartController.totalCartPrice + bagTotal;
  }

  /// Validate stock before checkout
  ///
  /// Returns true if all items have sufficient stock, false otherwise
  /// Updates cart items to show which items have stock issues
  Future<bool> validateStockBeforeCheckout() async {
    try {
      if (kDebugMode) {
        print(
            'CheckoutController: Validating stock for ${cartController.cartItems.length} items');
      }

      // Validate cart stock using cart controller
      final hasIssues = await cartController.validateCartStock();

      if (hasIssues) {
        if (kDebugMode) {
          print(
              'CheckoutController: Stock validation failed - ${cartController.stockAdjustments.length} items need adjustment');
        }

        TLoader.errorSnackBar(
          title: 'Stock Unavailable',
          message:
              'Some items in your cart have insufficient stock. Please review and adjust quantities.',
        );
        return false;
      }

      if (kDebugMode) {
        print('CheckoutController: Stock validation passed');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('CheckoutController: Error validating stock - $e');
      }
      TLoader.errorSnackBar(
        title: 'Validation Error',
        message: 'Failed to validate cart stock: ${e.toString()}',
      );
      return false;
    }
  }

  /// Process checkout with backend
  ///
  /// This method prepares cart data and sends it to the Rust backend
  /// Following the CHECKOUT_MODULE.md specification
  Future<bool> processCheckout() async {
    if (cartController.cartItems.isEmpty) {
      TLoader.errorSnackBar(
        title: 'Cart Empty',
        message: 'Please add items to cart before checkout',
      );
      return false;
    }

    _isProcessing.value = true;

    try {
      if (kDebugMode) {
        print('CheckoutController: Starting checkout process');
      }

      // Prepare cart items for backend
      final cartItemsForBackend = cartController.cartItems.map((item) {
        return {
          'variantId': item.cart.variantId,
          'quantity': item.cart.quantityAsInt,
          'sellPrice': item.sellPrice.toString(),
          'buyPrice': (item.buyPrice ?? 0.0).toString(),
        };
      }).toList();

      // Add bags as a cart item if included
      if (_includeBag.value && _bagQuantity.value > 0) {
        // TODO: Get bag variant ID from backend or use a constant
        // For now, we'll skip adding bags to the cart items
        // They should be handled separately or have a dedicated variant
      }

      if (kDebugMode) {
        print(
            'CheckoutController: Prepared ${cartItemsForBackend.length} cart items');
        print(
            'CheckoutController: Shipping method: ${_selectedShippingMethod.value.name}');
        print(
            'CheckoutController: Payment method: ${_selectedPaymentMethod.value.name}');
      }

      // Call backend checkout API
      final response = await _checkoutApiService.processCheckout(
        customerId:
            1, // TODO: Get actual customer ID from customer controller or kiosk session
        addressId: -1, // -1 for pickup
        shippingMethod:
            _selectedShippingMethod.value.name, // "pickup" or "shipping"
        paymentMethod: _getBackendPaymentMethod(_selectedPaymentMethod.value),
        cartItems: cartItemsForBackend,
      );

      if (response.success && response.data != null) {
        final orderId = response.data!['orderId'];
        final total = response.data!['total'];

        if (kDebugMode) {
          print('CheckoutController: ✅ Checkout successful!');
          print('CheckoutController: Order ID: $orderId');
          print('CheckoutController: Total: $total');
        }

        // Clear cart after successful checkout
        await cartController.clearCart();

        // Reset bag options
        _includeBag.value = false;
        _bagQuantity.value = 0;

        TLoader.successSnackBar(
          title: 'Checkout Successful!',
          message: 'Order #$orderId placed successfully. Total: Rs $total',
        );

        return true;
      } else {
        if (kDebugMode) {
          print('CheckoutController: ❌ Checkout failed - ${response.message}');
        }

        TLoader.errorSnackBar(
          title: 'Checkout Failed',
          message: response.message,
        );
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('CheckoutController: ❌ Checkout exception - $e');
      }

      TLoader.errorSnackBar(
        title: 'Checkout Error',
        message: 'An error occurred: ${e.toString()}',
      );
      return false;
    } finally {
      _isProcessing.value = false;
    }
  }

  /// Convert PaymentMethods enum to backend format
  String _getBackendPaymentMethod(PaymentMethods method) {
    switch (method) {
      case PaymentMethods.cash:
        return 'pickup'; // For kiosk, cash means pay at pickup
      case PaymentMethods.creditCard:
        return 'credit_card';
      case PaymentMethods.jazzcash:
        return 'jazzcash';
      default:
        return 'pickup';
    }
  }

  /// Validate checkout data
  bool validateCheckout() {
    if (cartController.cartItems.isEmpty) {
      return false;
    }

    // Add any additional validation logic here
    // For example, validate payment method, shipping method, etc.

    return true;
  }

  /// Get checkout summary
  Map<String, dynamic> getCheckoutSummary() {
    return {
      'subtotal': cartController.totalCartPrice,
      'bagCost': bagTotal,
      'tax': 0.0, // No tax as per requirements
      'shippingFee': 0.0, // No shipping fee as per requirements
      'total': totalWithBags,
      'itemCount': cartController.totalCartItems,
      'bagCount': _bagQuantity.value,
      'paymentMethod': selectedPaymentMethod,
      'shippingMethod': selectedShippingMethod,
    };
  }

  /// Print invoice (placeholder for now)
  ///
  /// This should generate and print an invoice for the order
  /// TODO: Implement actual invoice printing logic
  Future<void> printInvoice(int orderId, double total) async {
    if (kDebugMode) {
      print('CheckoutController: ========== INVOICE ==========');
      print('CheckoutController: Order ID: $orderId');
      print('CheckoutController: Date: ${DateTime.now()}');
      print('CheckoutController: --------------------------------');
      print('CheckoutController: Items:');
      for (final item in cartController.cartItems) {
        print(
            'CheckoutController:   ${item.productName} x ${item.cart.quantityAsInt} @ Rs ${item.sellPrice}');
      }
      if (_includeBag.value && _bagQuantity.value > 0) {
        print(
            'CheckoutController:   Shopping Bag x $_bagQuantity @ Rs $_bagPrice');
      }
      print('CheckoutController: --------------------------------');
      print(
          'CheckoutController: Subtotal: Rs ${cartController.totalCartPrice}');
      if (bagTotal > 0) {
        print('CheckoutController: Bags: Rs $bagTotal');
      }
      print('CheckoutController: Tax: Rs 0.00');
      print('CheckoutController: Shipping: Rs 0.00');
      print('CheckoutController: --------------------------------');
      print('CheckoutController: TOTAL: Rs $total');
      print('CheckoutController: ================================');
    }

    // TODO: Integrate with actual printer
    // For example, using thermal printer, PDF generator, etc.
  }
}
