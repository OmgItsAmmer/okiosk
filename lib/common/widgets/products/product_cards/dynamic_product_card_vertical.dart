import 'package:okiosk/common/widgets/images/t_rounded_image.dart';
import 'package:okiosk/common/widgets/texts/currency_text.dart';
import 'package:okiosk/common/widgets/texts/product_title_text.dart';
import 'package:okiosk/utils/constants/colors.dart';
import 'package:okiosk/utils/constants/image_strings.dart';
import 'package:okiosk/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../features/products/models/product_model.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../custom_shapes/containers/rounded_container.dart';

/// Enhanced TProductCardVertical that accepts dynamic image URL
class ProductCardWithDynamicImage extends StatelessWidget {
  final ProductModel product;
  final String imageUrl;
  final bool isNetworkImage;
  final VoidCallback? wishListOnPressed;

  const ProductCardWithDynamicImage({
    super.key,
    required this.product,
    required this.imageUrl,
    this.isNetworkImage = false,
    this.wishListOnPressed,
  });

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return GestureDetector(
      //onTap: () => Get.toNamed(TRoutes.productDetails, arguments: product),
      child: TRoundedContainer(
        width: 180,
        padding: const EdgeInsets.all(1),
        backgroundColor: dark ? TColors.darkerGrey : TColors.white,
        child: Column(
          children: [
            // Thumbnail
            TRoundedContainer(
              height: 180,
              //  padding: const EdgeInsets.all(TSizes.sm),
              backgroundColor: dark ? TColors.dark : TColors.light,
              child: TRoundedImage(
                height: 180,
                width: double.infinity,
                imageurl: isNetworkImage && imageUrl.isNotEmpty
                    ? imageUrl
                    : TImages.lightAppLogo, // Fallback to default image
                applyImageRadius: true,
                isNetworkImage: isNetworkImage,
                fit: BoxFit.cover,
              ),
            ),

            SizedBox(height: TSizes.spaceBtwItems / 2),

            // Product Details
            Padding(
              padding: const EdgeInsets.only(left: TSizes.sm),
              child: TProductTitleText(
                title: product.name,
                smallSize: true,
              ),
            ),

            const Spacer(),

            // Pricing and Add-to-Cart
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: TSizes.sm),
                    child: TProductPriceText(
                      isSign: true,
                      price: product.priceRange ?? '',
                    ),
                  ),
                ),
                // Add to Cart
                GestureDetector(
                  onTap: () {
                    // Show Quick Add to Cart Dialog
                    // showDialog(
                    //   context: context,
                    //   builder: (context) => QuickAddToCartDialog(
                    //     product: product,
                    //     imageUrl: imageUrl,
                    //     isNetworkImage: isNetworkImage,
                    //   ),
                    // );
                  },
                  child: Container(
                    decoration:  BoxDecoration(
                      color: dark ? TColors.black : TColors.primary,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(TSizes.cardRadiusMd),
                        bottomRight: Radius.circular(TSizes.productImageRadius),
                      ),
                    ),
                    child: SizedBox(
                      width: TSizes.iconLg * 1.7,
                      height: TSizes.iconLg * 1.7,
                      child: Center(
                        child: Icon(
                          Iconsax.info_circle5,
                          color: (dark) ? TColors.white : TColors.white,
                          size: 38,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
