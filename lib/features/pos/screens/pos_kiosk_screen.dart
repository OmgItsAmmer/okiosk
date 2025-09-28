import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:okiosk/features/pos/controller/pos_controller.dart';
import 'package:okiosk/features/categories/controller/category_controller.dart';
import 'package:okiosk/features/products/controller/product_controller.dart';
import 'package:okiosk/features/products/controller/product_varaintion_controller.dart';
import 'package:okiosk/features/cart/controller/cart_controller.dart';
import 'package:okiosk/features/shop/controller/shop_controller.dart';
import 'package:okiosk/features/pos/widgets/category_selector.dart';
import 'package:okiosk/features/pos/widgets/product_grid.dart';
import 'package:okiosk/features/pos/widgets/cart_sidebar.dart';
import 'package:okiosk/features/media/controller/media_controller.dart';
import 'package:okiosk/utils/layouts/template.dart';
import 'package:okiosk/utils/constants/colors.dart';
import 'package:okiosk/utils/constants/sizes.dart';
import 'package:okiosk/utils/helpers/helper_functions.dart';

import '../../../common/widgets/header/kiosk_header.dart';

/// POS Kiosk Main Screen
///
/// This is the main screen for the Point of Sale kiosk application.
/// It provides a responsive layout that adapts to screen sizes between 15" and 32"
/// with support for minimum resolution of 1366x768.
///
/// Layout Structure:
/// - Top: Category selector (wrappable for large screens, scrollable for small)
/// - Center/Left (60-70%): Product grid with automatic wrapping
/// - Right Sidebar (30-35%): Cart summary, pricing, payment, and checkout
class PosKioskScreen extends StatelessWidget {
  const PosKioskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    // Initialize controllers
    Get.put(PosController());
    Get.put(MediaController());
    Get.put(ProductController());
    Get.put(CategoryController());
    Get.put(ProductVariationController());
    Get.put(CartController());
    Get.put(ShopController());

