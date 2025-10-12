import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../utils/effects/shimmer effect.dart';
import '../../../../common/navigation/navigation_helper.dart';
import '../../../../common/widgets/chips/choice_chip.dart';
import '../../../../common/widgets/icons/t_circular_icon.dart';
import '../../../../common/widgets/images/t_rounded_image.dart';
import '../../../../common/widgets/loaders/tloaders.dart';
import '../../../../common/widgets/texts/currency_text.dart';
import '../../../../common/widgets/texts/heading_text.dart';
import '../../../../common/widgets/texts/product_title_text.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../cart/controller/cart_controller.dart';
import '../../../shop/controller/shop_controller.dart';
import '../../controller/product_varaintion_controller.dart';
import '../../controller/product_controller.dart';
import '../../models/product_model.dart';
import '../../models/product_variation_model.dart';

class QuickAddToCartDialog extends StatefulWidget {
  final ProductModel product;
  final String imageUrl;
  final bool isNetworkImage;

  const QuickAddToCartDialog({
    super.key,
    required this.product,
    required this.imageUrl,
    this.isNetworkImage = false,
  });

  @override
  State<QuickAddToCartDialog> createState() => _QuickAddToCartDialogState();
}

class _QuickAddToCartDialogState extends State<QuickAddToCartDialog> {
  late ProductVariationController variationController;
  late ProductController productController;
  late CartController cartController;
  int quantity = 1;
  final isAddingToCart = false.obs;
  bool hasShownQuantityLimitWarning = false;
  bool hasShownStockLimitWarning = false;
  Timer? _incrementTimer;
  Timer? _decrementTimer;
  int maxQuantityPerItem = 50; // Default value, will be updated from DB
  @override
  void initState() {
    super.initState();
    variationController = Get.find<ProductVariationController>();
    productController = Get.find<ProductController>();
    cartController = Get.put(CartController());

    // Reset variation controller for this product
    variationController.selectedVariant.value = '';
    variationController.selectedVariationProduct.value =
        ProductVariationModel.empty();
    variationController.itemQuantity.value = 1;

    // Load max quantity from DB
    _loadMaxQuantityFromDB();

    // Fetch variations for this product using ProductController
    WidgetsBinding.instance.addPostFrameCallback((_) {
      productController
          .fetchProductVariations(widget.product.productId)
          .then((variations) {
        // Update the variation controller with the fetched variations
        variationController.allProductVariations.assignAll(variations);
        variationController.allProductVariations.refresh();

        // Auto-select first available variant after loading
        final availableVariants = variationController.getAvailableVariants();
        if (availableVariants.isNotEmpty &&
            variationController.selectedVariant.value.isEmpty) {
          variationController.selectVariant(availableVariants.first);
          setState(() {}); // Trigger rebuild to update UI
        }
      }).catchError((e) {
        if (kDebugMode) {
          print(
              'Error fetching variations for product ${widget.product.productId}: $e');
        }
      });
    });
  }

  Future<void> _loadMaxQuantityFromDB() async {
    try {
      final shopController = Get.find<ShopController>();
      final maxQuantity = await shopController.maxAllowedQuantity();
      setState(() {
        maxQuantityPerItem = maxQuantity;
      });
    } catch (e) {
      // Keep default value of 50 if there's an error
      if (kDebugMode) {
        print('Error loading max quantity: $e');
      }
    }
  }

  void _incrementQuantity() {
    final maxStock = _getAvailableStock();

    if (quantity >= maxQuantityPerItem) {
      if (!hasShownQuantityLimitWarning) {
        TLoader.warningSnackBar(
          title: 'Quantity Limit',
          message: 'Maximum $maxQuantityPerItem items allowed per product',
        );
        hasShownQuantityLimitWarning = true;
      }
      return;
    }

    if (maxStock > 0 && quantity < maxStock) {
      // Reset warnings only when quantity actually increases
      hasShownQuantityLimitWarning = false;
      hasShownStockLimitWarning = false;
      setState(() {
        quantity++;
      });
    } else if (maxStock <= 0) {
      if (!hasShownStockLimitWarning) {
        TLoader.warningSnackBar(
          title: 'Out of Stock',
          message: 'This variant is currently out of stock',
        );
        hasShownStockLimitWarning = true;
      }
    } else {
      if (!hasShownStockLimitWarning) {
        TLoader.warningSnackBar(
          title: 'Stock Limit',
          message: 'Not enough items available in stock',
        );
        hasShownStockLimitWarning = true;
      }
    }
  }

