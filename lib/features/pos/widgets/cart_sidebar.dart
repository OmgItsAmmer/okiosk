import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:okiosk/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:okiosk/common/widgets/icons/t_circular_icon.dart';
import 'package:okiosk/common/widgets/texts/currency_text.dart';
import 'package:okiosk/features/pos/controller/pos_controller.dart';
import 'package:okiosk/features/cart/model/cart_model.dart';
import 'package:okiosk/features/cart/controller/cart_controller.dart';
import 'package:okiosk/features/cart/screens/widgets/cart_item_card.dart';
import 'package:okiosk/features/media/controller/media_controller.dart';
import 'package:okiosk/utils/layouts/template.dart';
import 'package:okiosk/utils/constants/colors.dart';

import 'package:okiosk/utils/constants/sizes.dart';
import 'package:iconsax/iconsax.dart';

import '../../../utils/helpers/helper_functions.dart';
import '../../../common/widgets/loaders/tloaders.dart';
import 'package:okiosk/features/checkout/screens/checkout_screen.dart';
import 'package:okiosk/features/checkout/controller/checkout_controller.dart';

/// Cart Sidebar Widget for POS Kiosk
///
/// Contains cart summary, total pricing, and checkout button
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

          // Cart Items List - Takes most of the space
          Expanded(
            flex: 7, // Give more space to cart items
            child: _buildCartItemsList(context, controller),
          ),

          // Cart Summary - Compact
          _buildCartSummary(context, controller),

          // Checkout Button - Compact
          _buildCheckoutButton(context, controller),
        ],
      ),
    );
  }

  /// Build cart header with item count
  Widget _buildCartHeader(BuildContext context, PosController controller) {
    final dark = THelperFunctions.isDarkMode(context);
    final cartController = Get.find<CartController>();

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
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.shopping_cart,
                size: PosLayoutTemplate.getResponsiveFontSize(context, 24),
                color: dark
                    ? TColors.darkModePrimaryText
                    : TColors.lightModePrimaryText,
              ),
              SizedBox(
                  width: PosLayoutTemplate.getResponsiveSpacing(context, 8)),
              Expanded(
                child: Text(
                  'Cart',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: PosLayoutTemplate.getResponsiveFontSize(
                            context, 20),
                        fontWeight: FontWeight.bold,
                        color: dark
                            ? TColors.darkModePrimaryText
                            : TColors.lightModePrimaryText,
                      ),
                ),
              ),
              Obx(() => TRoundedContainer(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    backgroundColor: dark
                        ? TColors.darkModePrimaryText
                        : TColors.lightModePrimaryText,
                    child: Text(
                      '${controller.cartItemCount}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: PosLayoutTemplate.getResponsiveFontSize(
                                context, 12),
                            color: dark
                                ? TColors.black
                                : TColors.lightModeTextWhite,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  )),
            ],
          ),
          // Kiosk session indicator
          Obx(() {
            if (cartController.scannedKioskSessionId.isNotEmpty &&
                cartController.scannedKioskSessionId !=
                    cartController.kioskUUID) {
              return Container(
                margin: EdgeInsets.only(
                    top: PosLayoutTemplate.getResponsiveSpacing(context, 8)),
                padding: EdgeInsets.symmetric(
                  horizontal:
                      PosLayoutTemplate.getResponsiveSpacing(context, 8),
                  vertical: PosLayoutTemplate.getResponsiveSpacing(context, 4),
                ),
                decoration: BoxDecoration(
                  color: TColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: TColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.link,
                      size: 16,
                      color: TColors.primary,
                    ),
                    SizedBox(
                        width:
                            PosLayoutTemplate.getResponsiveSpacing(context, 4)),
                    Expanded(
                      child: Text(
                        'Kiosk Session: ${cartController.scannedKioskSessionId.substring(0, 8)}...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: PosLayoutTemplate.getResponsiveFontSize(
                                  context, 12),
                              color: TColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showClearSessionDialog(context),
                      icon: Icon(
                        Icons.close,
                        size: 16,
                        color: TColors.primary,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
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
    final cartController = Get.find<CartController>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // QR Code Widget
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: QrImageView(
              data: cartController.kioskUUID,
              version: QrVersions.auto,
              size: PosLayoutTemplate.getResponsiveFontSize(context, 120),
              backgroundColor: Colors.white,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: TColors.primary,
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: TColors.primary,
              ),
            ),
          ),
          SizedBox(height: PosLayoutTemplate.getResponsiveSpacing(context, 16)),
          Text(
            'Scan to Load Cart',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize:
                      PosLayoutTemplate.getResponsiveFontSize(context, 18),
                  color: dark ? TColors.darkModePrimaryText : TColors.primary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: PosLayoutTemplate.getResponsiveSpacing(context, 8)),
          Text(
            'Customers can scan this QR code to connect their cart',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize:
                      PosLayoutTemplate.getResponsiveFontSize(context, 14),
                  color: dark
                      ? TColors.darkModeSecondaryText.withValues(alpha: 0.7)
                      : TColors.primary,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: PosLayoutTemplate.getResponsiveSpacing(context, 16)),
          // Action Buttons
          Row(
            children: [
              // QR Scanner Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showQRScannerDialog(context),
                  icon: Icon(
                    Icons.qr_code_scanner,
                    size: PosLayoutTemplate.getResponsiveFontSize(context, 18),
                  ),
                  label: Text(
                    'Scan QR',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: PosLayoutTemplate.getResponsiveFontSize(
                              context, 12),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.buttonPrimary,
                    foregroundColor: TColors.lightModeTextWhite,
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          PosLayoutTemplate.getResponsiveSpacing(context, 12),
                      vertical:
                          PosLayoutTemplate.getResponsiveSpacing(context, 10),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(
                  width: PosLayoutTemplate.getResponsiveSpacing(context, 8)),
              // Refresh Cart Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _refreshCart(context),
                  icon: Icon(
                    Icons.refresh,
                    size: PosLayoutTemplate.getResponsiveFontSize(context, 18),
                  ),
                  label: Text(
                    'Refresh',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: PosLayoutTemplate.getResponsiveFontSize(
                              context, 12),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary.withValues(alpha: 0.8),
                    foregroundColor: TColors.lightModeTextWhite,
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          PosLayoutTemplate.getResponsiveSpacing(context, 12),
                      vertical:
                          PosLayoutTemplate.getResponsiveSpacing(context, 10),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: PosLayoutTemplate.getResponsiveSpacing(context, 8)),
          // Debug button (only show in debug mode)
          if (kDebugMode)
            ElevatedButton.icon(
              onPressed: () => _debugCart(context),
              icon: Icon(
                Icons.bug_report,
                size: PosLayoutTemplate.getResponsiveFontSize(context, 16),
              ),
              label: Text(
                'Debug Cart',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize:
                          PosLayoutTemplate.getResponsiveFontSize(context, 12),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.error.withValues(alpha: 0.8),
                foregroundColor: TColors.lightModeTextWhite,
                padding: EdgeInsets.symmetric(
                  horizontal:
                      PosLayoutTemplate.getResponsiveSpacing(context, 12),
                  vertical: PosLayoutTemplate.getResponsiveSpacing(context, 8),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
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

  /// Build checkout button
  Widget _buildCheckoutButton(BuildContext context, PosController controller) {
    return Container(
      padding: context.responsivePadding,
      child: Obx(() => SizedBox(
            width: double.infinity,
            height: context.checkoutButtonSize.height,
            child: ElevatedButton(
              onPressed: controller.cartItems.isEmpty
                  ? null
                  : () => _openCheckoutDialog(context, controller),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.payment,
                    size: PosLayoutTemplate.getResponsiveFontSize(context, 20),
                  ),
                  SizedBox(
                      width:
                          PosLayoutTemplate.getResponsiveSpacing(context, 8)),
                  Text(
                    'Checkout',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: PosLayoutTemplate.getResponsiveFontSize(
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

  /// Open checkout dialog
  void _openCheckoutDialog(BuildContext context, PosController controller) {
    // Initialize checkout controller if not already initialized
    if (!Get.isRegistered<CheckoutController>()) {
      Get.put(CheckoutController());
    }
    Get.to(() => const CheckoutScreen());
  }

  /// Show QR scanner dialog for manual input
  void _showQRScannerDialog(BuildContext context) {
    final cartController = Get.find<CartController>();
    final dark = THelperFunctions.isDarkMode(context);
    final textController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text(
          'Scan Kiosk Cart QR Code',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: dark
                    ? TColors.darkModePrimaryText
                    : TColors.lightModePrimaryText,
              ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter the kiosk session ID from the QR code:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: dark
                        ? TColors.darkModeSecondaryText
                        : TColors.lightModeSecondaryText,
                  ),
            ),
            SizedBox(
                height: PosLayoutTemplate.getResponsiveSpacing(context, 16)),
            TextField(
              controller: textController,
              decoration: InputDecoration(
                hintText: 'Enter kiosk session ID...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor:
                    dark ? TColors.darkContainer : TColors.lightContainer,
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: dark
                        ? TColors.darkModePrimaryText
                        : TColors.lightModePrimaryText,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: dark
                    ? TColors.darkModeSecondaryText
                    : TColors.lightModeSecondaryText,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final sessionId = textController.text.trim();
              if (sessionId.isNotEmpty) {
                Get.back();
                await cartController.handleKioskCartQRScan(sessionId);
              } else {
                TLoader.errorSnackBar(
                  title: 'Invalid Input',
                  message: 'Please enter a valid kiosk session ID.',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TColors.buttonPrimary,
              foregroundColor: TColors.lightModeTextWhite,
            ),
            child: const Text('Scan'),
          ),
        ],
      ),
    );
  }

  /// Refresh cart to check for new items
  void _refreshCart(BuildContext context) {
    final cartController = Get.find<CartController>();
    cartController.checkForExistingKioskCart();
  }

  /// Debug cart to check all items in database
  void _debugCart(BuildContext context) {
    final cartController = Get.find<CartController>();
    cartController.debugCheckAllKioskCartItems();
  }

  /// Show dialog to confirm clearing kiosk session
  void _showClearSessionDialog(BuildContext context) {
    final cartController = Get.find<CartController>();
    final dark = THelperFunctions.isDarkMode(context);

    Get.dialog(
      AlertDialog(
        title: Text(
          'Clear Kiosk Session',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: dark
                    ? TColors.darkModePrimaryText
                    : TColors.lightModePrimaryText,
              ),
        ),
        content: Text(
          'Are you sure you want to clear the current kiosk session? This will disconnect from the scanned cart.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: dark
                    ? TColors.darkModeSecondaryText
                    : TColors.lightModeSecondaryText,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: dark
                    ? TColors.darkModeSecondaryText
                    : TColors.lightModeSecondaryText,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              cartController.clearKioskSession();
              TLoader.successSnackBar(
                title: 'Session Cleared',
                message: 'Kiosk session has been cleared successfully.',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TColors.error,
              foregroundColor: TColors.lightModeTextWhite,
            ),
            child: const Text('Clear Session'),
          ),
        ],
      ),
    );
  }
}
