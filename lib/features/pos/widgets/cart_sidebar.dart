import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:okiosk/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:okiosk/common/widgets/icons/t_circular_icon.dart';
import 'package:okiosk/common/widgets/texts/currency_text.dart';
import 'package:okiosk/common/widgets/chips/choice_chip.dart';
import 'package:okiosk/features/pos/controller/pos_controller.dart';
import 'package:okiosk/features/cart/model/cart_model.dart';
import 'package:okiosk/features/cart/screens/widgets/cart_item_card.dart';
import 'package:okiosk/features/media/controller/media_controller.dart';
import 'package:okiosk/utils/layouts/template.dart';
import 'package:okiosk/utils/constants/colors.dart';
import 'package:okiosk/utils/constants/enums.dart';
import 'package:okiosk/utils/constants/sizes.dart';
import 'package:iconsax/iconsax.dart';

import '../../../utils/helpers/helper_functions.dart';

/// Cart Sidebar Widget for POS Kiosk
///
/// Contains cart summary, total pricing, payment method selector, and checkout button
/// Fixed width and consistent across all screen sizes
class CartSidebar extends StatelessWidget {
  const CartSidebar({
    super.key,
    required this.mediaController,
  });

  final MediaController mediaController;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PosController>();
    final dark = THelperFunctions.isDarkMode(context);

    return Container(
      width: context.cartSidebarWidth,
      height: context.mainContentHeight,
      decoration: BoxDecoration(
        color: dark ? TColors.dark : TColors.white,
        border: Border(
          left: BorderSide(
            color: TColors.borderPrimary,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
                dark ? TColors.black : TColors.darkGrey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cart Header
          _buildCartHeader(context, controller),

          // Cart Items List
          Expanded(
            child: _buildCartItemsList(context, controller),
          ),

          // Cart Summary
          _buildCartSummary(context, controller),

          // Payment Methods
          _buildPaymentMethods(context, controller),

          // Shipping Methods
          _buildShippingMethods(context, controller),

          // Checkout Button
          _buildCheckoutButton(context, controller),
        ],
      ),
    );
  }

