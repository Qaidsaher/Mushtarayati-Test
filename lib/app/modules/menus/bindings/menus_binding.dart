import 'package:get/get.dart';
import '../controllers/menus_controller.dart';

class MenusBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MenusController>(() => MenusController());
  }
}
