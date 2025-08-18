import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:okiosk/routes/app_routes.dart';
import 'routes/routes.dart';
import 'utils/theme/theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    
    return GetMaterialApp(
      defaultTransition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
      themeMode: ThemeMode.system,
      theme: TAppTheme.lightTheme,
      darkTheme: TAppTheme.darkTheme,
      getPages: AppRoutes.pages,
     initialRoute: TRoutes.loading, 
    
      //  navigatorObservers: [TRouteObserver()],
      // unknownRoute: GetPage( 
      //     name: TRoutes.UnkownRoute,
      //     page: () => const UnkownRoute(),
      //     middlewares: [TRouteMiddleware()]),
    );
  }
}