    return Scaffold(
      backgroundColor: dark ? TColors.black : TColors.lightGrey,
      body: _buildResponsiveLayout(context),
    );
  }

  /// Build the main responsive layout
  Widget _buildResponsiveLayout(BuildContext context) {
    // Check if screen meets minimum kiosk requirements
    if (!context.isValidKioskScreen) {
      return _buildWarningScreen(context);
    }

    return Column(
      children: [
        const KioskHeader(),
        // Category Selector at the top

        // Main content area with product grid and cart sidebar
        Expanded(
          child: Row(
            children: [
              // Product Grid Area (60-70% width)
              const Expanded(
                flex: 65,
                child: Column(
                  children: [
                    CategorySelector(),

                    //  CategoryHeader(),
                    Expanded(child: ProductGrid()),
                  ],
                ),
              ),

              // Cart Sidebar (30-35% width)
              Expanded(
                flex: 25,
                child: CartSidebar(
                  mediaController: Get.find<MediaController>(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build warning screen for unsupported resolutions
  Widget _buildWarningScreen(BuildContext context) {
    final warnings = context.layoutWarnings;

    return Container(
      padding: const EdgeInsets.all(TSizes.lg),
      color: TColors.warning.withValues(alpha: 0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: TColors.warning,
            ),
            const SizedBox(height: TSizes.lg),
            Text(
              'Screen Resolution Warning',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: TColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: TSizes.md),
            Text(
              kDebugMode
                  ? 'This POS kiosk is optimized for screens between 15" and 32"\nwith minimum resolution of 1366x768.\n\nDevelopment mode: Using relaxed requirements (1024x600 minimum).'
                  : 'This POS kiosk is optimized for screens between 15" and 32"\nwith minimum resolution of 1366x768.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: TColors.lightModePrimaryText,
                  ),
              textAlign: TextAlign.center,
            ),
            if (warnings.isNotEmpty) ...[
              const SizedBox(height: TSizes.lg),
              Container(
                padding: const EdgeInsets.all(TSizes.md),
                decoration: BoxDecoration(
                  color: TColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: TColors.warning),
                ),
                child: Column(
                  children: warnings
                      .map((warning) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 16,
                                  color: TColors.error,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    warning,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: TColors.error,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: TSizes.xl),
            ElevatedButton(
              onPressed: () => _proceedAnyway(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.primary,
                foregroundColor: TColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: TSizes.xl,
                  vertical: TSizes.md,
                ),
              ),
              child: const Text('Proceed Anyway'),
            ),
          ],
        ),
      ),
    );
  }

  /// Proceed with the layout despite warnings
  void _proceedAnyway(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const _PosKioskScreenForced(),
      ),
    );
  }
}

/// Forced POS screen that bypasses resolution checks
class _PosKioskScreenForced extends StatelessWidget {
  const _PosKioskScreenForced();

  @override
  Widget build(BuildContext context) {
    // Initialize controller if not already initialized
    if (!Get.isRegistered<PosController>()) {
      Get.put(PosController());
    }
    if (!Get.isRegistered<ProductController>()) {
      Get.put(ProductController());
    }
    if (!Get.isRegistered<CategoryController>()) {
      Get.put(CategoryController());
    }
    if (!Get.isRegistered<MediaController>()) {
      Get.put(MediaController());
    }
    if (!Get.isRegistered<ProductVariationController>()) {
      Get.put(ProductVariationController());
    }
    if (!Get.isRegistered<CartController>()) {
      Get.put(CartController());
    }
    if (!Get.isRegistered<ShopController>()) {
      Get.put(ShopController());
    }

    return Scaffold(
      backgroundColor: TColors.lightGrey,
      body: Column(
        children: [
          // Category Selector at the top
          const CategorySelector(),

          // Main content area with product grid and cart sidebar
          Expanded(
            child: Row(
              children: [
                // Product Grid Area (60-70% width)
                const Expanded(
                  flex: 65,
                  child: Column(
                    children: [
                      CategoryHeader(),
                      Expanded(child: ProductGrid()),
                    ],
                  ),
                ),

                // Cart Sidebar (30-35% width)
                Expanded(
                  flex: 35,
                  child: CartSidebar(
                    mediaController: Get.find<MediaController>(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// POS Kiosk Screen with debugging information
///
/// This variant includes debugging information for development purposes
class PosKioskScreenDebug extends StatelessWidget {
  const PosKioskScreenDebug({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controllers
    Get.put(PosController());
    Get.put(MediaController());
    Get.put(ProductController());
    Get.put(CategoryController());
    Get.put(ProductVariationController());
    Get.put(CartController());
    Get.put(ShopController());

    return Scaffold(
      backgroundColor: TColors.lightGrey,
      body: Stack(
        children: [
          // Main layout
          Column(
            children: [
              // Category Selector at the top
              const CategorySelector(),

              // Main content area with product grid and cart sidebar
              Expanded(
                child: Row(
                  children: [
                    // Product Grid Area (60-70% width)
                    const Expanded(
                      flex: 65,
                      child: Column(
                        children: [
                          CategoryHeader(),
                          Expanded(child: ProductGrid()),
                        ],
                      ),
                    ),

                    // Cart Sidebar (30-35% width)
                    Expanded(
                      flex: 35,
                      child: CartSidebar(
                        mediaController: Get.find<MediaController>(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Debug overlay
          Positioned(
            top: 16,
            right: 16,
            child: _buildDebugInfo(context),
          ),
        ],
      ),
    );
  }

  /// Build debug information overlay
  Widget _buildDebugInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: TColors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Debug Info',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: TColors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Screen: ${THelperFunctions.screenWidth().toInt()}x${THelperFunctions.screenHeight().toInt()}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: TColors.white,
                  fontSize: 10,
                ),
          ),
          Text(
            'Grid Columns: ${context.productGridCrossAxisCount}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: TColors.white,
                  fontSize: 10,
                ),
          ),
          Text(
            'Category Layout: ${context.shouldUseCategoryWrap ? "Wrap" : "Scroll"}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: TColors.white,
                  fontSize: 10,
                ),
          ),
          Text(
            'Touch Target: ${context.touchTargetSize.toInt()}px',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: TColors.white,
                  fontSize: 10,
                ),
          ),
          Text(
            'Valid Kiosk: ${context.isValidKioskScreen ? "Yes" : "No"}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.isValidKioskScreen
                      ? TColors.success
                      : TColors.error,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }
}

/// POS Kiosk Screen Binding for GetX
class PosKioskBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PosController>(() => PosController());
    Get.lazyPut<CategoryController>(() => CategoryController());
    Get.lazyPut<ProductController>(() => ProductController());
    Get.lazyPut<MediaController>(() => MediaController());
    Get.lazyPut<ProductVariationController>(() => ProductVariationController());
    Get.lazyPut<CartController>(() => CartController());
    Get.lazyPut<ShopController>(() => ShopController());
  }
}
