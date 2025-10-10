import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:okiosk/features/pos/controller/pos_controller.dart';
import 'package:okiosk/features/cart/model/cart_model.dart';
import 'package:okiosk/features/cart/controller/cart_controller.dart';
import 'package:okiosk/features/media/controller/media_controller.dart';
import 'package:okiosk/utils/layouts/template.dart';
import 'package:okiosk/utils/constants/colors.dart';

import 'package:iconsax/iconsax.dart';

import '../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../common/widgets/icons/t_circular_icon.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';
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

    return Container(
      decoration: BoxDecoration(
        color: TColors.primaryBackground,
        border: Border(
          left: BorderSide(
            color: TColors.borderPrimary,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: TColors.borderPrimary.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cart Header with Icon Buttons (same height as kiosk header)
          _buildCartHeaderWithButtons(context, controller),

          // Cart Search Bar
          _buildCartSearchBar(context, controller),

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

  /// Build cart header with icon buttons (same height as kiosk header)
  Widget _buildCartHeaderWithButtons(
      BuildContext context, PosController controller) {
    final dark = THelperFunctions.isDarkMode(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TSizes.defaultSpace / 2),
      decoration: BoxDecoration(
        color: dark ? TColors.primaryBackground : TColors.primaryBackground,
        border: Border(
          bottom: BorderSide(
            color: TColors.borderPrimary,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Cart title
          Text(
            'Cart',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: TColors.lightModePrimaryText,
                ),
          ),

          // Icon buttons row (moved from kiosk header)
          Row(
            children: [
              TCircularIcon(
                width: 40,
                height: 40,
                icon: Iconsax.notification,
                onPressed: () {},
                backgroundColor:
                    dark ? TColors.buttonPrimary : TColors.buttonPrimary,
                color: dark ? TColors.white : TColors.white,
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              TCircularIcon(
                width: 40,
                height: 40,
                icon: Iconsax.camera,
                onPressed: () {},
                backgroundColor:
                    dark ? TColors.buttonPrimary : TColors.buttonPrimary,
                color: dark ? TColors.white : TColors.white,
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              TCircularIcon(
                width: 40,
                height: 40,
                icon: Iconsax.scan_barcode,
                onPressed: () => _openQRScanner(context),
                backgroundColor:
                    dark ? TColors.buttonPrimary : TColors.buttonPrimary,
                color: dark ? TColors.white : TColors.white,
              ),
            ],
          )
        ],
      ),
    );
  }

  /// Build cart search bar
  Widget _buildCartSearchBar(BuildContext context, PosController controller) {
    final cartController = Get.find<CartController>();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (context.responsivePadding / 2).horizontal,
        vertical: (context.responsivePadding / 4).vertical,
      ),
      decoration: BoxDecoration(
        color: TColors.lightContainer.withValues(alpha: 0.25),
        border: Border(
          bottom: BorderSide(
            color: TColors.borderPrimary,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TRoundedContainer(
              height: PosLayoutTemplate.getResponsiveSpacing(context, 40),
              padding: EdgeInsets.symmetric(
                horizontal: PosLayoutTemplate.getResponsiveSpacing(context, 12),
              ),
              backgroundColor: TColors.primaryBackground.withValues(alpha: 0.1),
              borderColor: TColors.borderPrimary,
              shadowBorder: true,
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    size: PosLayoutTemplate.getResponsiveFontSize(context, 18),
                    color: TColors.lightModePrimaryText,
                  ),
                  SizedBox(
                      width:
                          PosLayoutTemplate.getResponsiveSpacing(context, 8)),
                  Expanded(
                    child: Obx(() => TextField(
                          controller: TextEditingController(
                            text: cartController.cartSearchQuery,
                          )..selection = TextSelection.fromPosition(
                              TextPosition(
                                offset: cartController.cartSearchQuery.length,
                              ),
                            ),
                          onChanged: (value) =>
                              cartController.setCartSearchQuery(value),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            hintText: 'search in cart',
                            hintStyle: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: TColors.lightModeSecondaryText,
                                ),
                          ),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: TColors.lightModePrimaryText,
                                  ),
                        )),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Open QR scanner (moved from kiosk header)
  void _openQRScanner(BuildContext context) {
    // Get.to(() => QRScannerWidget(
    //       onQRCodeScanned: (String qrData) async {
    //         Get.back(); // Close scanner
    //         await _handleQRCodeScanned(qrData);
    //       },
    //       title: 'Scan Customer QR Code',
    //       subtitle: 'Ask customer to show their QR code from the mobile app',
    //     ));
  }

  /// Build cart items list
  Widget _buildCartItemsList(BuildContext context, PosController controller) {
    final cartController = Get.find<CartController>();
    return Obx(() {
      final items = cartController.filteredCartItems;
      if (items.isEmpty) {
        return _buildEmptyCart(context);
      }

      return ListView.separated(
        padding:
            EdgeInsets.all(PosLayoutTemplate.getResponsiveSpacing(context, 12)),
        itemCount: items.length,
        separatorBuilder: (context, index) => SizedBox(
          height: PosLayoutTemplate.getResponsiveSpacing(context, 8),
        ),
        itemBuilder: (context, index) {
          final cartItem = items[index];
          return _buildCartItem(context, controller, cartItem);
        },
      );
    });
  }

  /// Build individual cart item with redesigned two-row layout
  Widget _buildCartItem(
      BuildContext context, PosController controller, CartItemModel cartItem) {
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: PosLayoutTemplate.getResponsiveSpacing(context, 4),
      ),
      decoration: BoxDecoration(
        color: TColors.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: TColors.borderPrimary.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding:
            EdgeInsets.all(PosLayoutTemplate.getResponsiveSpacing(context, 12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First row: Product name + variant name in parenthesis
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${cartItem.productName} (${cartItem.variantName})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: PosLayoutTemplate.getResponsiveFontSize(
                              context, 16),
                          fontWeight: FontWeight.w600,
                          color: TColors.primaryBackground,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            SizedBox(
                height: PosLayoutTemplate.getResponsiveSpacing(context, 8)),

            // Second row: Total price + quantity controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Total price
                Expanded(
                  flex: 2,
                  child: Text(
                    'Rs ${cartItem.totalPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: PosLayoutTemplate.getResponsiveFontSize(
                              context, 18),
                          fontWeight: FontWeight.bold,
                          color: TColors.primaryBackground,
                        ),
                  ),
                ),

                // Quantity controls
                Expanded(
                  flex: 3,
                  child: _buildRedesignedQuantityControls(
                      context, controller, cartItem),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds redesigned quantity controls for the new cart item layout
  Widget _buildRedesignedQuantityControls(
    BuildContext context,
    PosController controller,
    CartItemModel cartItem,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: TColors.primaryBackground.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: TColors.primaryBackground.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Remove item button
          _buildRedesignedButton(
            context,
            icon: Iconsax.trash,
            onPressed: () =>
                _showRemoveConfirmation(context, controller, cartItem),
            backgroundColor: TColors.error,
            size: 32,
            iconSize: 16,
          ),

          const SizedBox(width: 8),

          // Decrease quantity button
          _buildRedesignedButton(
            context,
            icon: Iconsax.minus,
            onPressed: () => _decreaseQuantity(context, controller, cartItem),
            enabled: cartItem.cart.quantityAsInt > 1,
            size: 32,
            iconSize: 16,
          ),

          const SizedBox(width: 8),

          // Current quantity display
          Container(
            constraints: const BoxConstraints(minWidth: 28),
            child: Text(
              cartItem.cart.quantityAsInt.toString(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: TColors.primaryBackground,
                  ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(width: 8),

          // Increase quantity button
          _buildRedesignedButton(
            context,
            icon: Iconsax.add,
            onPressed: () => _increaseQuantity(context, controller, cartItem),
            enabled: _canIncreaseQuantity(cartItem),
            size: 32,
            iconSize: 16,
          ),
        ],
      ),
    );
  }

  /// Builds redesigned button for quantity controls
  Widget _buildRedesignedButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback? onPressed,
    bool enabled = true,
    Color? backgroundColor,
    double size = 32,
    double iconSize = 16,
  }) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ??
              (enabled
                  ? TColors.primaryBackground.withValues(alpha: 0.2)
                  : TColors.primaryBackground.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: enabled
                ? TColors.primaryBackground.withValues(alpha: 0.5)
                : TColors.primaryBackground.withValues(alpha: 0.2),
          ),
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: enabled
              ? TColors.primaryBackground
              : TColors.primaryBackground.withValues(alpha: 0.5),
        ),
      ),
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
          // Debug info widget (show cart state)
        ],
      ),
    );
  }

  /// Build cart summary with totals
  Widget _buildCartSummary(BuildContext context, PosController controller) {
    return Container(
      padding: context.responsivePadding,
      decoration: BoxDecoration(
        color: TColors.lightContainer.withValues(alpha: 0.2),
        border: Border(
          top: BorderSide(color: TColors.borderPrimary),
          bottom: BorderSide(color: TColors.borderPrimary),
        ),
      ),
      child: Obx(() => Column(
            children: [
              // _buildSummaryRow(
              //   context,
              //   'Subtotal',
              //   'Rs ${controller.subTotal.toStringAsFixed(2)}',
              // ),
              // SizedBox(
              //     height: PosLayoutTemplate.getResponsiveSpacing(context, 4)),
              // _buildSummaryRow(
              //   context,
              //   'Tax (10%)',
              //   'Rs ${controller.taxAmount.toStringAsFixed(2)}',
              // ),
              // SizedBox(
              //     height: PosLayoutTemplate.getResponsiveSpacing(context, 8)),
              // Divider(color: TColors.borderPrimary, thickness: 1),
              // SizedBox(
              //     height: PosLayoutTemplate.getResponsiveSpacing(context, 4)),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: PosLayoutTemplate.getResponsiveFontSize(
                    context, isTotal ? 16 : 14),
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: TColors.lightModePrimaryText,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: PosLayoutTemplate.getResponsiveFontSize(
                    context, isTotal ? 16 : 14),
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                color: TColors.lightModePrimaryText,
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

  // removed: clear session dialog (not used after header simplification)
}
