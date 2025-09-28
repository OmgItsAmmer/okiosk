import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:okiosk/common/widgets/chips/choice_chip.dart';
import 'package:okiosk/common/widgets/texts/currency_text.dart';
import 'package:okiosk/features/pos/controller/pos_controller.dart';
import 'package:okiosk/features/checkout/controller/checkout_controller.dart';
import 'package:okiosk/utils/constants/colors.dart';
import 'package:okiosk/utils/constants/enums.dart';
import 'package:okiosk/utils/constants/sizes.dart';
import 'package:okiosk/utils/helpers/helper_functions.dart';
import 'package:okiosk/utils/layouts/template.dart';

/// Checkout Screen for POS Kiosk
///
/// Displays payment methods, shipping methods, and handles checkout process
/// Designed as a popup dialog for better UX
class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final posController = Get.find<PosController>();
    final checkoutController = Get.find<CheckoutController>();
    final dark = THelperFunctions.isDarkMode(context);

    return Dialog(
      backgroundColor: dark ? TColors.dark : TColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Cart Summary
            _buildCartSummary(context, posController),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Payment Methods
            _buildPaymentMethods(context, checkoutController),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Shipping Methods
            _buildShippingMethods(context, checkoutController),

            const Spacer(),

            // Action Buttons
            _buildActionButtons(context, checkoutController),
          ],
        ),
      ),
    );
  }

  /// Build header with close button
  Widget _buildHeader(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Row(
      children: [
        Icon(
          Icons.shopping_cart_checkout,
          size: 32,
          color: TColors.primary,
        ),
        const SizedBox(width: TSizes.spaceBtwItems),
        Text(
          'Checkout',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: dark
                    ? TColors.darkModePrimaryText
                    : TColors.lightModePrimaryText,
              ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.close,
            color: dark
                ? TColors.darkModePrimaryText
                : TColors.lightModePrimaryText,
          ),
        ),
      ],
    );
  }

  /// Build cart summary section
  Widget _buildCartSummary(BuildContext context, PosController controller) {
    final dark = THelperFunctions.isDarkMode(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? TColors.darkContainer : TColors.lightContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dark ? TColors.borderSecondary : TColors.borderPrimary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: dark
                      ? TColors.darkModePrimaryText
                      : TColors.lightModePrimaryText,
                ),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          Obx(() => Column(
                children: [
                  _buildSummaryRow(
                    context,
                    'Subtotal',
                    'Rs ${controller.subTotal.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems / 2),
                  _buildSummaryRow(
                    context,
                    'Tax (10%)',
                    'Rs ${controller.taxAmount.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  Divider(color: TColors.borderPrimary, thickness: 1),
                  const SizedBox(height: TSizes.spaceBtwItems / 2),
                  _buildSummaryRow(
                    context,
                    'Total',
                    'Rs ${controller.cartTotal.toStringAsFixed(2)}',
                    isTotal: true,
                  ),
                ],
              )),
        ],
      ),
    );
  }

  /// Build summary row
  Widget _buildSummaryRow(BuildContext context, String label, String value,
      {bool isTotal = false}) {
    final dark = THelperFunctions.isDarkMode(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: isTotal ? 18 : 16,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: dark
                    ? TColors.darkModePrimaryText
                    : TColors.lightModePrimaryText,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: isTotal ? 18 : 16,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                color: dark
                    ? TColors.darkModePrimaryText
                    : TColors.lightModePrimaryText,
              ),
        ),
      ],
    );
  }

  /// Build payment methods selector
  Widget _buildPaymentMethods(
      BuildContext context, CheckoutController controller) {
    final paymentMethods = [
      PaymentMethods.cash,
      PaymentMethods.creditCard,
      PaymentMethods.jazzcash,
    ];
    final dark = THelperFunctions.isDarkMode(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: dark
                    ? TColors.darkModePrimaryText
                    : TColors.lightModePrimaryText,
              ),
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
        Obx(() => Wrap(
              spacing: TSizes.spaceBtwItems,
              runSpacing: TSizes.spaceBtwItems,
              children: paymentMethods
                  .map((method) => TChoiceChip(
                        text: _getPaymentMethodName(method),
                        selected: controller.selectedPaymentMethod == method,
                        onSelected: (selected) {
                          if (selected) {
                            controller.selectPaymentMethod(method);
                          }
                        },
                        showCheckmark: false,
                      ))
                  .toList(),
            )),
      ],
    );
  }

  /// Build shipping methods selector
  Widget _buildShippingMethods(
      BuildContext context, CheckoutController controller) {
    final shippingMethods = [
      ShippingMethods.shipping,
      ShippingMethods.pickup,
    ];
    final dark = THelperFunctions.isDarkMode(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shipping Method',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: dark
                    ? TColors.darkModePrimaryText
                    : TColors.lightModePrimaryText,
              ),
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
        Obx(() => Wrap(
              spacing: TSizes.spaceBtwItems,
              runSpacing: TSizes.spaceBtwItems,
              children: shippingMethods
                  .map((method) => TChoiceChip(
                        text: _getShippingMethodName(method),
                        selected: controller.selectedShippingMethod == method,
                        onSelected: (selected) {
                          if (selected) {
                            controller.selectShippingMethod(method);
                          }
                        },
                        showCheckmark: false,
                      ))
                  .toList(),
            )),
      ],
    );
  }

  /// Build action buttons
  Widget _buildActionButtons(
      BuildContext context, CheckoutController controller) {
    final posController = Get.find<PosController>();
    return Row(
      children: [
        // Cancel Button
        Expanded(
          child: OutlinedButton(
            onPressed: () => Get.back(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: TSizes.spaceBtwItems),
        // Process Payment Button
        Expanded(
          flex: 2,
          child: Obx(() => ElevatedButton(
                onPressed:
                    posController.cartItems.isEmpty || controller.isProcessing
                        ? null
                        : () => _processCheckout(context, controller),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.buttonPrimary,
                  disabledBackgroundColor: TColors.buttonDisabled,
                  foregroundColor: TColors.lightModeTextWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: controller.isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: TColors.lightModeTextWhite,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Process Payment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              )),
        ),
      ],
    );
  }

  /// Process checkout
  Future<void> _processCheckout(
      BuildContext context, CheckoutController controller) async {
    final posController = Get.find<PosController>();

    if (posController.cartItems.isEmpty) {
      Get.snackbar(
        'Cart Empty',
        'Please add items to cart before checkout',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    try {
      final success = await controller.processCheckout();

      if (success) {
        Get.back(); // Close checkout dialog
      }
    } catch (e) {
      Get.snackbar(
        'Checkout Failed',
        'An error occurred during checkout. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: TColors.error,
        colorText: TColors.lightModeTextWhite,
      );
    }
  }

  /// Get payment method display name
  String _getPaymentMethodName(PaymentMethods method) {
    switch (method) {
      case PaymentMethods.cash:
        return 'Cash';
      case PaymentMethods.creditCard:
        return 'Card';
      case PaymentMethods.jazzcash:
        return 'JazzCash';
      default:
        return method.name;
    }
  }

  /// Get shipping method display name
  String _getShippingMethodName(ShippingMethods method) {
    switch (method) {
      case ShippingMethods.shipping:
        return 'Shipping';
      case ShippingMethods.pickup:
        return 'Pickup';
      default:
        return method.name;
    }
  }
}
