import 'package:get/get.dart';
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/login_page.dart';
import '../modules/splash/views/splash_page.dart';
import '../modules/auth/views/register_page.dart';
import '../modules/auth/views/forgot_page.dart';
import '../modules/profile/views/profile_settings_page.dart';
import '../modules/shell/views/shell_page.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/about/views/about_page.dart';
import '../modules/categories/views/categories_page.dart';
import '../modules/categories/bindings/categories_binding.dart';
import '../modules/branches/views/branches_page.dart';
import '../modules/branches/bindings/branches_binding.dart';
import '../modules/menus/views/menus_page.dart';
import '../modules/menus/bindings/menus_binding.dart';
import '../modules/menu_items/views/menu_items_page.dart';
import '../modules/menu_items/bindings/menu_items_binding.dart';

part 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(name: Routes.splash, page: () => const SplashPage()),
    GetPage(
      name: Routes.login,
      page: () => LoginPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.register,
      page: () => RegisterPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.forgot,
      page: () => ForgotPage(),
      binding: AuthBinding(),
    ),
    GetPage(name: Routes.profile, page: () => const ProfileSettingsPage()),
    GetPage(
      name: Routes.home,
      page: () => const ShellPage(),
      binding: HomeBinding(),
    ),
    GetPage(name: Routes.about, page: () => const AboutPage()),
    GetPage(
      name: Routes.categories,
      page: () => const CategoriesPage(),
      binding: CategoriesBinding(),
    ),
    GetPage(
      name: Routes.branches,
      page: () => const BranchesPage(),
      binding: BranchesBinding(),
    ),
    GetPage(
      name: Routes.menus,
      page: () => const MenusPage(),
      binding: MenusBinding(),
    ),
    GetPage(
      name: Routes.menuItems,
      page: () => const MenuItemsPage(),
      binding: MenuItemsBinding(),
    ),
  ];
}
