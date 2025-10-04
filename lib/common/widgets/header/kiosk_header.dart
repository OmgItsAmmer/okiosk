import 'package:flutter/material.dart';
import 'package:okiosk/common/widgets/images/t_rounded_image.dart';
import 'package:okiosk/utils/constants/sizes.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../search/animated_search_bar.dart';

class KioskHeader extends StatelessWidget {
  const KioskHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Container(
      width: double.infinity,
      //  height: 60,
      padding: const EdgeInsets.all(TSizes.defaultSpace / 2),
      color: dark ? TColors.primaryBackground : TColors.primaryBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // const TSectionHeading(
          //   title: 'Kiosk Header',
          //   showActionButton: false,
          //   textColor: TColors.primary,
          // ),
          TRoundedImage(
            imageurl: TImages.appIcon,
            isNetworkImage: false,
            width: 80,
            height: 80,
          ),
          const SizedBox(width: TSizes.spaceBtwItems),
          Expanded(
            child: const AnimatedSearchBar(),
          ),
          const SizedBox(width: TSizes.spaceBtwItems),
          TRoundedImage(
            imageurl: TImages.aiAgentDoodle,
            isNetworkImage: false,
            width: 80,
            height: 80,
          ),
        ],
      ),
    );
  }
}
