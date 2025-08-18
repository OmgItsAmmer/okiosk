// import 'package:okiosk/features/shop/screens/cart/cart.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:iconsax/iconsax.dart';

// import '../../../../features/shop/controllers/cart_controller.dart';
// import '../../../../utils/constants/colors.dart';
// import '../../../../utils/effects/shimmer effect.dart';

// /// Cart Counter Icon - Displays cart item count with navigation to cart screen
// ///
// /// This widget follows the Observer pattern with reactive state management.
// /// It uses the refactored CartController to display accurate cart item counts
// /// and provides smooth loading states during data fetching.
// class TCartCounterIcon extends StatelessWidget {
//   const TCartCounterIcon({
//     super.key,
//     this.iconColor,
//     this.counterColor,
//     this.size = 24.0,
//   });

//   final Color? iconColor;
//   final Color? counterColor;
//   final double size;

//   @override
//   Widget build(BuildContext context) {
//     return GetBuilder<CartController>(
//       init: CartController(),
//       builder: (cartController) {
//         return Obx(() {
//           // Show shimmer effect while loading
//           if (cartController.isLoading.value) {
//             return _buildLoadingState();
//           }

//           return _buildCartIcon(cartController);
//         });
//       },
//     );
//   }

//   /// Builds the main cart icon with item count
//   ///
//   /// Uses the new CartController architecture for accurate count display
//   Widget _buildCartIcon(CartController cartController) {
//     return Stack(
//       clipBehavior: Clip.none,
//       children: [
//         IconButton(
//           onPressed: () => _navigateToCart(cartController),
//           icon: Icon(
//             Iconsax.shopping_bag,
//             color: iconColor ?? TColors.primary,
//             size: size,
//           ),
//           tooltip: 'View Cart',
//         ),

//         // Cart item count badge
//         if (cartController.totalCartItems > 0)
//           Positioned(
//             right: 6,
//             top: 6,
//             child: _buildCountBadge(cartController.totalCartItems),
//           ),
//       ],
//     );
//   }

//   /// Builds the count badge showing number of items
//   ///
//   /// Implements proper styling and handles different count ranges
//   Widget _buildCountBadge(int itemCount) {
//     // Determine display text based on count
//     String displayText;
//     if (itemCount > 99) {
//       displayText = '99+';
//     } else {
//       displayText = itemCount.toString();
//     }

//     return Container(
//       constraints: const BoxConstraints(minWidth: 18),
//       height: 18,
//       padding: const EdgeInsets.symmetric(horizontal: 6),
//       decoration: BoxDecoration(
//         color: counterColor ?? TColors.primary,
//         borderRadius: BorderRadius.circular(9),
//         border: Border.all(
//           color: Colors.white,
//           width: 1,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.2),
//             spreadRadius: 1,
//             blurRadius: 2,
//             offset: const Offset(0, 1),
//           ),
//         ],
//       ),
//       child: Center(
//         child: Text(
//           displayText,
//           style: const TextStyle(
//             color: Colors.white,
//             fontSize: 11,
//             fontWeight: FontWeight.bold,
//             height: 1.0,
//           ),
//           textAlign: TextAlign.center,
//         ),
//       ),
//     );
//   }

//   /// Builds loading state with shimmer effect
//   Widget _buildLoadingState() {
//     return Stack(
//       clipBehavior: Clip.none,
//       children: [
//         IconButton(
//           onPressed: null, // Disabled during loading
//           icon: Icon(
//             Iconsax.shopping_bag,
//             color: (iconColor ?? TColors.primary).withValues(alpha: 0.5),
//             size: size,
//           ),
//         ),
//         Positioned(
//           right: 6,
//           top: 6,
//           child: TShimmerEffect(
//             width: 18,
//             height: 18,
//             radius: 9,
//           ),
//         ),
//       ],
//     );
//   }

//   /// Navigates to cart screen with proper initialization
//   ///
//   /// Ensures cart data is fetched when navigating to cart screen
//   void _navigateToCart(CartController cartController) {
//     // Pre-fetch cart data for better user experience
//     if (cartController.cartItems.isEmpty && !cartController.isLoading.value) {
//       cartController.fetchCart();
//     }

//     Get.to(() => const CartScreen());
//   }
// }

// /// Alternative compact cart icon for use in smaller spaces
// ///
// /// This variant provides a more compact representation suitable for
// /// navigation bars or toolbar implementations
// class TCompactCartIcon extends StatelessWidget {
//   const TCompactCartIcon({
//     super.key,
//     this.iconColor,
//     this.size = 20.0,
//   });

//   final Color? iconColor;
//   final double size;

//   @override
//   Widget build(BuildContext context) {
//     return GetBuilder<CartController>(
//       init: CartController(),
//       builder: (cartController) {
//         return Obx(() {
//           return GestureDetector(
//             onTap: () => Get.to(() => const CartScreen()),
//             child: Container(
//               padding: const EdgeInsets.all(8),
//               child: Stack(
//                 clipBehavior: Clip.none,
//                 children: [
//                   Icon(
//                     Iconsax.shopping_bag,
//                     color: iconColor ?? TColors.primary,
//                     size: size,
//                   ),
//                   if (cartController.totalCartItems > 0)
//                     Positioned(
//                       right: -6,
//                       top: -6,
//                       child: Container(
//                         width: 16,
//                         height: 16,
//                         decoration: BoxDecoration(
//                           color: TColors.primary,
//                           borderRadius: BorderRadius.circular(8),
//                           border: Border.all(color: Colors.white, width: 1),
//                         ),
//                         child: Center(
//                           child: Text(
//                             cartController.totalCartItems > 9
//                                 ? '9+'
//                                 : cartController.totalCartItems.toString(),
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 10,
//                               fontWeight: FontWeight.bold,
//                             ),
//                             textAlign: TextAlign.center,
//                           ),
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           );
//         });
//       },
//     );
//   }
// }
