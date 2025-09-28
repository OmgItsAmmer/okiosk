import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:okiosk/features/cart/screens/widgets/cart_item_card.dart';

import '../../../../../common/navigation/navigation_helper.dart';
import '../../../../../common/widgets/products/cart/cart_item.dart';
import '../../../../../common/widgets/texts/currency_text.dart';
import '../../../../../common/widgets/texts/expandable_text.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../common/widgets/icons/t_circular_icon.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/image_strings.dart';
import '../../../../../common/widgets/images/t_rounded_image.dart';
import '../../../../../common/widgets/texts/brand_title_with_verification.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../utils/effects/shimmer effect.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../media/controller/media_controller.dart';
import '../../../products/controller/product_varaintion_controller.dart';
import '../../controller/cart_controller.dart';
import '../../model/cart_model.dart';

/// Cart Items Widget - Displays list of cart items with quantity controls
///
/// This widget follows the MVVM pattern and uses the refactored CartController
/// with CartItemModel for type safety and better state management.
/// It implements proper error handling and optimistic UI updates.
class TCartItems extends StatelessWidget {
  const TCartItems({
    super.key,
    this.showAddRemovebutton = true,
    this.physics,
    this.padding,
  });

  final bool showAddRemovebutton;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartController>();
    Get.put(MediaController());
    Get.put(ProductVariationController());