  void _handleIncrementTap() {
    final maxStock = _getAvailableStock();
    final isMaxQuantityReached = quantity >= maxQuantityPerItem;
    final isMaxStockReached = quantity >= maxStock;

    if (isMaxQuantityReached) {
      if (!hasShownQuantityLimitWarning) {
        TLoader.warningSnackBar(
          title: 'Quantity Limit',
          message: 'Maximum $maxQuantityPerItem items allowed per product',
        );
        hasShownQuantityLimitWarning = true;
      }
      return;
    }

    if (maxStock <= 0) {
      if (!hasShownStockLimitWarning) {
        TLoader.warningSnackBar(
          title: 'Out of Stock',
          message: 'This variant is currently out of stock',
        );
        hasShownStockLimitWarning = true;
      }
      return;
    }

    if (isMaxStockReached) {
      if (!hasShownStockLimitWarning) {
        TLoader.warningSnackBar(
          title: 'Stock Limit',
          message: 'Not enough items available in stock',
        );
        hasShownStockLimitWarning = true;
      }
      return;
    }

    // If all checks pass, increment quantity
    _incrementQuantity();
  }

  void _decrementQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
      // Reset warnings when quantity decreases (allows user to try again)
      hasShownQuantityLimitWarning = false;
      hasShownStockLimitWarning = false;
    }
  }

  void _handleDecrementTap() {
    if (quantity > 1) {
      _decrementQuantity();
    }
  }

  void _startIncrementTimer() {
    _stopIncrementTimer(); // Stop any existing timer
    _incrementTimer =
        Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (mounted) {
        _incrementQuantity();
      } else {
        timer.cancel();
      }
    });
  }

  void _stopIncrementTimer() {
    _incrementTimer?.cancel();
    _incrementTimer = null;
  }

  void _startDecrementTimer() {
    _stopDecrementTimer(); // Stop any existing timer
    _decrementTimer =
        Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (mounted) {
        _decrementQuantity();
      } else {
        timer.cancel();
      }
    });
  }

  void _stopDecrementTimer() {
    _decrementTimer?.cancel();
    _decrementTimer = null;
  }

  @override
  void dispose() {
    _incrementTimer?.cancel();
    _decrementTimer?.cancel();
    super.dispose();
  }

  double _getCurrentPrice() {
    if (variationController.selectedVariationProduct.value.variantId != 0) {
      return double.tryParse(
              variationController.selectedVariationProduct.value.sellPrice) ??
          0.0;
    }
    return 0.0;
  }

  int _getAvailableStock() {
    // Only use variant stock, not product stock
    if (variationController.selectedVariationProduct.value.variantId != 0) {
      return int.tryParse(variationController
              .selectedVariationProduct.value.stockQuantity) ??
          0;
    }
    // If no variant selected, check if any variants are available
    final availableVariants = variationController.getAvailableVariants();
    if (availableVariants.isNotEmpty) {
      // Return stock of first available variant
      final firstVariant = variationController.allProductVariations
          .where((v) => availableVariants.contains(v.variantName))
          .first;
      return int.tryParse(firstVariant.stockQuantity) ?? 0;
    }
    return 0; // No variants available
  }

  Future<void> _addToCart() async {
    try {
      isAddingToCart.value = true;
      // Check if variants are available and none selected
      if (variationController.getVisibleVariants().isNotEmpty &&
          variationController.selectedVariant.value.isEmpty) {
        TLoader.warningSnackBar(
          title: "Select Variant",
          message: "Please select a variant before adding to cart.",
        );
        return;
      }

      // Validate quantity
      if (quantity <= 0) {
        TLoader.warningSnackBar(
          title: "Quantity Required",
          message: "Please select a quantity greater than 0",
        );
        return;
      }

      // Check stock availability
      final availableStock = _getAvailableStock();
      if (availableStock <= 0) {
        TLoader.warningSnackBar(
          title: "Out of Stock",
          message: "This variant is currently out of stock.",
        );
        return;
      }

      if (availableStock < quantity) {
        TLoader.warningSnackBar(
          title: "Insufficient Stock",
          message: "Only $availableStock items available.",
        );
        return;
      }

      // Get variant ID for cart
      int variantId = 0;
      if (variationController.hasValidSelectedVariant()) {
        variantId =
            variationController.selectedVariationProduct.value.variantId;
      } else {
        // If no valid variant selected but variants exist, auto-select first available
        final availableVariants = variationController.getAvailableVariants();
        if (availableVariants.isNotEmpty) {
          final firstAvailableVariant = variationController.allProductVariations
              .firstWhere((v) => v.variantName == availableVariants.first);
          variantId = firstAvailableVariant.variantId;
        }
      }

      if (variantId == 0) {
        TLoader.warningSnackBar(
          title: "No Variant Available",
          message: "This product has no available variants.",
        );
        return;
      }

      final success =
          await cartController.addToCart(variantId, quantity: quantity);
      if (!success) return;

      NavigationHelper.goBackFromController();

      _showAddToCartSuccess();
    } catch (e) {
      TLoader.errorSnackBar(
        title: "Error",
        message: "Failed to add item to cart: ${e.toString()}",
      );
    } finally {
      isAddingToCart.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    //final dark = THelperFunctions.isDarkMode(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
      ),
      child: Container(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const TSectionHeading(
                  title: "Quick Add",
                  showActionButton: false,
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Iconsax.close_circle),
                ),
              ],
            ),

            const SizedBox(height: TSizes.spaceBtwItems),

            // Product Image and Basic Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                TRoundedImage(
                  imageurl: widget.isNetworkImage && widget.imageUrl.isNotEmpty
                      ? widget.imageUrl
                      : TImages.productImage78,
                  width: 80,
                  height: 80,
                  applyImageRadius: true,
                  isNetworkImage: widget.isNetworkImage,
                  fit: BoxFit.cover,
                ),

                const SizedBox(width: TSizes.spaceBtwItems),

                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TProductTitleText(
                        title: widget.product.name,
                        smallSize: false,
                      ),
                      const SizedBox(height: TSizes.spaceBtwItems / 2),
                      Obx(() => TProductPriceText(
                            price: _getCurrentPrice().toString(),
                            isLarge: true,
                          )),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Variant Selection
            Obx(() {
              if (variationController.getVisibleVariants().isEmpty) {
                return const SizedBox.shrink();
              }

              if (variationController.isLoading.value) {
                return const Center(
                    child: TShimmerEffect(width: double.infinity, height: 120));
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TSectionHeading(
                    title: 'Select Variant',
                    showActionButton: false,
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  Container(
                    constraints: const BoxConstraints(
                      maxHeight: 120, // Limit height to prevent overflow
                    ),
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // Available Variants
                            ...variationController.getAvailableVariants().map(
                                  (variantName) => TChoiceChip(
                                    showCheckmark: false,
                                    text: variantName,
                                    selected: variationController
                                        .isVariantSelected(variantName),
                                    onSelected: (value) {
                                      variationController
                                          .selectVariant(variantName);
                                      setState(
                                          () {}); // Trigger rebuild for price update
                                    },
                                    isOutOfStock: false,
                                  ),
                                ),
                            // Out of Stock Variants
                            ...variationController.getOutOfStockVariants().map(
                                  (variantName) => TChoiceChip(
                                    text: variantName,
                                    selected: false,
                                    onSelected: null,
                                    isOutOfStock: true,
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections),
                ],
              );
            }),

            // Quantity Selection
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quantity',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    // Decrease quantity button
                    GestureDetector(
                      onTapDown: (_) => _startDecrementTimer(),
                      onTapUp: (_) => _stopDecrementTimer(),
                      onTapCancel: () => _stopDecrementTimer(),
                      child: TCircularIcon(
                        onPressed: quantity <= 1 ? null : _handleDecrementTap,
                        icon: Iconsax.minus,
                        backgroundColor:
                            quantity <= 1 ? TColors.darkGrey : TColors.primary,
                        width: 40,
                        height: 40,
                        color: TColors.white,
                      ),
                    ),

                    const SizedBox(width: TSizes.spaceBtwItems),

                    // Quantity display
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: TColors.grey),
                      ),
                      child: Text(
                        quantity.toString(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),

                    const SizedBox(width: TSizes.spaceBtwItems),

                    // Increase quantity button
                    Obx(() {
                      final maxStock = _getAvailableStock();
                      final isMaxQuantityReached =
                          quantity >= maxQuantityPerItem;
                      final isMaxStockReached = quantity >= maxStock;
                      final isDisabled =
                          isMaxQuantityReached || isMaxStockReached;

                      return GestureDetector(
                        onTapDown: (_) => _startIncrementTimer(),
                        onTapUp: (_) => _stopIncrementTimer(),
                        onTapCancel: () => _stopIncrementTimer(),
                        child: TCircularIcon(
                          onPressed: _handleIncrementTap,
                          icon: Iconsax.add,
                          backgroundColor:
                              isDisabled ? TColors.darkGrey : TColors.primary,
                          width: 40,
                          height: 40,
                          color: TColors.white,
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),

            const SizedBox(height: TSizes.spaceBtwItems),

            // Stock Info
            Obx(() {
              final stock = _getAvailableStock();
              final hasVariants =
                  variationController.getVisibleVariants().isNotEmpty;
              final hasSelectedVariant =
                  variationController.selectedVariant.value.isNotEmpty;

              String stockText;
              Color stockColor;

              if (hasVariants && !hasSelectedVariant) {
                stockText = 'Select a variant to see stock';
                stockColor = TColors.darkGrey;
              } else if (stock > 0) {
                stockText = 'In Stock';
                stockColor = TColors.success;
              } else {
                stockText = 'Out of Stock';
                stockColor = TColors.error;
              }

              return Text(
                stockText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: stockColor,
                      fontWeight: FontWeight.w500,
                    ),
              );
            }),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Total Price and Add to Cart Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Obx(() => TProductPriceText(
                          price: (_getCurrentPrice() * quantity).toString(),
                          isLarge: true,
                        )),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: TSizes.spaceBtwItems),
                  child: Obx(() {
                    final stock = _getAvailableStock();
                    final hasVariants =
                        variationController.getVisibleVariants().isNotEmpty;
                    final hasSelectedVariant =
                        variationController.selectedVariant.value.isNotEmpty;
                    final isEnabled =
                        stock > 0 && (!hasVariants || hasSelectedVariant);

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        TCircularIcon(
                          onPressed: isEnabled && !isAddingToCart.value
                              ? _addToCart
                              : null,
                          icon: Iconsax.shopping_cart,
                          backgroundColor: isAddingToCart.value
                              ? TColors.grey
                              : (isEnabled ? TColors.primary : TColors.grey),
                          width: 50,
                          height: 50,
                          color: TColors.white,
                        ),
                        if (isAddingToCart.value)
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  TColors.primary),
                              backgroundColor: TColors.grey.withOpacity(0.3),
                            ),
                          ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToCartSuccess() {
    Get.snackbar(
      'Success',
      'Item added to cart successfully!',
      backgroundColor: TColors.primary,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      mainButton: TextButton(
        onPressed: () {
          NavigationHelper.goBack(Get.overlayContext!); // Close snackbar
          // Get.toNamed(TRoutes.cart);
        },
        child: const Text(
          'View Cart',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      icon: const Icon(
        Iconsax.tick_circle,
        color: Colors.white,
      ),
    );
  }
}
