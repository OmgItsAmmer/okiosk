import 'package:get/get.dart';

class GeneralBindings extends Bindings {
  @override
  void dependencies() {

    //only that require on startup
    // Get.put(NetworkManager());
    // Get.lazyPut(() => LoginController(),fenix: true);
    // Get.lazyPut(() => CategoryController(),fenix: true);
  }
}
