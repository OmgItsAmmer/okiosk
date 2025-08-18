import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:okiosk/routes/app_routes.dart';
import 'data/bindings/general_binding.dart';
import 'routes/routes.dart';
import 'utils/theme/theme.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
    return GetMaterialApp(
      themeMode: ThemeMode.system,
      theme: TAppTheme.lightTheme,
      darkTheme: TAppTheme.darkTheme,
      initialBinding: GeneralBindings(),
      //  initialBinding: GeneralBindings(),
      getPages: AppRoutes.pages,
      initialRoute: TRoutes.signIn, // Changed to POS Kiosk for demo
      navigatorKey: navigatorKey,
      //  navigatorObservers: [TRouteObserver()],
      // unknownRoute: GetPage(
      //     name: TRoutes.UnkownRoute,
      //     page: () => const UnkownRoute(),
      //     middlewares: [TRouteMiddleware()]),
    );
  }
}
