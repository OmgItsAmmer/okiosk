import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:okiosk/utils/constants/image_strings.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../main.dart';

import '../../../common/widgets/loaders/tloaders.dart';
import '../../../data/repositories/login/login_repository.dart';
import '../../../routes/routes.dart';
import '../../../utils/popups/full_screen_loader.dart';
import '../../cart/controller/cart_controller.dart';
import '../../customer/controller/customer_controller.dart';
import '../../network_manager/network_manager.dart';
import '../../products/controller/product_controller.dart';
import '../../categories/controller/category_controller.dart';

class LoginController extends GetxController {
  final loginRepository = Get.put(LoginRepository());
  // variables
  final rememberMe = false.obs;
  final hidePassword = true.obs;
  final localStorage = GetStorage();
  final email = TextEditingController();
  final password = TextEditingController();
  GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  // final userController = Get.put(UserController());

  @override
  void onInit() {
    // Load saved credentials if remember me was selected
    email.text = localStorage.read('REMEMBER_ME_EMAIL') ?? "";
    //password.text = localStorage.read('REMEMBER_ME_PASSWORD') ?? "";

    // Load the saved remember me state
    rememberMe.value = localStorage.read('REMEMBER_ME_CHECKED') ?? false;

    super.onInit();
  }

  Future<void> emailAndPasswordSignIn() async {
    try {
      //start Loading
      TFullScreenLoader.openLoadingDialog(
          'Logging you in...', TImages.docerAnimation);

      //check internet connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      if (!loginFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Always save the current state of the remember me checkbox
      localStorage.write('REMEMBER_ME_CHECKED', rememberMe.value);

      //Save Data of Remember me is Selected
      if (rememberMe.value) {
        localStorage.write('REMEMBER_ME_EMAIL', email.text.trim());
        //   localStorage.write('REMEMBER_ME_PASSWORD', password.text.trim());
      } else {
        // Clear saved credentials if remember me is not selected
        localStorage.remove('REMEMBER_ME_EMAIL');
        //     localStorage.remove('REMEMBER_ME_PASSWORD');
      }

      // Log in the user
      await loginRepository.loginWithEmailAndPassword(
          email.text.trim(), password.text.trim());

      // Clear password field for security
      if (!rememberMe.value) {
        clearCredentials();
      }

      // Initialize controllers and load data for POS system
      await _initializePOSData();

      //Remove Loader
      TFullScreenLoader.stopLoading();

      //Redirect to dashboard
      Get.offAllNamed(TRoutes.posKiosk);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      TFullScreenLoader.stopLoading();
      TLoader.errorSnackBar(
          title: 'Login Failed',
          message: 'Please check your credentials and try again.');
    }
  }

  /// Initialize POS data after successful login
  Future<void> _initializePOSData() async {
    try {
      // Initialize controllers
      final productController = Get.put(ProductController(), permanent: true);
      final categoryController = Get.put(CategoryController(), permanent: true);
      final cartController = Get.put(CartController(), permanent: true);
      final customerController = Get.put(CustomerController(), permanent: true);

      // Load popular products for POS system
      await productController.loadPopularProductsLazily();

      // Set products in category controller for filtering
      categoryController.setProducts(productController.popularProducts);

      if (kDebugMode) {
        print('POS Data initialized successfully');
        print(
            'Total products loaded: ${productController.popularProducts.length}');
        print('Categories loaded: ${categoryController.allCategories.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing POS data: $e');
      }
      // Don't throw here to avoid breaking the login flow
      // The POS screen will handle loading its own data if needed
    }
  }

  // Toggle remember me value and save it immediately
  void toggleRememberMe() {
    rememberMe.value = !rememberMe.value;
    localStorage.write('REMEMBER_ME_CHECKED', rememberMe.value);

    // If remember me is turned off, clear saved credentials
    if (!rememberMe.value) {
      localStorage.remove('REMEMBER_ME_EMAIL');
      //  localStorage.remove('REMEMBER_ME_PASSWORD');
      // Don't clear the input fields while the user is still on the login screen
    }
  }

  Future<void> googleSignIn() async {
    try {
      TFullScreenLoader.openLoadingDialog(
          "Logging you in....", TImages.docerAnimation);

      //Check internet COnnectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      //Google Authentication
      // final userCredentional = await AuthenticationRepository.instance.signInWithGoogle();

      //Save user Record
      //  await userController.saveUserRecord(userCredentional);
      TFullScreenLoader.stopLoading();
      TLoader.errorSnackBar(
          title: "Google Sign-In",
          message:
              "Google sign-in is currently unavailable. Please try another method.");
      return;
      //  Get.to(()=> NavigationMenu());
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoader.errorSnackBar(
          title: 'Login Failed',
          message:
              'An error occurred during Google sign-in. Please try again.');
    }
  }

  void clearCredentials() {
    // Only clear password, keep email for user convenience
    password.clear();
  }
}
