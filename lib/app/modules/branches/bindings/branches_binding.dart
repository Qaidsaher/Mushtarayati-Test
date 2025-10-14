import 'package:get/get.dart';
import '../controllers/branches_controller.dart';

class BranchesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BranchesController>(() => BranchesController());
  }
}
