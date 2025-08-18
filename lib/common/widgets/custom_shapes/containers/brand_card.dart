// import 'package:okiosk/common/widgets/custom_shapes/containers/rounded_container.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:iconsax/iconsax.dart';

// import '../../../../utils/constants/colors.dart';
// import '../../../../utils/constants/enums.dart';
// import '../../../../utils/constants/sizes.dart';
// import '../../../../utils/helpers/helper_functions.dart';
// import '../../images/t_circular_image.dart';
// import '../../texts/brand_title_with_verification.dart';


// class TBrandCard extends StatelessWidget {
//   const TBrandCard({
//     super.key,
//     required this.showBorder,
//     this.onTap,
//     required this.brand,
//   });
//   final BrandModel brand;
//   final bool showBorder;

//   final void Function()? onTap;

//   @override
//   Widget build(BuildContext context) {
//     final dark = THelperFunctions.isDarkMode(context);
//     final mediaController = Get.put(MediaController());

//     // Preload brand image if not already loaded
//     mediaController
//         .preloadImages([brand.brandID!], MediaCategory.brands.toString());

//     return GestureDetector(
//       onTap: onTap,
//       child: TRoundedContainer(
//         padding: EdgeInsets.all(TSizes.sm),
//         shadowBorder: showBorder,
//         backgroundColor: Colors.transparent,
//         child: Row(
//           children: [
//             // Image/Icon
//             // Flexible(
//             //   child: TCircularImage(
//             //     isNetworkImage: isNetworkImage,
//             //     image: imagePath,
//             //     backgroundColor: Colors.transparent,
//             //     overlayColor: THelperFunctions.isDarkMode(context)
//             //         ? TColors.white
//             //         : TColors.black,
//             //   ),
//             // ),
//             const SizedBox(
//               width: TSizes.spaceBtwItems / 2,
//             ),
//             // Text
//             Flexible(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   TBrandTitleWithVerification(
//                     showVerified: brand.isVerified ?? false,
//                     brandId: brand.brandID,
//                     brandTextSize: TextSizes.large,
//                   ),
//                   // if(brand.isVerified == true)
//                   // Row(
//                   //   children: [
//                   //     Icon(Iconsax.verify5, color: dark ? TColors.white : TColors.black,),
//                   //     const SizedBox(width: TSizes.spaceBtwItems / 2,),
//                   //     Text(
//                   //       "Verified",
//                   //       overflow: TextOverflow.ellipsis,
//                   //       style: Theme.of(context).textTheme.labelMedium?.copyWith(
//                   //         color: dark ? TColors.white : TColors.black,
//                   //       ),
//                   //     ),
//                   //   ],
//                   // ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
