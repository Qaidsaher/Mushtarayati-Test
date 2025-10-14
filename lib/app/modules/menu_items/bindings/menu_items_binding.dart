import 'package:get/get.dart';
import '../controllers/menu_items_controller.dart';

class MenuItemsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MenuItemsController>(() => MenuItemsController());
  }
}
