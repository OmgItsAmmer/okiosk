import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../common/widgets/chips/choice_chip.dart';
import '../../../data/backend/models/action_data_models.dart';
import '../../../features/products/models/product_variation_model.dart';
import '../controller/chat_controller.dart';

/// Variant Selection Chat Bubble
///
/// Displays a special chat bubble for variant selection when the AI
/// needs the user to choose a product variant before adding to cart
class VariantSelectionBubble extends StatelessWidget {
  final VariantSelectionActionData variantData;
  final String message;
  final VoidCallback? onVariantSelected;

  const VariantSelectionBubble({
    super.key,
    required this.variantData,
    required this.message,
    this.onVariantSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: TSizes.spaceBtwItems,
        left: TSizes.defaultSpace,
        right: TSizes.defaultSpace,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message bubble with variant selection
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            decoration: BoxDecoration(
              color: TColors.lightContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(TSizes.borderRadiusSm),
                topRight: Radius.circular(TSizes.borderRadiusLg),
                bottomLeft: Radius.circular(TSizes.borderRadiusSm),
                bottomRight: Radius.circular(TSizes.borderRadiusLg),
              ),
              border: Border.all(
                color: TColors.borderPrimary.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: TColors.black.withValues(alpha: 0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI message
                Text(
                  message,
                  style: const TextStyle(
                    color: TColors.lightModePrimaryText,
                    fontSize: TSizes.fontSizeMd,
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwItems),

                // Variant selection section
                _buildVariantSelection(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build the variant selection interface
  Widget _buildVariantSelection(BuildContext context) {
    final inStockVariants = variantData.inStockVariants;
    final outOfStockVariants = variantData.outOfStockVariants;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product info header
        Container(
          padding: const EdgeInsets.all(TSizes.sm),
          decoration: BoxDecoration(
            color: TColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
          ),
          child: Row(
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 16,
                color: TColors.primary,
              ),
              const SizedBox(width: TSizes.xs),
              Expanded(
                child: Text(
                  '${variantData.productName} (Qty: ${variantData.quantity})',
                  style: TextStyle(
                    fontSize: TSizes.fontSizeSm,
                    fontWeight: FontWeight.w600,
                    color: TColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: TSizes.sm),

        // In stock variants
        if (inStockVariants.isNotEmpty) ...[
          Text(
            'Available Variants:',
            style: TextStyle(
              fontSize: TSizes.fontSizeSm,
              fontWeight: FontWeight.w600,
              color: TColors.lightModeSecondaryText,
            ),
          ),
          const SizedBox(height: TSizes.xs),
          Wrap(
            spacing: TSizes.xs,
            runSpacing: TSizes.xs,
            children: inStockVariants.map((variant) {
              return TChoiceChip(
                text:
                    '${variant.variantName ?? 'Unknown'} - ${variant.formattedPrice}',
                selected: false,
                onSelected: (selected) {
                  if (selected) {
                    _selectVariant(variant);
                  }
                },
                isOutOfStock: false,
                showCheckmark: false,
              );
            }).toList(),
          ),
          const SizedBox(height: TSizes.sm),
        ],

        // Out of stock variants
        if (outOfStockVariants.isNotEmpty) ...[
          Text(
            'Out of Stock:',
            style: TextStyle(
              fontSize: TSizes.fontSizeSm,
              fontWeight: FontWeight.w600,
              color: TColors.error,
            ),
          ),
          const SizedBox(height: TSizes.xs),
          Wrap(
            spacing: TSizes.xs,
            runSpacing: TSizes.xs,
            children: outOfStockVariants.map((variant) {
              return TChoiceChip(
                text:
                    '${variant.variantName ?? 'Unknown'} - ${variant.formattedPrice}',
                selected: false,
                onSelected: null, // Disabled for out of stock
                isOutOfStock: true,
                showCheckmark: false,
              );
            }).toList(),
          ),
        ],

        // No variants available
        if (inStockVariants.isEmpty && outOfStockVariants.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(TSizes.sm),
            decoration: BoxDecoration(
              color: TColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_outlined,
                  size: 16,
                  color: TColors.error,
                ),
                const SizedBox(width: TSizes.xs),
                Text(
                  'No variants available for this product',
                  style: TextStyle(
                    fontSize: TSizes.fontSizeSm,
                    color: TColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Handle variant selection
  /// Updated to use the new backend format from CART_AI_MODULE.md
  void _selectVariant(ProductVariationModel variant) {
    final chatController = Get.find<ChatController>();

    // Create a new AI command with the selected variant using the format:
    // "Product Name (Variant Name)" - this will be parsed by the backend
    final command =
        'Add ${variantData.quantity} ${variantData.productName} (${variant.variantName}) to cart';

    if (kDebugMode) {
      print('VariantSelectionBubble: Sending command: $command');
      print(
          'VariantSelectionBubble: Selected variant ID: ${variant.variantId}');
      print(
          'VariantSelectionBubble: Selected variant name: ${variant.variantName}');
    }

    // Send the command to AI
    chatController.sendMessage(command);

    // Call callback if provided
    onVariantSelected?.call();
  }
}