  /// Build cart header with item count
  Widget _buildCartHeader(BuildContext context, PosController controller) {
    final dark = THelperFunctions.isDarkMode(context);
    return Container(
      padding: context.responsivePadding,
      decoration: BoxDecoration(
        color: dark ? TColors.black : TColors.primary.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(
            color: TColors.borderPrimary,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shopping_cart,
            size: PosLayoutTemplate.getResponsiveFontSize(context, 24),
            color: dark
                ? TColors.darkModePrimaryText
                : TColors.lightModePrimaryText,
          ),
          SizedBox(width: PosLayoutTemplate.getResponsiveSpacing(context, 8)),
          Text(
            'Cart',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize:
                      PosLayoutTemplate.getResponsiveFontSize(context, 20),
                  fontWeight: FontWeight.bold,
                  color: dark
                      ? TColors.darkModePrimaryText
                      : TColors.lightModePrimaryText,
                ),
          ),
          const Spacer(),
          Obx(() => TRoundedContainer(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                backgroundColor: dark
                    ? TColors.darkModePrimaryText
                    : TColors.lightModePrimaryText,
                child: Text(
                  '${controller.cartItemCount}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: PosLayoutTemplate.getResponsiveFontSize(
                            context, 12),
                        color:
                            dark ? TColors.black : TColors.lightModeTextWhite,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              )),
        ],
      ),
    );
  }

  /// Build cart items list
  Widget _buildCartItemsList(BuildContext context, PosController controller) {
    return Obx(() {
      if (controller.cartItems.isEmpty) {
        return _buildEmptyCart(context);
      }

      return ListView.separated(
        padding:
            EdgeInsets.all(PosLayoutTemplate.getResponsiveSpacing(context, 12)),
        itemCount: controller.cartItems.length,
        separatorBuilder: (context, index) => SizedBox(
          height: PosLayoutTemplate.getResponsiveSpacing(context, 8),
        ),
        itemBuilder: (context, index) {
          final cartItem = controller.cartItems[index];
          return _buildCartItem(context, controller, cartItem);
        },
      );
    });
  }

  /// Build individual cart item with improved UI and controls
  Widget _buildCartItem(
      BuildContext context, PosController controller, CartItemModel cartItem) {
    final dark = THelperFunctions.isDarkMode(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding:
            EdgeInsets.all(PosLayoutTemplate.getResponsiveSpacing(context, 8)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cart Item Details - Left side
            Expanded(
              flex: 3,
              child: TCartItemWithImage(
                dark: dark,
                productId: cartItem.cart.variantId ?? 1,
                mediaController: mediaController,
                brandId: cartItem.brandId ?? 1,
                productTitle: cartItem.productName,
                variantName: cartItem.variantName,
                showBrandVerification: false,
                maxTitleLines: 1,
                imageSize: 50.0,
                spacing: PosLayoutTemplate.getResponsiveSpacing(context, 6),
                padding: 0,
                borderRadius: context.responsiveBorderRadius,
                onItemTap: null,
                customAttributes: [
                  CartItemAttribute(
                    isLabel: false,
                    label: 'Price',
                    value:
                        'Rs ${cartItem.effectivePrice.toStringAsFixed(2)} each',
                    // icon: Icons.attach_money,
                  ),
                ],
              ),
            ),

            const SizedBox(width: TSizes.sm),

            // Quantity and Price Controls - Right side
            Expanded(
              flex: 2,
              child: _buildCompactQuantityAndPriceControls(
                  context, controller, cartItem),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds compact quantity controls and price display for horizontal layout
  Widget _buildCompactQuantityAndPriceControls(
    BuildContext context,
    PosController controller,
    CartItemModel cartItem,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Price Display at top
        _buildCompactPriceDisplay(context, cartItem),

        const SizedBox(height: 8),

        // Quantity Controls at bottom
        _buildCompactQuantityControls(context, controller, cartItem),
      ],
    );
  }

  /// Builds quantity controls and price display with responsive layout
  Widget _buildQuantityAndPriceControls(
    BuildContext context,
    PosController controller,
    CartItemModel cartItem,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 350;

        if (isSmallScreen) {
          // Stack layout for very small screens
          return Column(
            children: [
              // Price display below
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Quantity controls on top
                  _buildQuantityControls(context, controller, cartItem,
                      isCompact: true),
                  _buildPriceDisplay(context, cartItem),
                ],
              ),
            ],
          );
        } else {
          // Side by side layout for larger screens
          return Row(
            children: [
              // Quantity Control Section
              Expanded(
                flex: 3,
                child: _buildQuantityControls(context, controller, cartItem),
              ),

              const SizedBox(width: TSizes.spaceBtwItems),

              // Price Display Section
              Expanded(
                flex: 2,
                child: _buildPriceDisplay(context, cartItem),
              ),
            ],
          );
        }
      },
    );
  }

  /// Builds compact quantity controls for horizontal layout
  Widget _buildCompactQuantityControls(
    BuildContext context,
    PosController controller,
    CartItemModel cartItem,
  ) {
    final dark = THelperFunctions.isDarkMode(context);

    return Container(
      decoration: BoxDecoration(
        color: dark ? TColors.darkContainer : TColors.lightContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: dark ? TColors.borderSecondary : TColors.borderPrimary,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Remove item button
          Expanded(
            child: _buildRemoveButton(context, controller, cartItem,
                size: 38, iconSize: 18),
          ),

          const SizedBox(width: TSizes.spaceBtwItems * 2),

          // Decrease quantity button
          Expanded(
            child: _buildQuantityButton(
              context,
              icon: Iconsax.minus,
              onPressed: () => _decreaseQuantity(context, controller, cartItem),
              enabled: cartItem.cart.quantityAsInt > 1,
              size: 38,
              iconSize: 18,
            ),
          ),

          const SizedBox(width: TSizes.spaceBtwItems),

          // Current quantity display
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minWidth: 30),
              child: Text(
                cartItem.cart.quantityAsInt.toString(),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: dark
                          ? TColors.darkModePrimaryText
                          : TColors.lightModePrimaryText,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(width: TSizes.spaceBtwItems),

          // Increase quantity button
          Expanded(
            child: _buildQuantityButton(
              context,
              icon: Iconsax.add,
              onPressed: () => _increaseQuantity(context, controller, cartItem),
              enabled: _canIncreaseQuantity(cartItem),
              size: 38,
              iconSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds quantity control buttons with responsive design
  Widget _buildQuantityControls(
    BuildContext context,
    PosController controller,
    CartItemModel cartItem, {
    bool isCompact = false,
  }) {
    final dark = THelperFunctions.isDarkMode(context);

    return Container(
      decoration: BoxDecoration(
        color: dark ? TColors.darkContainer : TColors.lightContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: dark ? TColors.borderSecondary : TColors.borderPrimary,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: 4,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final buttonSize = isCompact ? 32.0 : 36.0;
          final iconSize = isCompact ? 18.0 : 20.0;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Decrease quantity button
              Center(
                child: _buildQuantityButton(
                  context,
                  icon: Iconsax.minus,
                  onPressed: () =>
                      _decreaseQuantity(context, controller, cartItem),
                  enabled: cartItem.cart.quantityAsInt > 1,
                  size: buttonSize,
                  iconSize: iconSize,
                ),
              ),

              SizedBox(width: isCompact ? 8 : TSizes.spaceBtwItems),

              // Current quantity display
              Container(
                constraints: BoxConstraints(minWidth: isCompact ? 35 : 40),
                child: Text(
                  cartItem.cart.quantityAsInt.toString(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isCompact ? 14 : 16,
                        color: dark
                            ? TColors.darkModePrimaryText
                            : TColors.lightModePrimaryText,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(width: isCompact ? 8 : TSizes.spaceBtwItems),

              // Increase quantity button
              Center(
                child: _buildQuantityButton(
                  context,
                  icon: Iconsax.add,
                  onPressed: () =>
                      _increaseQuantity(context, controller, cartItem),
                  enabled: _canIncreaseQuantity(cartItem),
                  size: buttonSize,
                  iconSize: iconSize,
                ),
              ),

              SizedBox(width: isCompact ? 8 : TSizes.spaceBtwItems),

              // Remove item button
              Center(
                child: _buildRemoveButton(context, controller, cartItem,
                    size: buttonSize, iconSize: iconSize),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Builds individual quantity control button with responsive sizing
  Widget _buildQuantityButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback? onPressed,
    required bool enabled,
    double size = 36,
    double iconSize = 20,
  }) {
    final dark = THelperFunctions.isDarkMode(context);
    return TCircularIcon(
      icon: icon,
      size: iconSize,
      width: size,
      height: size,
      backgroundColor: enabled
          ? TColors.buttonPrimary
          : (dark ? TColors.darkGrey : TColors.grey),
      color: enabled
          ? TColors.lightModeTextWhite
          : (dark
              ? TColors.darkModeSecondaryText
              : TColors.lightModeSecondaryText),
      onPressed: enabled ? onPressed : null,
    );
  }

  /// Builds remove item button with confirmation and responsive sizing
  Widget _buildRemoveButton(
    BuildContext context,
    PosController controller,
    CartItemModel cartItem, {
    double size = 36,
    double iconSize = 20,
  }) {
    final dark = THelperFunctions.isDarkMode(context);
    return TCircularIcon(
      icon: Iconsax.trash,
      size: iconSize,
      width: size,
      height: size,
      backgroundColor: TColors.error,
      color: TColors.lightModeTextWhite,
      onPressed: () => _showRemoveConfirmation(context, controller, cartItem),
    );
  }

  /// Builds compact price display for horizontal layout
  Widget _buildCompactPriceDisplay(
      BuildContext context, CartItemModel cartItem) {
    final dark = THelperFunctions.isDarkMode(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Unit price
        Text(
          'Rs ${cartItem.effectivePrice.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: dark
                    ? TColors.darkModeSecondaryText
                    : TColors.lightModeSecondaryText,
              ),
        ),

        // Total price for this item
        TProductPriceText(
          price: cartItem.totalPrice.toStringAsFixed(2),
          isLarge: false,
        ),
      ],
    );
  }

  /// Builds price display section with reactive updates
  Widget _buildPriceDisplay(BuildContext context, CartItemModel cartItem) {
    final dark = THelperFunctions.isDarkMode(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Unit price
        Text(
          'Rs ${cartItem.effectivePrice.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: dark
                    ? TColors.darkModeSecondaryText
                    : TColors.lightModeSecondaryText,
              ),
        ),

        // Total price for this item
        TProductPriceText(
          price: cartItem.totalPrice.toStringAsFixed(2),
          isLarge: false,
        ),
      ],
    );
  }

  /// Decreases item quantity with validation
  Future<void> _decreaseQuantity(
    BuildContext context,
    PosController controller,
    CartItemModel cartItem,
  ) async {
    final newQuantity = cartItem.cart.quantityAsInt - 1;

    if (newQuantity <= 0) {
      _showRemoveConfirmation(context, controller, cartItem);
    } else {
      controller.updateCartItemQuantity(cartItem, newQuantity);
    }
  }

  /// Increases item quantity with validation
  Future<void> _increaseQuantity(
    BuildContext context,
    PosController controller,
    CartItemModel cartItem,
  ) async {
    final newQuantity = cartItem.cart.quantityAsInt + 1;
    controller.updateCartItemQuantity(cartItem, newQuantity);
  }

  /// Checks if quantity can be increased
  bool _canIncreaseQuantity(CartItemModel cartItem) {
    const maxQuantityPerItem = 50; // Business rule
    final currentQuantity = cartItem.cart.quantityAsInt;
    final stockQuantity = cartItem.variantStock;

    // Check against maximum allowed and stock availability
    return currentQuantity < maxQuantityPerItem &&
        (stockQuantity <= 0 || currentQuantity < stockQuantity);
  }

  /// Shows confirmation dialog before removing item
  void _showRemoveConfirmation(
    BuildContext context,
    PosController controller,
    CartItemModel cartItem,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Remove Item'),
        content: Text(
          'Are you sure you want to remove "${cartItem.productName}" from your cart?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              controller.removeFromCart(cartItem);
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty cart state
  Widget _buildEmptyCart(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: PosLayoutTemplate.getResponsiveFontSize(context, 48),
            color: TColors.primary,
          ),
          SizedBox(height: PosLayoutTemplate.getResponsiveSpacing(context, 16)),
          Text(
            'Cart is Empty',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize:
                      PosLayoutTemplate.getResponsiveFontSize(context, 18),
                  color: dark ? TColors.darkModePrimaryText : TColors.primary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: PosLayoutTemplate.getResponsiveSpacing(context, 8)),
          Text(
            'Add products to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize:
                      PosLayoutTemplate.getResponsiveFontSize(context, 14),
                  color: dark
                      ? TColors.darkModeSecondaryText.withValues(alpha: 0.7)
                      : TColors.primary,
                ),
          ),
        ],
      ),
    );
  }

  /// Build cart summary with totals
  Widget _buildCartSummary(BuildContext context, PosController controller) {
    return Container(
      padding: context.responsivePadding,
      decoration: BoxDecoration(
        color: TColors.softGrey.withValues(alpha: 0.3),
        border: Border(
          top: BorderSide(color: TColors.borderPrimary),
          bottom: BorderSide(color: TColors.borderPrimary),
        ),
      ),
      child: Obx(() => Column(
            children: [
              _buildSummaryRow(
                context,
                'Subtotal',
                'Rs ${controller.subTotal.toStringAsFixed(2)}',
              ),
              SizedBox(
                  height: PosLayoutTemplate.getResponsiveSpacing(context, 4)),
              _buildSummaryRow(
                context,
                'Tax (10%)',
                'Rs ${controller.taxAmount.toStringAsFixed(2)}',
              ),
              SizedBox(
                  height: PosLayoutTemplate.getResponsiveSpacing(context, 8)),
              Divider(color: TColors.borderPrimary, thickness: 1),
              SizedBox(
                  height: PosLayoutTemplate.getResponsiveSpacing(context, 4)),
              _buildSummaryRow(
                context,
                'Total',
                'Rs ${controller.cartTotal.toStringAsFixed(2)}',
                isTotal: true,
              ),
            ],
          )),
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
                fontSize: PosLayoutTemplate.getResponsiveFontSize(
                    context, isTotal ? 16 : 14),
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: dark
                    ? TColors.darkModePrimaryText
                    : TColors.lightModePrimaryText,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: PosLayoutTemplate.getResponsiveFontSize(
                    context, isTotal ? 16 : 14),
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
  Widget _buildPaymentMethods(BuildContext context, PosController controller) {
    final paymentMethods = [
      PaymentMethods.cash,
      PaymentMethods.creditCard,
      PaymentMethods.jazzcash,
      //PaymentMethods.applePay,
    ];
    final dark = THelperFunctions.isDarkMode(context);
    return Container(
      padding: context.responsivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            'Payment Method',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize:
                      PosLayoutTemplate.getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.bold,
                  color: dark
                      ? TColors.darkModePrimaryText
                      : TColors.lightModePrimaryText,
                ),
          ),
          SizedBox(height: PosLayoutTemplate.getResponsiveSpacing(context, 8)),
          Obx(() => Wrap(
                alignment: WrapAlignment.start,
                spacing: PosLayoutTemplate.getResponsiveSpacing(context, 8),
                runSpacing: PosLayoutTemplate.getResponsiveSpacing(context, 8),
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
      ),
    );
  }

  /// Build shipping methods selector
  Widget _buildShippingMethods(BuildContext context, PosController controller) {
    final shippingMethods = [
      ShippingMethods.shipping,
      ShippingMethods.pickup,
    ];
    final dark = THelperFunctions.isDarkMode(context);
    return Container(
      padding: context.responsivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            'Shipping Method',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize:
                      PosLayoutTemplate.getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.bold,
                  color: dark
                      ? TColors.darkModePrimaryText
                      : TColors.lightModePrimaryText,
                ),
          ),
          SizedBox(height: PosLayoutTemplate.getResponsiveSpacing(context, 8)),
          Obx(() => Wrap(
                alignment: WrapAlignment.start,
                spacing: PosLayoutTemplate.getResponsiveSpacing(context, 8),
                runSpacing: PosLayoutTemplate.getResponsiveSpacing(context, 8),
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
      ),
    );
  }

  /// Build checkout button
  Widget _buildCheckoutButton(BuildContext context, PosController controller) {
    return Container(
      padding: context.responsivePadding,
      child: Obx(() => SizedBox(
            width: double.infinity,
            height: context.checkoutButtonSize.height,
            child: ElevatedButton(
              onPressed: controller.cartItems.isEmpty || controller.isLoading
                  ? null
                  : () => controller.processCheckout(),
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.buttonPrimary,
                disabledBackgroundColor: TColors.buttonDisabled,
                foregroundColor: TColors.lightModeTextWhite,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(context.responsiveBorderRadius),
                ),
                elevation: 2,
              ),
              child: controller.isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: TColors.lightModeTextWhite,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.payment,
                          size: PosLayoutTemplate.getResponsiveFontSize(
                              context, 20),
                        ),
                        SizedBox(
                            width: PosLayoutTemplate.getResponsiveSpacing(
                                context, 8)),
                        Text(
                          'Checkout',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontSize:
                                        PosLayoutTemplate.getResponsiveFontSize(
                                            context, 18),
                                    fontWeight: FontWeight.bold,
                                    color: TColors.lightModeTextWhite,
                                  ),
                        ),
                      ],
                    ),
            ),
          )),
    );
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
