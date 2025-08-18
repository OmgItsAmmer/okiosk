import 'package:flutter/material.dart';

import '../../../../common/widgets/images/t_rounded_image.dart';
import '../../../../common/widgets/texts/expandable_text.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../media/controller/media_controller.dart';

/// Cart Item Widget - Displays individual cart item details
///
/// This widget follows the Single Responsibility Principle by focusing solely on
/// displaying cart item information. It's designed to be reusable and maintainable
/// with proper separation of concerns and flexible styling options.
///
/// The widget implements:
/// - Responsive design for different screen sizes
/// - Fallback handling for missing data
/// - Consistent styling with theme integration
/// - Accessibility support with proper semantics
/// - Expandable text for long product names and variant names
class TCartItem extends StatefulWidget {
  const TCartItem({
    super.key,
    required this.productId,
    required this.mediaController,
    required this.brandId,
    required this.productTitle,
    required this.variantName,
    this.dark,
    this.showBrandVerification = true,
    this.maxTitleLines = 2,
    this.imageSize = 60.0,
    this.spacing = TSizes.sm,
    this.padding = TSizes.xs,
    this.borderRadius = 8.0,
    this.onImageTap,
    this.onItemTap,
    this.customAttributes,
  });

  // Required parameters
  final int productId;
  final MediaController mediaController;
  final int brandId;
  final String productTitle;
  final String variantName;

  final bool? dark;
  final bool showBrandVerification;
  final int maxTitleLines;
  final double imageSize;
  final double spacing;
  final double padding;
  final double borderRadius;

  // Callback functions for interactivity
  final VoidCallback? onImageTap;
  final VoidCallback? onItemTap;

  // Additional attributes for extensibility
  final List<CartItemAttribute>? customAttributes;

  @override
  State<TCartItem> createState() => _TCartItemState();
}

