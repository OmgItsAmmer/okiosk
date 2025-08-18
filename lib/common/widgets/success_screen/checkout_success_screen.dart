import 'package:okiosk/common/styles/spacingstyles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/routes.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/helper_functions.dart';

class CheckoutSuccessScreen extends StatelessWidget {
  const CheckoutSuccessScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: TSpacingStyle.paddingWithAppBarHeight * 2,
          child: Column(
            children: [
              //Image
              Image(
                image: AssetImage(
                  TImages.staticSuccessIllustration,
                ),
                width: THelperFunctions.screenWidth() * 0.6,
              ),
              SizedBox(
                height: TSizes.spaceBtwSections,
              ),
              //Text & Subtitle
              Text(
                "Congratulations!",
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: TSizes.spaceBtwItems,
              ),

              Text(
                "Your order has been placed successfully, go to your order page to track your order.",
                style: Theme.of(context).textTheme.labelMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: TSizes.spaceBtwItems,
              ),

              // Notification information in English
              Container(
                padding: EdgeInsets.all(TSizes.md),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceVariant
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                ),
                child: Column(
                  children: [
                    Text(
                      "📱 Order Notifications",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: TSizes.sm),
                    Text(
                      "You will receive a notification when your order is ready for pickup. If your order gets cancelled, you can contact our support team to ask for the reason.",
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: TSizes.sm),
                    // Support link
                    GestureDetector(
                      onTap: () {
                        // Get.toNamed(TRoutes.support);
                      },
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium,
                          children: const [
                            TextSpan(
                              text: "Need help? Contact ",
                            ),
                            TextSpan(
                              text: "support",
                              style: TextStyle(
                                color: TColors.primary,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: " for assistance.",
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: TSizes.spaceBtwItems),

              // Notification information in Urdu
              Container(
                padding: EdgeInsets.all(TSizes.md),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceVariant
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                ),
                child: Column(
                  children: [
                    Text(
                      "📱 آرڈر نوٹیفیکیشنز",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: TSizes.sm),
                    Text(
                      "جب آپ کا آرڈر پک اپ کے لیے تیار ہو جائے گا تو آپ کو نوٹیفیکیشن ملے گا۔ اگر آپ کا آرڈر منسوخ ہو جائے تو آپ وجہ جاننے کے لیے ہماری سپورٹ ٹیم سے رابطہ کر سکتے ہیں۔",
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: TSizes.sm),
                    // Support link in Urdu
                    GestureDetector(
                      onTap: () {
                        // TODO: Navigate to support page
                        // Get.toNamed(TRoutes.support);
                      },
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium,
                          children: [
                            TextSpan(
                              text: "مدد چاہیے؟ ",
                            ),
                            TextSpan(
                              text: "سپورٹ",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: " سے رابطہ کریں۔",
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: TSizes.spaceBtwSections,
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.toNamed(TRoutes.home);
                  },
                  child: Text(TTexts.tContinue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
