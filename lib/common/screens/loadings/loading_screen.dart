import 'package:flutter/material.dart';
import 'package:get/get.dart';


import '../../../../utils/constants/sizes.dart';
import '../../../utils/constants/image_strings.dart';
import '../../widgets/loaders/animation_loader.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                TAnimationLoaderWidget(
                  text: "Initializing your app...",
                  animation: TImages.docerAnimation,
                  showAction: false,
                ),
                SizedBox(height: 32),
                Text(
                  "Please wait while we set up your experience",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
