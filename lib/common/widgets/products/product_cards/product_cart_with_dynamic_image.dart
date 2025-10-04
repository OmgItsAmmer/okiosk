import 'package:okiosk/common/widgets/images/t_rounded_image.dart';
import 'package:okiosk/utils/constants/colors.dart';
import 'package:okiosk/utils/constants/enums.dart';
import 'package:okiosk/utils/constants/image_strings.dart';
import 'package:okiosk/utils/constants/sizes.dart';
import 'package:flutter/material.dart';

import '../../../../features/media/controller/media_controller.dart';
import '../../../../features/products/models/product_model.dart';
import '../../custom_shapes/containers/rounded_container.dart';

/// Custom product card that fetches and displays product images - Kiosk Optimized
class ProductCardWithImage extends StatelessWidget {
  final ProductModel product; // Your product model
  final MediaController mediaController;
  final VoidCallback? wishListOnPressed;

  const ProductCardWithImage({
    super.key,
    required this.product,
    required this.mediaController,
    this.wishListOnPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: mediaController.fetchMainImage(
          product.productId, MediaCategory.products.name),
      builder: (context, snapshot) {
        // Get the image URL from the snapshot or use fallback
        final String imageUrl = snapshot.data ?? '';
        final bool hasImage = snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.isNotEmpty;

        // Build the card with dynamic image
        return TRoundedContainer(
          padding: const EdgeInsets.all(8),
          backgroundColor: TColors.primaryBackground,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image - Takes 60% of card height
              Expanded(
                flex: 6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                  child: TRoundedImage(
                    width: double.infinity,
                    imageurl: hasImage && imageUrl.isNotEmpty
                        ? imageUrl
                        : TImages.lightAppLogo, // Fallback to default image
                    applyImageRadius: false,
                    isNetworkImage: hasImage,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: TSizes.spaceBtwItems),

              // Product Name - Bold and larger for kiosk
              Text(
                product.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: TColors.lightModePrimaryText,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      height: 1.2,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: TSizes.spaceBtwItems / 2),

              // Product Description - Fixed size container spanning full width and height
              Expanded(
                flex: 2,
                child: TRoundedContainer(
                  padding: const EdgeInsets.all(8),
                  backgroundColor: TColors.lightContainer.withOpacity(0.7),
                  radius: TSizes.cardRadiusSm,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      product.description ?? 'Mango',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: TColors.lightModePrimaryText,
                            fontSize: 12,
                            height: 1.3,
                            fontWeight: FontWeight.w500,
                          ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Price Range - Custom container extending beyond card bottom
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Transform.translate(
                    offset:
                        const Offset(0, 8), // Move down to extend beyond card
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: TColors.primary,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(TSizes.cardRadiusSm),
                          topRight: Radius.circular(TSizes.cardRadiusSm),
                          bottomLeft: Radius.zero,
                          bottomRight: Radius.zero,
                        ),
                      ),
                      child: Text(
                        'Rs ${product.priceRange}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: TColors.cream,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
