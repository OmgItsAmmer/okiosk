// import 'package:okiosk/features/shop/controllers/product_controller.dart';
// import 'package:okiosk/features/shop/controllers/wishlist_controller.dart';
// import 'package:okiosk/features/shop/models/product_model.dart';
// import 'package:okiosk/utils/effects/shimmer%20effect.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:iconsax/iconsax.dart';

// import '../../../../features/media/controllers/media_controller.dart';
// import '../../../../features/personalization/controllers/user_controller.dart';
// import '../../../../utils/constants/sizes.dart';
// import '../../layout/grid_layout.dart';
// import '../product_cards/product_card_vertical.dart';
// import '../product_cards/product_cart_with_dynamic_image.dart';

// class TSortableProducts extends StatefulWidget {
//   const TSortableProducts({
//     super.key,
//   });

//   @override
//   State<TSortableProducts> createState() => _TSortableProductsState();
// }

// class _TSortableProductsState extends State<TSortableProducts> {
//   late final CustomerController userController;
//   late final WishlistController wishListController;
//   late final ProductController productController;

//   // Add sorting state
//   final RxString selectedSortOption = 'Names'.obs;

//   @override
//   void initState() {
//     super.initState();
//     userController = Get.find<CustomerController>();
//     wishListController = Get.find<WishlistController>();
//     productController = Get.find<ProductController>();

//     // Trigger loading of current brand products
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       productController.fetchCurrentBrandProducts();
//     });
//   }

//   // Sorting methods
//   void _sortProducts(String sortOption) {
//     selectedSortOption.value = sortOption;

//     switch (sortOption) {
//       case 'Alphabetical Order':
//         _sortByName();
//         break;
//       // case 'Higher Price':
//       //   _sortByPrice(ascending: false);
//       //   break;
//       // case 'Lower Price':
//       //   _sortByPrice(ascending: true);
//       //   break;
//     }
//   }

//   void _sortByName() {
//     final sortedProducts =
//         List<ProductModel>.from(productController.currentBrandProducts);
//     sortedProducts.sort((a, b) => a.name.compareTo(b.name));
//     productController.currentBrandProducts.assignAll(sortedProducts);
//   }

//   // void _sortByPrice({required bool ascending}) {
//   //   final sortedProducts =
//   //       List<ProductModel>.from(productController.currentBrandProducts);
//   //   sortedProducts.sort((a, b) {
//   //     final priceA =
//   //         double.tryParse(a.salePrice.isNotEmpty ? a.salePrice : a.basePrice) ??
//   //             0.0;
//   //     final priceB =
//   //         double.tryParse(b.salePrice.isNotEmpty ? b.salePrice : b.basePrice) ??
//   //             0.0;

//   //     return ascending ? priceA.compareTo(priceB) : priceB.compareTo(priceA);
//   //   });
//   //   productController.currentBrandProducts.assignAll(sortedProducts);
//   // }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         //Drop Down
//         Obx(() => DropdownButtonFormField<String>(
//             value: selectedSortOption.value,
//             decoration: InputDecoration(prefixIcon: Icon(Iconsax.sort)),
//             items: [
//               'Names',
//               'Higher Price',
//               'Lower Price',
//             ]
//                 .map((option) =>
//                     DropdownMenuItem(value: option, child: Text(option)))
//                 .toList(),
//             onChanged: (value) {
//               if (value != null) {
//                 _sortProducts(value);
//               }
//             })),
//         SizedBox(
//           height: TSizes.spaceBtwSections,
//         ),
//         //Products
//         Obx(
//           () => _buildProductsGrid(),
//         )
//       ],
//     );
//   }

//   Widget _buildProductsGrid() {
//     // Show loading state
//     if (productController.isLoading.value &&
//         productController.currentBrandProducts.isEmpty) {
//       return Center(child: TShimmerEffect(width: 80, height: 80));
//     }

//     // Show empty state
//     if (productController.currentBrandProducts.isEmpty &&
//         !productController.isLoading.value) {
//       return Center(child: Text("No products available"));
//     }

//     // Show products
//     return TGridLayout(
//       itemCount: productController.currentBrandProducts.length,
//       itemBuilder: (_, index) {
//         final product = productController.currentBrandProducts[index];

//         return ProductCardWithImage(
//           product: product,
//           mediaController: Get.find<MediaController>(),
//           onWishlistPressed: () {
//             final userController = Get.find<CustomerController>();
//             final wishListController = Get.find<WishlistController>();
//             wishListController.toggleWishlistItem(
//               product.productId,
//               userController.currentCustomer.value.customerId!,
//             );
//           },
//         );
//       },
//     );
//   }
// }
