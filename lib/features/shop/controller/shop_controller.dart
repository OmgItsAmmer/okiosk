import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../data/repositories/shop/shop_repository.dart';

class ShopController extends GetxController {
  final ShopRepository shopRepository = Get.put(ShopRepository());

  // @override
  // void onInit() {
  //   super.onInit();
  //   isShippingAllowed();
  // }

  //get is shipping allowed

  Future<bool> isShippingAllowed() async {
    try {
      final isShippingAllowed = await shopRepository.isShippingAllowed();
      return isShippingAllowed;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return false;
    }
  }

  Future<int> maxAllowedQuantity() async {
    try {
      final maxAllowedQuantity = await shopRepository.maxAllowedQuantity();
      return maxAllowedQuantity;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return 50;
    }
  }

  // Terms and Conditions
  List<Map<String, String>> getTermsAndConditions() {
    return [
      {
        "title": "Account Registration",
        "content":
            "By creating an account, you agree to provide accurate and complete information. You are responsible for maintaining the confidentiality of your account credentials."
      },
      {
        "title": "Product Information",
        "content":
            "While we strive to provide accurate product descriptions, images, and pricing, we do not guarantee that all information is error-free. Product availability is subject to change without notice."
      },
      {
        "title": "Order Processing",
        "content":
            "Orders are processed on a first-come, first-served basis. We reserve the right to cancel or modify orders due to inventory issues, pricing errors, or other circumstances beyond our control."
      },
      {
        "title": "Payment and Security",
        "content":
            "All payments are processed securely through our payment partners. We do not store your complete payment information on our servers. You agree to pay all charges incurred through your account."
      },
      {
        "title": "Shipping and Delivery",
        "content":
            "Delivery times are estimates only. We are not responsible for delays caused by factors beyond our control, including weather, customs, or carrier issues. Risk of loss transfers to you upon delivery."
      },
      {
        "title": "Returns and Refunds",
        "content":
            "Returns must be initiated within 30 days of delivery. Items must be unused and in original packaging. Refunds will be processed within 5-7 business days after we receive your return."
      },
      {
        "title": "Privacy Policy",
        "content":
            "Your personal information is collected and used in accordance with our Privacy Policy. By using our services, you consent to our data practices as described in our Privacy Policy."
      },
      {
        "title": "Limitation of Liability",
        "content":
            "Our liability is limited to the amount you paid for the specific product. We are not liable for indirect, incidental, or consequential damages."
      },
      {
        "title": "Governing Law",
        "content":
            "These terms are governed by the laws of your jurisdiction. Any disputes will be resolved through binding arbitration or small claims court."
      },
      {
        "title": "Changes to Terms",
        "content":
            "We may modify these terms at any time. Continued use of our services after changes constitutes acceptance of the new terms."
      }
    ];
  }
}