    return Obx(() {
      // Show loading state
      if (cartController.isLoading.value) {
        return _buildLoadingState();
      }

      // Show empty state
      if (cartController.isCartEmpty) {
        return _buildEmptyState(context);
      }

      // Show cart items
      return _buildCartItemsList(cartController);
    });
  }

  /// Builds the loading state with shimmer effects
  Widget _buildLoadingState() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3, // Show 3 skeleton items
      separatorBuilder: (_, __) => const SizedBox(height: TSizes.spaceBtwItems),
      itemBuilder: (_, __) => _buildShimmerItem(),
    );
  }

  /// Builds individual shimmer item for loading state
  Widget _buildShimmerItem() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(TSizes.md),
        child: Row(
          children: const [
            TShimmerEffect(width: 60, height: 60, radius: 8),
            SizedBox(width: TSizes.spaceBtwItems),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TShimmerEffect(width: 100, height: 16),
                  SizedBox(height: 4),
                  TShimmerEffect(width: 150, height: 14),
                  SizedBox(height: 4),
                  TShimmerEffect(width: 80, height: 12),
                ],
              ),
            ),
            TShimmerEffect(width: 60, height: 30),
          ],
        ),
      ),
    );
  }

  /// Builds empty state message
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          Text(
            'No items in cart',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  /// Builds the main cart items list
  Widget _buildCartItemsList(CartController cartController) {
    return ListView.separated(
      shrinkWrap: true,
      physics: physics ?? const BouncingScrollPhysics(),
      padding: padding,
      itemCount: cartController.cartItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: TSizes.spaceBtwItems),
      itemBuilder: (_, index) => _buildCartItemCard(
        cartController.cartItems[index],
        cartController,
        index,
      ),
    );
  }

  /// Builds individual cart item card with all controls
  Widget _buildCartItemCard(
    CartItemModel cartItem,
    CartController cartController,
    int index,
  ) {
    final mediaController = Get.find<MediaController>();
    final productVariationController = Get.find<ProductVariationController>();

    // Get the product ID for the current cart item
    final productId =
        productVariationController.getProductId(cartItem.cart.variantId!);

    // Check if this item has been adjusted
    final adjustment =
        cartController.getAdjustmentForCartItem(cartItem.cart.cartId);
    final hasAdjustment = adjustment != null;

    return Card(
      elevation: hasAdjustment ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasAdjustment
            ? BorderSide(
                color: adjustment.shouldRemove
                    ? Colors.red.withValues(alpha: 0.5)
                    : Colors.orange.withValues(alpha: 0.5),
                width: 2,
              )
            : BorderSide.none,
      ),
      child: Container(
        decoration: hasAdjustment
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    adjustment.shouldRemove
                        ? Colors.red.withValues(alpha: 0.05)
                        : Colors.orange.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(TSizes.sm),
          child: Column(
            children: [
              // Adjustment indicator
              if (hasAdjustment) _buildAdjustmentIndicator(adjustment),

              // Cart Item Details
              TCartItemWithImage(
                dark: THelperFunctions.isDarkMode(Get.context!),
                productId: productId,
                mediaController: mediaController,
                brandId: cartItem.brandId ?? -1,
                productTitle: cartItem.productName,
                variantName: cartItem.variantName,
              ),

              // Alternative: Show tooltip for long text (uncomment to use)
              // _buildTooltipCartItem(cartItem, mediaController, productId),

              if (showAddRemovebutton) ...[
                const SizedBox(height: TSizes.sm),
                _buildQuantityAndPriceControls(cartItem, cartController),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds adjustment indicator widget
  Widget _buildAdjustmentIndicator(CartStockValidation adjustment) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: TSizes.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: adjustment.shouldRemove
            ? Colors.red.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: adjustment.shouldRemove
              ? Colors.red.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            adjustment.shouldRemove ? Icons.remove_shopping_cart : Icons.update,
            size: 16,
            color:
                adjustment.shouldRemove ? Colors.red[700] : Colors.orange[700],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              adjustment.adjustmentType.label,
              style: Get.theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: adjustment.shouldRemove
                    ? Colors.red[700]
                    : Colors.orange[700],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: adjustment.shouldRemove
                  ? Colors.red[100]
                  : Colors.orange[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              adjustment.shouldRemove ? 'Will be removed' : 'Quantity adjusted',
              style: Get.theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: adjustment.shouldRemove
                    ? Colors.red[800]
                    : Colors.orange[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds quantity controls and price display with responsive layout
  Widget _buildQuantityAndPriceControls(
    CartItemModel cartItem,
    CartController cartController,
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
                  _buildQuantityControls(cartItem, cartController,
                      isCompact: true),
                  _buildPriceDisplay(cartItem),
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
                child: _buildQuantityControls(cartItem, cartController),
              ),

              const SizedBox(width: TSizes.spaceBtwItems),

              // Price Display Section
              Expanded(
                flex: 2,
                child: _buildPriceDisplay(cartItem),
              ),
            ],
          );
        }
      },
    );
  }

  /// Builds quantity control buttons with responsive design
  Widget _buildQuantityControls(
    CartItemModel cartItem,
    CartController cartController, {
    bool isCompact = false,
  }) {
    final dark = THelperFunctions.isDarkMode(Get.context!);

    return Container(
      decoration: BoxDecoration(
        color: dark ? TColors.darkerGrey : TColors.light,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TColors.grey.withValues(alpha: 0.3)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: 4,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final buttonSize = isCompact ? 24.0 : 28.0;
          final iconSize = isCompact ? 14.0 : 16.0;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Decrease quantity button
              Center(
                child: _buildQuantityButton(
                  icon: Iconsax.minus,
                  onPressed: () => _decreaseQuantity(cartItem, cartController),
                  enabled: cartItem.cart.quantityAsInt > 1,
                  size: buttonSize,
                  iconSize: iconSize,
                ),
              ),

              SizedBox(width: isCompact ? 8 : TSizes.spaceBtwItems),

              // Current quantity display
              Container(
                constraints: BoxConstraints(minWidth: isCompact ? 25 : 30),
                child: Text(
                  cartItem.cart.quantityAsInt.toString(),
                  style: Get.theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isCompact ? 12 : 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(width: isCompact ? 8 : TSizes.spaceBtwItems),

              // Increase quantity button
              Center(
                child: _buildQuantityButton(
                  icon: Iconsax.add,
                  onPressed: () => _increaseQuantity(cartItem, cartController),
                  enabled: _canIncreaseQuantity(cartItem),
                  size: buttonSize,
                  iconSize: iconSize,
                ),
              ),

              SizedBox(width: isCompact ? 8 : TSizes.spaceBtwItems),

              // Remove item button
              Center(
                child: _buildRemoveButton(cartItem, cartController,
                    size: buttonSize, iconSize: iconSize),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Builds individual quantity control button with responsive sizing
  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool enabled,
    double size = 28,
    double iconSize = 16,
  }) {
    return TCircularIcon(
      icon: icon,
      size: iconSize,
      width: size,
      height: size,
      backgroundColor: enabled ? TColors.primary : TColors.grey,
      color: Colors.white,
      onPressed: enabled ? onPressed : null,
    );
  }

  /// Builds remove item button with confirmation and responsive sizing
  Widget _buildRemoveButton(
    CartItemModel cartItem,
    CartController cartController, {
    double size = 28,
    double iconSize = 16,
  }) {
    return TCircularIcon(
      icon: Iconsax.trash,
      size: iconSize,
      width: size,
      height: size,
      backgroundColor: TColors.error,
      color: Colors.white,
      onPressed: () => _showRemoveConfirmation(cartItem, cartController),
    );
  }

  /// Builds price display section with reactive updates
  Widget _buildPriceDisplay(CartItemModel cartItem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Unit price
        Text(
          'Rs ${cartItem.effectivePrice.toStringAsFixed(2)}',
          style: Get.theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
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
    CartItemModel cartItem,
    CartController cartController,
  ) async {
    final newQuantity = cartItem.cart.quantityAsInt - 1;

    if (newQuantity <= 0) {
      _showRemoveConfirmation(cartItem, cartController);
    } else {
      await cartController.updateCartItemQuantity(cartItem, newQuantity);
    }
  }

  /// Increases item quantity with validation
  Future<void> _increaseQuantity(
    CartItemModel cartItem,
    CartController cartController,
  ) async {
    final newQuantity = cartItem.cart.quantityAsInt + 1;
    await cartController.updateCartItemQuantity(cartItem, newQuantity);
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
    CartItemModel cartItem,
    CartController cartController,
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
              NavigationHelper.goBack(Get.overlayContext!);
              await cartController.removeCartItem(cartItem);
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

  /// Alternative method using tooltip for long text
  /// Uncomment the call to this method in _buildCartItemCard to use tooltip approach
  Widget _buildTooltipCartItem(
    CartItemModel cartItem,
    MediaController mediaController,
    int productId,
  ) {
    final isDark = THelperFunctions.isDarkMode(Get.context!);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Image
        GestureDetector(
          onTap: () {}, // Add image tap handler if needed
          child: FutureBuilder<String?>(
            future: mediaController.fetchMainImage(productId, 'product'),
            builder: (context, snapshot) {
              final String imageUrl = snapshot.data ?? '';
              final bool hasImage = snapshot.hasData &&
                  snapshot.data != null &&
                  snapshot.data!.isNotEmpty;

              return TRoundedImage(
                imageurl: hasImage
                    ? imageUrl
                    : isDark
                        ? TImages.darkAppLogo
                        : TImages.lightAppLogo,
                width: 60,
                height: 60,
                isNetworkImage: hasImage,
                backgroundColor: isDark ? TColors.darkerGrey : TColors.light,
                borderRadius: 8,
                fit: BoxFit.cover,
              );
            },
          ),
        ),

        const SizedBox(width: TSizes.sm),

        // Product Details with Tooltip
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Brand Name

              // Product Title with Tooltip
              TTooltipText(
                text: cartItem.productName,
                style: Get.theme.textTheme.titleSmall,
                maxLines: 2,
                tooltipText: cartItem.productName,
              ),

              const SizedBox(height: 4),

              // Variant Name with Tooltip
              if (cartItem.variantName.isNotEmpty)
                TTooltipText(
                  text: 'Variant: ${cartItem.variantName}',
                  style: Get.theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? TColors.white : TColors.black,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  tooltipText: 'Variant: ${cartItem.variantName}',
                ),
            ],
          ),
        ),
      ],
    );
  }
}
