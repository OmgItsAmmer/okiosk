import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:okiosk/common/widgets/icons/t_circular_icon.dart';
import 'package:okiosk/common/widgets/texts/heading_text.dart';
import 'package:okiosk/utils/constants/sizes.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/helpers/helper_functions.dart';

class KioskHeader extends StatelessWidget {
  const KioskHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Container(
      width: double.infinity,
      //  height: 60,
      padding: const EdgeInsets.all(TSizes.defaultSpace/2),
      color: dark ? TColors.black : TColors.lightGrey,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const TSectionHeading(title: 'Kiosk Header',showActionButton: false,textColor: TColors.primary,),
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
                onPressed: () {},
                backgroundColor: dark ? TColors.primary : TColors.primary,
                color: dark ? TColors.white : TColors.white,
              ),
            ],
          )
        ],
      ),
    );
  }
}
