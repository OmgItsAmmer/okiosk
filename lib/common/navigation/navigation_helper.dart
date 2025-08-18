import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class NavigationHelper {
  static void goBack(BuildContext context) {
    try {
      // Try GetX first
      Get.back();
    } catch (e) {
      // Fallback to Navigator
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Get.offAllNamed('/home');
      }
    }
  }

   static void goBackFromController() {
    // Specifically for controller usage
    try {
      Get.back();
    } catch (e) {
      // If Get.back fails, try to navigate to a safe route
      Get.offAllNamed('/home');
    }
  }
}