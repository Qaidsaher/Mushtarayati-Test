import 'package:get/get.dart';
import '../core/controllers/appearance_controller.dart';
import '../core/controllers/theme_controller.dart';
import '../data/controllers/sync_controller.dart';
import '../core/controllers/user_controller.dart';
import '../modules/auth/controllers/auth_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AppearanceController>(AppearanceController(), permanent: true);
    Get.put<ThemeController>(ThemeController(), permanent: true);
    Get.put<SyncController>(SyncController(), permanent: true);
    Get.put<UserController>(UserController(), permanent: true);
    // Ensure AuthController is available globally (used by profile/logout flows)
    Get.put<AuthController>(AuthController(), permanent: true);
  }
}
