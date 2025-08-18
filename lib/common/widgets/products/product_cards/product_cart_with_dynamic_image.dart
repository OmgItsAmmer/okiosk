import 'package:okiosk/common/widgets/products/product_cards/dynamic_product_card_vertical.dart';

import 'package:okiosk/utils/constants/enums.dart';
import 'package:flutter/material.dart';


import '../../../../features/media/controller/media_controller.dart';
import '../../../../features/products/models/product_model.dart';


/// Custom product card that fetches and displays product images
class ProductCardWithImage extends StatelessWidget {
  final ProductModel product; // Your product model
  final MediaController mediaController;
 // final VoidCallback onWishlistPressed;

  const ProductCardWithImage({
    super.key,
    required this.product,
    required this.mediaController,
    //required this.onWishlistPressed,
  });

  @override
  Widget build(BuildContext context) {

 

    return FutureBuilder<String?>(
      future: mediaController.fetchMainImage(
          product.productId ?? 0, MediaCategory.products.name),
      builder: (context, snapshot) {
        // Get the image URL from the snapshot or use fallback
        final String imageUrl = snapshot.data ?? '';
        final bool hasImage = snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.isNotEmpty;

        return ProductCardWithDynamicImage(
          product: product,
          imageUrl: imageUrl,
          isNetworkImage: hasImage,
          
        );
      },
    );
  }
}
