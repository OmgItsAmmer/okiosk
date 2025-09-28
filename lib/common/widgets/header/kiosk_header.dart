import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:okiosk/common/widgets/icons/t_circular_icon.dart';
import 'package:okiosk/common/widgets/texts/heading_text.dart';
import 'package:okiosk/utils/constants/sizes.dart';

import '../../../features/cart/controller/cart_controller.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../loaders/tloaders.dart';
import '../qr_scanner/qr_scanner_widget.dart';

class KioskHeader extends StatelessWidget {
  const KioskHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Container(
      width: double.infinity,
      //  height: 60,
      padding: const EdgeInsets.all(TSizes.defaultSpace / 2),
      color: dark ? TColors.black : TColors.lightGrey,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const TSectionHeading(
            title: 'Kiosk Header',
            showActionButton: false,
            textColor: TColors.primary,
          ),
          //another row of icons
          Row(
            children: [
              TCircularIcon(
                width: 40,
                height: 40,
                icon: Iconsax.notification,
                onPressed: () {},
                backgroundColor: dark ? TColors.primary : TColors.primary,
                color: dark ? TColors.white : TColors.white,
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              TCircularIcon(
                width: 40,
                height: 40,
                icon: Iconsax.camera,
                onPressed: () {},
                backgroundColor: dark ? TColors.primary : TColors.primary,
                color: dark ? TColors.white : TColors.white,
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              TCircularIcon(
                width: 40,
                height: 40,
                icon: Iconsax.scan_barcode,
                onPressed: () => _openQRScanner(context),
                backgroundColor: dark ? TColors.primary : TColors.primary,
                color: dark ? TColors.white : TColors.white,
              ),
            ],
          )
        ],
      ),
    );
  }

  void _openQRScanner(BuildContext context) {
    // Get.to(() => QRScannerWidget(
    //       onQRCodeScanned: (String qrData) async {
    //         Get.back(); // Close scanner
    //         await _handleQRCodeScanned(qrData);
    //       },
    //       title: 'Scan Customer QR Code',
    //       subtitle: 'Ask customer to show their QR code from the mobile app',
    //     ));
  }

  Future<void> _handleQRCodeScanned(String qrData) async {
    try {
      // Parse customer ID from QR data
      // Assuming QR data format is just the customer ID as string
      final customerId = int.tryParse(qrData);

      if (customerId == null) {
        TLoader.errorSnackBar(
          title: 'Invalid QR Code',
          message: 'The scanned QR code is not valid. Please try again.',
        );
        return;
      }

      // Get cart controller and scan customer QR
      final cartController = Get.find<CartController>();
      final success = await cartController.scanCustomerQR(customerId);

      if (!success) {
        TLoader.errorSnackBar(
          title: 'Failed to Load Cart',
          message: 'Could not load customer cart. Please try again.',
        );
      }
    } catch (e) {
      TLoader.errorSnackBar(
        title: 'Error',
        message: 'An error occurred while processing the QR code.',
      );
    }
  }
}
