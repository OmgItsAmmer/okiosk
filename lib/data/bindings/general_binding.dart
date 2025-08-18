import 'package:get/get.dart';
import 'package:okiosk/features/network_manager/network_manager.dart';
import '../../features/categories/controller/category_controller.dart';
import '../../features/login/controller/login_controller.dart';

class GeneralBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(NetworkManager());
    Get.lazyPut(() => LoginController());
    Get.put(() => CategoryController());
  }
}
