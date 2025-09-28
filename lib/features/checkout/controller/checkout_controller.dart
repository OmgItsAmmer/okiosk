import 'package:get/get.dart';
import 'package:okiosk/features/pos/controller/pos_controller.dart';
import 'package:okiosk/utils/constants/enums.dart';

/// Checkout Controller for handling checkout process
///
/// Manages checkout-specific state and logic
class CheckoutController extends GetxController {
  static CheckoutController get instance => Get.find();

  // Observable state variables
  final _selectedPaymentMethod = PaymentMethods.cash.obs;
  final _selectedShippingMethod = ShippingMethods.pickup.obs;
  final _isProcessing = false.obs;

  // Get PosController instance
  final PosController posController = Get.find<PosController>();

  // Getters for reactive state
  PaymentMethods get selectedPaymentMethod => _selectedPaymentMethod.value;
  ShippingMethods get selectedShippingMethod => _selectedShippingMethod.value;
  bool get isProcessing => _isProcessing.value;

  @override
  void onInit() {
    super.onInit();
    // Initialize with default values from POS controller
    _selectedPaymentMethod.value = posController.selectedPaymentMethod;
    _selectedShippingMethod.value = posController.selectedShippingMethod;
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

  /// Process checkout
  Future<bool> processCheckout() async {
    if (posController.cartItems.isEmpty) {
      Get.snackbar(
        'Cart Empty',
        'Please add items to cart before checkout',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }

    _isProcessing.value = true;

    try {
      // Simulate checkout process
      await Future.delayed(const Duration(seconds: 2));

      // Clear cart after successful checkout
      posController.clearCart();

      Get.snackbar(
        'Checkout Successful',
        'Payment processed successfully!',
        snackPosition: SnackPosition.TOP,
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Checkout Failed',
        'An error occurred during checkout. Please try again.',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    } finally {
      _isProcessing.value = false;
    }
  }

  /// Validate checkout data
  bool validateCheckout() {
    if (posController.cartItems.isEmpty) {
      return false;
    }

    // Add any additional validation logic here
    // For example, validate payment method, shipping method, etc.

    return true;
  }

  /// Get checkout summary
  Map<String, dynamic> getCheckoutSummary() {
    return {
      'subtotal': posController.subTotal,
      'tax': posController.taxAmount,
      'total': posController.cartTotal,
      'itemCount': posController.cartItemCount,
      'paymentMethod': selectedPaymentMethod,
      'shippingMethod': selectedShippingMethod,
    };
  }
}
