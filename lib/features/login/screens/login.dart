// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../common/widgets/form_divider.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/constants/text_strings.dart';

import '../../../utils/helpers/helper_functions.dart';
import 'widgets/login_form.dart';
import 'widgets/login_header.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Scaffold(
      backgroundColor: dark ? TColors.black : TColors.white,
      body: Center(
        child: SingleChildScrollView(
          child: TRoundedContainer(
            width: 500,
            borderColor: dark ? TColors.darkGrey : TColors.grey,
            shadowBorder: true,
            backgroundColor: dark ? TColors.dark : TColors.white,
            padding: EdgeInsets.all(TSizes.defaultSpace),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TLoginHeader(dark: dark),
                TLoginForm(),
                // TFormDivider(
                //   dividerText: TTexts.orSignInWith.capitalize!,
                //   dark: dark,
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
