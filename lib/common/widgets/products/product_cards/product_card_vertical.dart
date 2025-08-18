// import 'package:okiosk/common/styles/shadows.dart';
// import 'package:okiosk/common/widgets/images/t_rounded_image.dart';
// import 'package:okiosk/common/widgets/texts/brand_title_with_verification.dart';
// import 'package:okiosk/features/shop/models/product_model.dart';
// import 'package:okiosk/features/shop/screens/product_details/product_Detail.dart';
// import 'package:okiosk/routes/routes.dart';
// import 'package:okiosk/utils/constants/colors.dart';
// import 'package:okiosk/utils/constants/image_strings.dart';
// import 'package:okiosk/utils/constants/sizes.dart';
// import 'package:okiosk/utils/helpers/helper_functions.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:iconsax/iconsax.dart';

// import '../../custom_shapes/containers/rounded_container.dart';
// import '../../icons/t_circular_icon.dart';
// import '../../texts/currency_text.dart';
// import '../../texts/product_title_text.dart';
// import '../../../../features/shop/controllers/wishlist_controller.dart';

// class TProductCardVertical extends StatelessWidget {
//   final ProductModel product;
//   final bool isNetworkImage;
//   final VoidCallback? wishListOnPressed;

//   TProductCardVertical({
//     super.key,
//     required this.product,
//     this.isNetworkImage = false,
//     this.wishListOnPressed,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final dark = THelperFunctions.isDarkMode(context);
//     final WishlistController wishlistController =
//         Get.find<WishlistController>();

//     return Obx(
//       () => GestureDetector(
//         onTap: () =>
//             Get.toNamed(TRoutes.productDetails, arguments: product.productId),
//         child: Container(
//           width: 180,
//           padding: const EdgeInsets.all(1),
//           decoration: BoxDecoration(
//             boxShadow: [TshadowStyle.verticalProductShadow],
//             borderRadius: BorderRadius.circular(TSizes.productImageRadius),
//             color: dark ? TColors.darkerGrey : TColors.white,
//           ),
//           child: Column(
//             children: [
//               // Thumbnail and Wishlist
//               TRoundedContainer(
//                 height: 180,
//                 padding: const EdgeInsets.all(TSizes.sm),
//                 backgroundColor: dark ? TColors.dark : TColors.light,
//                 child: Stack(
//                   children: [
//                     // Product Image
//                     TRoundedImage(
//                       imageurl: TImages.productImage78,
//                       applyImageRadius: true,
//                       isNetworkImage: isNetworkImage,
//                       fit: BoxFit.fill,
//                     ),

//                     // Sale Tag (if discount is applicable)
//                     // if (product.discount != null && product.discount! > 0)
//                     //   Positioned(
//                     //     top: 12,
//                     //     child: TRoundedContainer(
//                     //       radius: TSizes.sm,
//                     //       backgroundColor: TColors.secondary.withValues(alpha: 0.8),
//                     //       padding: const EdgeInsets.symmetric(
//                     //           horizontal: TSizes.sm, vertical: TSizes.xs),
//                     //       child: Text(
//                     //         "${product.discount!.toInt()}% OFF",
//                     //         style: Theme.of(context)
//                     //             .textTheme
//                     //             .labelLarge!
//                     //             .apply(color: TColors.black),
//                     //       ),
//                     //     ),
//                     //   ),

//                     // Favorite Icon Button
//                     Positioned(
//                       top: 0,
//                       right: 0,
//                       child: GestureDetector(
//                         onTap: () {
//                           if (wishListOnPressed != null) {
//                             wishListOnPressed!(); // Call the additional callback if provided
//                           }
//                         },
//                         child: TCircularIcon(
//                           icon: wishlistController
//                                   .isProductInWishListById(product.productId)
//                               ? Iconsax.heart5
//                               : Iconsax.heart5,
//                           color: wishlistController
//                                   .isProductInWishListById(product.productId)
//                               ? Colors.red
//                               : Colors.grey,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               SizedBox(height: TSizes.spaceBtwItems / 2),

//               // Product Details
//               Padding(
//                 padding: const EdgeInsets.only(left: TSizes.sm),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     TProductTitleText(
//                       title: product.name,
//                       smallSize: true,
//                     ),
//                     const SizedBox(height: TSizes.spaceBtwItems / 2),
//                     TBrandTitleWithVerification(
//                       brandId: product.brandID ?? 0,
//                     ),
//                   ],
//                 ),
//               ),

//               const Spacer(),

//               // Pricing and Add-to-Cart
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.only(left: TSizes.sm),
//                     child: TProductPriceText(
//                       price: product.priceRange,
//                     ),
//                   ),
//                   // Add to Cart
//                   Container(
//                     decoration: const BoxDecoration(
//                       color: TColors.dark,
//                       borderRadius: BorderRadius.only(
//                         topLeft: Radius.circular(TSizes.cardRadiusMd),
//                         bottomRight: Radius.circular(TSizes.productImageRadius),
//                       ),
//                     ),
//                     child: SizedBox(
//                       width: TSizes.iconLg * 1.2,
//                       height: TSizes.iconLg * 1.2,
//                       child: const Center(
//                         child: Icon(
//                           Iconsax.add,
//                           color: TColors.white,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
