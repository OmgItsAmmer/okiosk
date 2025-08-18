import 'package:get/get.dart';
import 'package:okiosk/features/pos/screens/pos_kiosk_screen.dart';
import '../common/screens/loadings/loading_screen.dart';
import '../features/login/screens/login.dart';
import 'routes.dart';

class AppRoutes {
  static final pages = [
    // POS Kiosk Routes
    GetPage(
      name: TRoutes.posKiosk,
      page: () => const PosKioskScreen(),
      binding: PosKioskBinding(),
    ),
    GetPage(
      name: TRoutes.posKioskDebug,
      page: () => const PosKioskScreenDebug(),
      binding: PosKioskBinding(),
    ),
    GetPage(
      name: TRoutes.signIn,
      page: () => const LoginScreen(),
     // binding: LoginBinding(),
    ),

    //loading screen
    GetPage(
      name: TRoutes.loading,
      page: () => const LoadingScreen(),
    ),
  ];
}
