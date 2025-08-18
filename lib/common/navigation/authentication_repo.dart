import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/cart/controller/cart_controller.dart';
import '../../features/categories/controller/category_controller.dart';
import '../../features/customer/controller/customer_controller.dart';
import '../../features/login/controller/login_controller.dart';
import '../../features/login/screens/login.dart';
import '../../features/network_manager/network_manager.dart';
import '../../features/pos/screens/pos_kiosk_screen.dart';
import '../../features/products/controller/product_controller.dart';
import '../../main.dart';
import '../../routes/routes.dart';

class AuthenticationRepository extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _initlizeCritcalControllers();

    // Use post-frame callback to ensure app is fully initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      screenRedirect();
    });

    //for futute listining
    _initlizeSupabaseAuthListener();
    FlutterNativeSplash.remove();
  }

  Future<void> screenRedirect() async {
    if (await checkSession()) {
      _initlizePostSignInControllers();
      Get.off(() => const PosKioskScreen());
    } else {
      Get.off(() => const LoginScreen());
    }
  }

  Future<bool> checkSession() async {
    //check from direct supabase auth session
    final session = supabase.auth.currentSession;
    if (session != null) {
      return true;
    }
    return false;
  }

  void _initlizeCritcalControllers() {
    try {
      Get.put(NetworkManager(), permanent: true);
      Get.lazyPut(() => LoginController(), fenix: true);
      Get.put(CustomerController(), permanent: true);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> _initlizePostSignInControllers() async {
    try {
      final productController = Get.put(ProductController(), permanent: true);
      final categoryController = Get.put(CategoryController(), permanent: true);
      Get.put(CartController(), permanent: true);

      // Load ALL products for POS system (not just popular ones)
      await productController.loadAllProductsForPOS();

      // Set products in category controller for filtering
      categoryController.setProducts(productController.allProductsForPOS);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  //initilize Supabase auth listener
  void _initlizeSupabaseAuthListener() {
    supabase.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedIn) {
        _initlizePostSignInControllers();
        screenRedirect();
      } else if (event.event == AuthChangeEvent.signedOut) {
        screenRedirect();
      }
    });
  }
}
