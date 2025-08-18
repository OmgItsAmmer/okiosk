
// import 'package:okiosk/utils/helpers/helper_functions.dart';
// import 'package:flutter/material.dart';

// import 'package:okiosk/common/widgets/icons/t_circular_icon.dart';
// import 'package:okiosk/utils/constants/colors.dart';
// import 'package:okiosk/utils/constants/sizes.dart';
// import 'package:get/get.dart';
// import 'package:iconsax/iconsax.dart';

// /// Product Quantity Control Widget with Add/Remove buttons
// ///
// /// Updated to work with the new CartController and immutable CartItemModel.
// /// Provides reactive quantity controls with proper state management.
// class TProductQuantityWithAddRemove extends StatelessWidget {
//   const TProductQuantityWithAddRemove({
//     super.key,
//     required this.cartItem,
//     required this.variationStock,
//     required this.eachItemPrice,
//   });

//   final CartItemModel cartItem;
//   final String variationStock;
//   final String eachItemPrice;

//   @override
//   Widget build(BuildContext context) {
//     final bool dark = THelperFunctions.isDarkMode(context);
//     final cartController = Get.find<CartController>();

//     return Obx(
//       () {
//         // Find the current cart item (in case it was updated)
//         final currentCartItem = cartController.cartItems.firstWhere(
//           (item) => item.cart.cartId == cartItem.cart.cartId,
//           orElse: () => cartItem,
//         );

//         return Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             // Quantity Controls
//             Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // Decrease quantity button
//                 TCircularIcon(
//                   icon: Iconsax.minus,
//                   width: 40,
//                   height: 40,
//                   size: TSizes.md,
//                   color: dark ? TColors.white : TColors.black,
//                   backgroundColor: dark ? TColors.darkerGrey : TColors.light,
//                   onPressed: () => _decreaseQuantity(
//                     context,
//                     currentCartItem,
//                     cartController,
//                   ),
//                 ),
//                 const SizedBox(width: TSizes.spaceBtwItems),

//                 // Current quantity display
//                 Text(
//                   currentCartItem.cart.quantityAsInt.toString(),
//                   style: Theme.of(context).textTheme.titleSmall,
//                 ),
//                 const SizedBox(width: TSizes.spaceBtwItems),

//                 // Increase quantity button
//                 TCircularIcon(
//                   icon: Iconsax.add,
//                   width: 40,
//                   height: 40,
//                   size: TSizes.md,
//                   color: TColors.white,
//                   backgroundColor: TColors.primary,
//                   onPressed: () => _increaseQuantity(
//                     currentCartItem,
//                     cartController,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         );
//       },
//     );
//   }

//   /// Decreases the quantity of the cart item
//   void _decreaseQuantity(
//     BuildContext context,
//     CartItemModel cartItem,
//     CartController cartController,
//   ) {
//     final currentQuantity = cartItem.cart.quantityAsInt;

//     if (currentQuantity > 1) {
//       // Update quantity normally
//       cartController.updateCartItemQuantity(cartItem, currentQuantity - 1);
//     } else if (currentQuantity == 1) {
//       // Show confirmation dialog for removal
//       _showRemovalConfirmationDialog(context, cartItem, cartController);
//     }
//   }

//   /// Increases the quantity of the cart item
//   void _increaseQuantity(
//     CartItemModel cartItem,
//     CartController cartController,
//   ) {
//     final currentQuantity = cartItem.cart.quantityAsInt;
//     final stockLimit = int.tryParse(variationStock) ?? 100;

//     if (currentQuantity < stockLimit) {
//       cartController.updateCartItemQuantity(cartItem, currentQuantity + 1);
//     } else {
//       // Show stock limit message
//       Get.snackbar(
//         'Stock Limit',
//         'Maximum available quantity is $stockLimit',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: TColors.warning,
//         colorText: TColors.white,
//       );
//     }
//   }

//   /// Shows confirmation dialog when user tries to remove item (quantity = 0)
//   void _showRemovalConfirmationDialog(
//     BuildContext context,
//     CartItemModel cartItem,
//     CartController cartController,
//   ) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return Dialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20.0),
//           ),
//           child: Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(20.0),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Icon(
//                   Icons.warning_rounded,
//                   size: 50,
//                   color: Colors.orange,
//                 ),
//                 const SizedBox(height: 15),
//                 const Text(
//                   "Remove Item",
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: TColors.primary,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 const Text(
//                   "Are you sure you want to remove this item from the cart?",
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: TColors.primary,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     // Cancel button
//                     ElevatedButton(
//                       onPressed: () {
//                         Navigator.of(context).pop(); // Just close dialog
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.grey[300],
//                       ),
//                       child: const Text(
//                         "Cancel",
//                         style: TextStyle(color: Colors.black),
//                       ),
//                     ),
//                     // Confirm removal button
//                     ElevatedButton(
//                       onPressed: () {
//                         Navigator.of(context).pop();
//                         cartController.removeCartItem(cartItem);
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: TColors.error,
//                       ),
//                       child: const Text(
//                         "Remove",
//                         style: TextStyle(color: Colors.white),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
