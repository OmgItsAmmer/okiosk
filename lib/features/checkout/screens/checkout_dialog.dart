import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:okiosk/common/widgets/chips/choice_chip.dart';
import 'package:okiosk/features/cart/controller/cart_controller.dart';
import 'package:okiosk/features/checkout/controller/checkout_controller.dart';
import 'package:okiosk/utils/constants/colors.dart';
import 'package:okiosk/utils/constants/sizes.dart';

/// New Checkout Dialog for POS Kiosk
///
/// Features:
/// - Primary background with opacity
/// - Price breakdown (no tax, no shipping)
/// - Bag option with add/subtract buttons (Rs 50 per bag)
/// - Pick up payment method only (using choice chip)
/// - Confirm button that sends to Rust backend
class CheckoutDialog extends StatelessWidget {
  const CheckoutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final checkoutController = Get.find<CheckoutController>();
    final cartController = Get.find<CartController>();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: TColors.primaryBackground.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(context, checkoutController),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: TSizes.spaceBtwSections),

                    // Price Breakdown
                    _buildPriceBreakdown(
                        context, checkoutController, cartController),

                    const SizedBox(height: TSizes.spaceBtwSections),

                    // Bag Option
                    _buildBagOption(context, checkoutController),

                    const SizedBox(height: TSizes.spaceBtwSections),

                    // Payment Method
                    _buildPaymentMethod(context, checkoutController),

                    const SizedBox(height: TSizes.spaceBtwSections),
                  ],
                ),
              ),
            ),

            // Confirm Button (Fixed at bottom)
            _buildConfirmButton(context, checkoutController),
          ],
        ),
      ),
    );
  }

  /// Build header with title and close button
  Widget _buildHeader(BuildContext context, CheckoutController controller) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TColors.primary.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
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
                  color: TColors.primary,
                ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Get.back(),
            icon: Icon(
              Icons.close,
              color: TColors.primary,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  /// Build price breakdown section
  Widget _buildPriceBreakdown(
    BuildContext context,
    CheckoutController checkoutController,
    CartController cartController,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TColors.primary.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: TColors.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: TColors.primary,
                size: 24,
              ),
              const SizedBox(width: TSizes.spaceBtwItems / 2),
              Text(
                'Price Breakdown',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: TColors.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          Divider(color: TColors.primary.withOpacity(0.2), thickness: 1),
          const SizedBox(height: TSizes.spaceBtwItems),

          // Cart items count
          Obx(() => _buildBreakdownRow(
                context,
                'Items (${cartController.totalCartItems})',
                'Rs ${cartController.totalCartPrice.toStringAsFixed(2)}',
              )),
          const SizedBox(height: TSizes.spaceBtwItems / 2),

          // Bag cost
          Obx(() => checkoutController.includeBag
              ? Column(
                  children: [
                    _buildBreakdownRow(
                      context,
                      'Shopping Bags (${checkoutController.bagQuantity})',
                      'Rs ${checkoutController.bagTotal.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: TSizes.spaceBtwItems / 2),
                  ],
                )
              : const SizedBox.shrink()),

          // Tax (Rs 0)
          _buildBreakdownRow(
            context,
            'Tax',
            'Rs 0.00',
            isSubtle: true,
          ),
          const SizedBox(height: TSizes.spaceBtwItems / 2),

          // Shipping (Rs 0)
          _buildBreakdownRow(
            context,
            'Shipping Fee',
            'Rs 0.00',
            isSubtle: true,
          ),

          const SizedBox(height: TSizes.spaceBtwItems),
          Divider(color: TColors.primary.withOpacity(0.3), thickness: 2),
          const SizedBox(height: TSizes.spaceBtwItems),

          // Total
          Obx(() => _buildBreakdownRow(
                context,
                'Total',
                'Rs ${checkoutController.totalWithBags.toStringAsFixed(2)}',
                isTotal: true,
              )),
        ],
      ),
    );
  }

  /// Build breakdown row
  Widget _buildBreakdownRow(
    BuildContext context,
    String label,
    String value, {
    bool isTotal = false,
    bool isSubtle = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: isTotal ? 20 : 16,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isSubtle
                    ? TColors.darkGrey
                    : (isTotal
                        ? TColors.primary
                        : TColors.lightModePrimaryText),
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: isTotal ? 20 : 16,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                color: isSubtle
                    ? TColors.darkGrey
                    : (isTotal
                        ? TColors.primary
                        : TColors.lightModePrimaryText),
              ),
        ),
      ],
    );
  }

  /// Build bag option section
  Widget _buildBagOption(BuildContext context, CheckoutController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TColors.accent.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                color: TColors.accent,
                size: 24,
              ),
              const SizedBox(width: TSizes.spaceBtwItems / 2),
              Text(
                'Include Shopping Bag?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: TColors.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: TSizes.spaceBtwItems / 2),
          Text(
            'Rs 50 per bag',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: TColors.darkGrey,
                ),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          Obx(() => Row(
                children: [
                  // Yes/No toggle
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => controller.toggleIncludeBag(true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: controller.includeBag
                                    ? TColors.accent
                                    : TColors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: controller.includeBag
                                      ? TColors.accent
                                      : TColors.grey,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                'Yes',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: controller.includeBag
                                      ? TColors.white
                                      : TColors.darkGrey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: TSizes.spaceBtwItems / 2),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => controller.toggleIncludeBag(false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !controller.includeBag
                                    ? TColors.grey
                                    : TColors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: !controller.includeBag
                                      ? TColors.grey
                                      : TColors.grey.withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                'No',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: !controller.includeBag
                                      ? TColors.white
                                      : TColors.darkGrey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quantity controls (only show if bag is included)
                  if (controller.includeBag) ...[
                    const SizedBox(width: TSizes.spaceBtwItems),
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: TColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: TColors.accent.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Decrement button
                            IconButton(
                              onPressed: controller.decrementBagQuantity,
                              icon: Icon(
                                Icons.remove_circle,
                                color: TColors.accent,
                                size: 32,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),

                            // Quantity display
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: TColors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${controller.bagQuantity}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: TColors.primary,
                                    ),
                              ),
                            ),

                            // Increment button
                            IconButton(
                              onPressed: controller.incrementBagQuantity,
                              icon: Icon(
                                Icons.add_circle,
                                color: TColors.accent,
                                size: 32,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              )),
        ],
      ),
    );
  }

  /// Build payment method section
  Widget _buildPaymentMethod(
      BuildContext context, CheckoutController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TColors.primary.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payment,
                color: TColors.primary,
                size: 24,
              ),
              const SizedBox(width: TSizes.spaceBtwItems / 2),
              Text(
                'Payment Method',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: TColors.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: TSizes.spaceBtwItems),

          // For now, only Pick up is available
          // Using TChoiceChip but permanently selected
          TChoiceChip(
            text: 'Pick up',
            selected: true,
            onSelected: (_) {
              // Do nothing - it's the only option
            },
            showCheckmark: true,
          ),

          const SizedBox(height: TSizes.spaceBtwItems / 2),
          Text(
            'Payment at pickup counter',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: TColors.darkGrey,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }

  /// Build confirm button
  Widget _buildConfirmButton(
      BuildContext context, CheckoutController controller) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TColors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cancel Button
          Expanded(
            child: OutlinedButton(
              onPressed: () => Get.back(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(
                  color: TColors.primary,
                  width: 2,
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: TColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: TSizes.spaceBtwItems),

          // Confirm Button
          Expanded(
            flex: 2,
            child: Obx(() => ElevatedButton(
                  onPressed: controller.isProcessing
                      ? null
                      : () => _processCheckout(context, controller),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.accent,
                    disabledBackgroundColor: TColors.buttonDisabled,
                    foregroundColor: TColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: controller.isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: TColors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, size: 24),
                            const SizedBox(width: TSizes.spaceBtwItems / 2),
                            Text(
                              'Confirm Order',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                )),
          ),
        ],
      ),
    );
  }

  /// Process checkout
  Future<void> _processCheckout(
      BuildContext context, CheckoutController controller) async {
    try {
      final success = await controller.processCheckout();

      if (success) {
        // Close checkout dialog
        Get.back();

        // Show success message
        Get.snackbar(
          'Success!',
          'Order placed successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: TColors.success,
          colorText: TColors.white,
          duration: const Duration(seconds: 3),
        );

        // TODO: Print invoice
        // await controller.printInvoice(orderId, total);
      }
    } catch (e) {
      // Error is already handled in controller
    }
  }
}
