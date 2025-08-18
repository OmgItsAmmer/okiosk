
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:okiosk/utils/exceptions/TFormatException.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/login/screens/login.dart';
import '../../../main.dart';


class LoginRepository extends GetxController {
  static LoginRepository get instance => Get.find();

  //Variables
  final deviceStorage = GetStorage();
  final _requireLoginEveryTime =
      true; // Set to true to require login every time

  @override
  void onReady() {
    // Clear any existing sessions if we want to require login every time
    if (_requireLoginEveryTime) {
      clearSessionOnStartup();
    }
  }

  // Clear any existing session on app startup
  Future<void> clearSessionOnStartup() async {
    try {
      if (kDebugMode) {
        print("Clearing session on startup to require new login");
      }

      // Sign out from Supabase to clear the current session
      await supabase.auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        print("Error clearing session: $e");
      }
    }
  }


  /*-------- Email & PasSSWOrd Sign-in --------*/
  /// [EmailAuthentication] - Sign in
  Future<void> loginWithEmailAndPassword(String email, String password) async {
    try {
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
     
    } on FormatException catch (_) {
      throw const TFormatException();
    }
  }

  // Future<void> deleteAccount() async {
  //   try {
  //     // Get secure service key
  //     final serviceKey = await SecureKeys.instance.getSupabaseServiceKey();

  //     if (serviceKey == null) {
  //       if (kDebugMode) {
  //         print("Error: Service key not available for admin operations");
  //       }
  //       TLoaders.errorSnackBar(
  //           title: "Error",
  //           message:
  //               "This operation is not available in release mode. Please contact support.");
  //       return;
  //     }

  //     // Admin client with Service Role key (retrieved securely)
  //     final supabaseAdmin = SupabaseClient(
  //       await SecureKeys.instance.getSupabaseUrl() ??
  //           SupabaseStrings.projectUrl,
  //       serviceKey,
  //     );

  //     final User? currentUser = Supabase.instance.client.auth.currentUser;

  //     // Ensure the user is logged in before proceeding
  //     if (currentUser == null) {
  //       TLoaders.errorSnackBar(title: "Error", message: "User is Null");
  //       return;
  //     }

  //     // Clear the profile image cache
  //     if (Get.isRegistered<MediaController>()) {
  //       final mediaController = Get.find<MediaController>();
  //       mediaController.refreshUserImage();
  //     }

  //     // Delete user with the admin client
  //     await supabaseAdmin.auth.admin.deleteUser(currentUser.id);
  //     TLoaders.successSnackBar(title: "Account Deleted Successfully");
  //     Get.to(() => const LoginScreen());
  //   } on FormatException catch (_) {
  //     throw const TFormatException();
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print("Error deleting account: $e");
  //     }
  //     TLoaders.errorSnackBar(
  //         title: "Error",
  //         message: "Could not delete account. Please try again later.");
  //   }
  // }

  // Future<void> logout() async {
  //   try {
  //     // Clear the profile image cache first
  //     if (Get.isRegistered<MediaController>()) {
  //       final mediaController = Get.find<MediaController>();
  //       mediaController.refreshUserImage();
  //     }

  //     // Sign out from Supabase
  //     await supabase.auth.signOut();

  //     // Navigate to login screen
  //     Get.offAll(() => const LoginScreen());

  //     TLoaders.successSnackBar(title: "Logged out successfully");
  //   } catch (e) {
  //     TLoaders.errorSnackBar(title: "Logout Error", message: e.toString());
  //   }
  // }
}