class _TCartItemState extends State<TCartItem> {
  @override
  Widget build(BuildContext context) {
    final bool isDark = THelperFunctions.isDarkMode(context);

    return InkWell(
      onTap: widget.onItemTap,
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Container(
        padding: EdgeInsets.all(widget.padding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Section
            _buildProductImage(isDark),

            SizedBox(width: widget.spacing),

            // Product Details Section
            Expanded(
              child: _buildProductDetails(context, isDark),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the product image with proper fallback handling
  ///
  /// Implements proper error handling and fallback images for better UX
  Widget _buildProductImage(bool isDark) {
    return GestureDetector(
      onTap: widget.onImageTap,
      child: FutureBuilder<String?>(
        future: widget.mediaController
            .fetchMainImage(widget.productId, MediaCategory.products.name),
        builder: (context, snapshot) {
          final String imageUrl = snapshot.data ?? '';
          final bool hasImage = snapshot.hasData &&
              snapshot.data != null &&
              snapshot.data!.isNotEmpty;

          return TRoundedImage(
            //is dark logic
            imageurl: hasImage
                ? imageUrl
                : isDark
                    ? TImages.darkAppLogo
                    : TImages.lightAppLogo,
            width: widget.imageSize,
            height: widget.imageSize,
            isNetworkImage: hasImage,
            // padding: EdgeInsets.all(padding),
            backgroundColor: isDark ? TColors.darkerGrey : TColors.light,
            borderRadius: widget.borderRadius,
            fit: BoxFit.cover,
            // Note: TRoundedImage will handle loading and error states internally
          );
        },
      ),
    );
  }

  /// Builds the product details section with proper hierarchy
  ///
  /// Follows design principles for information hierarchy and readability
  Widget _buildProductDetails(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Product Title with expandable functionality
        _buildExpandableProductTitle(context, isDark),

        const SizedBox(height: 4),

        // Product Attributes
        _buildProductAttributes(context, isDark),
      ],
    );
  }

  /// Builds expandable product title widget
  Widget _buildExpandableProductTitle(BuildContext context, bool isDark) {
    return TExpandableText(
      text: widget.productTitle,
      style: Theme.of(context).textTheme.titleSmall,
      maxLines: widget.maxTitleLines,
      expandTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: TColors.primary,
            fontWeight: FontWeight.w600,
            // decoration: TextDecoration.underline,
          ),
      collapseTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: TColors.primary,
            fontWeight: FontWeight.w600,
            // decoration: TextDecoration.underline,
          ),
    );
  }

  /// Builds product attributes section (size, calories, custom attributes)
  ///
  /// Implements flexible attribute display that can be extended easily
  Widget _buildProductAttributes(BuildContext context, bool isDark) {
    final List<Widget> attributeWidgets = [];

    // Size attribute
    if (widget.variantName.isNotEmpty) {
      attributeWidgets.add(
        _buildExpandableAttributeRow(
          context,
          isLabel: false,
          label: 'Variant',
          value: widget.variantName,
          isDark: isDark,
        ),
      );
    }

    // Custom attributes for extensibility
    if (widget.customAttributes != null) {
      for (final attribute in widget.customAttributes!) {
        if (attribute.value.isNotEmpty) {
          attributeWidgets.add(
            _buildAttributeRow(
              context,
              label: attribute.label,
              value: attribute.value,
              isDark: isDark,
              icon: attribute.icon,
            ),
          );
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: attributeWidgets,
    );
  }

  /// Builds expandable attribute row with consistent styling
  Widget _buildExpandableAttributeRow(
    BuildContext context, {
    bool isLabel = true,
    required String label,
    required String value,
    required bool isDark,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: isDark
                  ? TColors.darkModeSecondaryText
                  : TColors.lightModeSecondaryText,
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: TExpandableText(
              text: isLabel ? '$label: $value' : value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? TColors.white : TColors.black,
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 1,
              expandTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: TColors.primary,
                    fontWeight: FontWeight.w600,
                    // decoration: TextDecoration.underline,
                    fontSize: 10,
                  ),
              collapseTextStyle:
                  Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: TColors.primary,
                        fontWeight: FontWeight.w600,
                        //  decoration: TextDecoration.underline,
                        fontSize: 10,
                      ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds individual attribute row with consistent styling
  ///
  /// Provides consistent formatting for all product attributes
  Widget _buildAttributeRow(
    BuildContext context, {
    required String label,
    required String value,
    required bool isDark,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: isDark ? TColors.grey : TColors.darkGrey,
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? TColors.grey : TColors.darkGrey,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  TextSpan(
                    text: value,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? TColors.white : TColors.black,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds loading placeholder for image loading
  Widget _buildLoadingPlaceholder(bool isDark) {
    return Container(
      width: widget.imageSize,
      height: widget.imageSize,
      decoration: BoxDecoration(
        color: isDark ? TColors.darkerGrey : TColors.light,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: Center(
        child: SizedBox(
          width: widget.imageSize * 0.3,
          height: widget.imageSize * 0.3,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? TColors.white : TColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  /// Gets valid image URL with fallback handling
  String _getValidImageUrl() {
    return TImages.productImage1; // Fallback to default image
  }

  /// Checks if the image URL is a valid network image
  bool _isValidNetworkImage() {
    return false; // Will be handled by FutureBuilder and hasImage check
  }

  /// Determines if dark mode is active
  bool _isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}

/// Data class for custom cart item attributes
///
/// Allows easy extension of cart item attributes without modifying the main widget.
/// Follows the Open/Closed Principle by being open for extension.
class CartItemAttribute {
  bool isLabel = false; 
  final String label;
  final String value;
  final IconData? icon;

   CartItemAttribute({
    this.isLabel = false,
    required this.label,
    required this.value,
    this.icon,
  });

  /// Factory constructor for common attributes
  factory CartItemAttribute.weight(String weight) {
    return CartItemAttribute(
      label: 'Weight',
      value: weight,
      icon: Icons.monitor_weight_outlined,
    );
  }

  /// Factory constructor for color attributes
  factory CartItemAttribute.color(String color) {
    return CartItemAttribute(
      label: 'Color',
      value: color,
      icon: Icons.palette_outlined,
    );
  }

  /// Factory constructor for material attributes
  factory CartItemAttribute.material(String material) {
    return CartItemAttribute(
      label: 'Material',
      value: material,
      icon: Icons.texture_outlined,
    );
  }

  /// Factory constructor for expiry date
  factory CartItemAttribute.expiryDate(String date) {
    return CartItemAttribute(
      label: 'Expires',
      value: date,
      icon: Icons.schedule_outlined,
    );
  }
}

/// Compact version of cart item for use in smaller spaces
///
/// Provides a more condensed representation suitable for
/// summary views or checkout screens
class TCompactCartItem extends StatelessWidget {
  const TCompactCartItem({
    super.key,
    required this.imageUrl,
    required this.productTitle,
    required this.size,
    this.brand,
    this.dark,
  });

  final String imageUrl;
  final String productTitle;
  final String size;
  final String? brand;
  final bool? dark;

  @override
  Widget build(BuildContext context) {
    final bool isDark = dark ?? Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        // Compact image
        TRoundedImage(
          imageurl: imageUrl.isNotEmpty ? imageUrl : TImages.productImage1,
          width: 40,
          height: 40,
          isNetworkImage: imageUrl.startsWith('http'),
          borderRadius: 6,
          backgroundColor: isDark ? TColors.darkerGrey : TColors.light,
        ),

        const SizedBox(width: TSizes.spaceBtwItems / 2),

        // Compact details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                productTitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (size.isNotEmpty)
                Text(
                  'Size: $size',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Cart Item wrapper that handles image fetching similar to ProductCardWithImage
///
/// This wrapper follows the same pattern as ProductCardWithImage to ensure
/// consistent image handling across the application
class TCartItemWithImage extends StatelessWidget {
  const TCartItemWithImage({
    super.key,
    required this.productId,
    required this.mediaController,
    required this.brandId,
    required this.productTitle,
    required this.variantName,
    this.dark,
    this.showBrandVerification = true,
    this.maxTitleLines = 2,
    this.imageSize = 60.0,
    this.spacing = TSizes.sm,
    this.padding = TSizes.xs,
    this.borderRadius = 8.0,
    this.onImageTap,
    this.onItemTap,
    this.customAttributes,
  });

  final int productId;
  final MediaController mediaController;
  final int brandId;
  final String productTitle;
  final String variantName;
  final bool? dark;
  final bool showBrandVerification;
  final int maxTitleLines;
  final double imageSize;
  final double spacing;
  final double padding;
  final double borderRadius;
  final VoidCallback? onImageTap;
  final VoidCallback? onItemTap;
  final List<CartItemAttribute>? customAttributes;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: mediaController.fetchMainImage(productId, 'product'),
      builder: (context, snapshot) {
        // Get the image URL from the snapshot or use fallback
        final String imageUrl = snapshot.data ?? '';
        final bool hasImage = snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.isNotEmpty;

        return TCartItem(
          productId: productId,
          mediaController: mediaController,
          brandId: brandId,
          productTitle: productTitle,
          variantName: variantName,
          dark: dark,
          showBrandVerification: showBrandVerification,
          maxTitleLines: maxTitleLines,
          imageSize: imageSize,
          spacing: spacing,
          padding: padding,
          borderRadius: borderRadius,
          onImageTap: onImageTap,
          onItemTap: onItemTap,
          customAttributes: customAttributes,
        );
      },
    );
  }
}
