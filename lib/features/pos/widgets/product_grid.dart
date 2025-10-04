import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:okiosk/features/pos/controller/pos_controller.dart';
import 'package:okiosk/features/products/models/product_model.dart';
import 'package:okiosk/features/media/controller/media_controller.dart';
import 'package:okiosk/common/widgets/products/product_cards/product_cart_with_dynamic_image.dart';
import 'package:okiosk/features/products/screens/widgets/quick_add_to_cart_dialog.dart';
import 'package:okiosk/utils/effects/shimmer%20effect.dart';
import 'package:okiosk/utils/layouts/template.dart';
import 'package:okiosk/utils/constants/colors.dart';

import '../../../utils/constants/sizes.dart';

/// Product Grid Widget for POS Kiosk
///
/// Displays products in a responsive grid layout that adapts to screen size
/// Uses Wrap widget to automatically wrap items if horizontal space is tight
class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PosController>();
    final mediaController = Get.put(MediaController());

    return Container(
      width: context.productGridWidth,
      height: context.mainContentHeight,
      padding: const EdgeInsets.all(TSizes.defaultSpace / 2),
      decoration: BoxDecoration(
        color: TColors.lightContainer, // secondary background
        boxShadow: [
          BoxShadow(
            color: TColors.borderPrimary.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() {
        if (controller.isLoading) {
          return const Center(child: TShimmerEffect(width: 100, height: 100));
        }

        final products = controller.filteredProducts;

        if (products.isEmpty) {
          return _buildEmptyState(context);
        }

        return _buildProductGrid(
            context, controller, mediaController, products);
      }),
    );
  }

  /// Build the main product grid
  Widget _buildProductGrid(BuildContext context, PosController controller,
      MediaController mediaController, List<ProductModel> products) {
    final spacing = PosLayoutTemplate.getResponsiveSpacing(context, 12.0);
    // Force exactly 3 columns by computing a fixed card size for the current grid width
    const int fixedColumns = 3;
    final double gridWidth = context.productGridWidth;
    final double cardWidth =
        (gridWidth - (spacing * (fixedColumns + 1))) / fixedColumns;
    final Size fixedCardSize = Size(cardWidth, cardWidth * 1.2);

    return SingleChildScrollView(
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: products
            .map((product) => _buildProductCard(
                  context: context,
                  product: product,
                  controller: controller,
                  mediaController: mediaController,
                  cardSize: fixedCardSize,
                ))
            .toList(),
      ),
    );
  }

  /// Build individual product card
  Widget _buildProductCard({
    required BuildContext context,
    required ProductModel product,
    required PosController controller,
    required MediaController mediaController,
    required Size cardSize,
  }) {
    final borderRadius = context.responsiveBorderRadius;

    return SizedBox(
      width: cardSize.width,
      height: cardSize.height,
      child: Material(
        color: TColors.primaryBackground, // contrast card surface
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(
            color: TColors.borderPrimary.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: () =>
              _openQuickAddToCartDialog(context, product, mediaController),
          child: ProductCardWithImage(
            product: product,
            mediaController: mediaController,
          ),
        ),
      ),
    );
  }

  /// Open the quick add to cart dialog with macOS-style expand animation
  void _openQuickAddToCartDialog(BuildContext context, ProductModel product,
      MediaController mediaController) {
    try {
      // Try to get the product image from media controller
      mediaController
          .fetchMainImage(product.productId, 'product')
          .then((imageUrl) {
        if (imageUrl != null && imageUrl.isNotEmpty) {
          // Show the quick add to cart dialog with the fetched image
          _showAnimatedDialog(
            context,
            QuickAddToCartDialog(
              product: product,
              imageUrl: imageUrl,
              isNetworkImage: true,
            ),
          );
        } else {
          // Show dialog with default image
          _showAnimatedDialog(
            context,
            QuickAddToCartDialog(
              product: product,
              imageUrl: '',
              isNetworkImage: false,
            ),
          );
        }
      }).catchError((e) {
        // Show dialog with default image on error
        if (kDebugMode) {
          print(
              'Error fetching product image for product ${product.productId}: $e');
        }
        _showAnimatedDialog(
          context,
          QuickAddToCartDialog(
            product: product,
            imageUrl: '',
            isNetworkImage: false,
          ),
        );
      });
    } catch (e) {
      // If no image found, use default
      if (kDebugMode) {
        print('No product image found for product ${product.productId}: $e');
      }
      // Show dialog with default image
      _showAnimatedDialog(
        context,
        QuickAddToCartDialog(
          product: product,
          imageUrl: '',
          isNetworkImage: false,
        ),
      );
    }
  }

  /// Show dialog with macOS-style expand animation
  void _showAnimatedDialog(BuildContext context, Widget dialog) {
    Get.generalDialog(
      pageBuilder: (context, animation, secondaryAnimation) {
        return dialog;
      },
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // Create a scale animation that starts small and grows to full size
        final scaleAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));

        // Create a fade animation
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        ));

        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Build empty state when no products are found
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: PosLayoutTemplate.getResponsiveFontSize(context, 64),
            color: TColors.primary.withValues(alpha: 0.6),
          ),
          SizedBox(height: PosLayoutTemplate.getResponsiveSpacing(context, 16)),
          Text(
            'No Products Found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize:
                      PosLayoutTemplate.getResponsiveFontSize(context, 24),
                  color: TColors.lightModePrimaryText,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: PosLayoutTemplate.getResponsiveSpacing(context, 8)),
          Text(
            'Try selecting a different category',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize:
                      PosLayoutTemplate.getResponsiveFontSize(context, 16),
                  color: TColors.lightModeSecondaryText,
                ),
          ),
        ],
      ),
    );
  }
}
