import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_storage/get_storage.dart';

import 'app/routes/app_pages.dart';
import 'app/bindings/app_binding.dart';
// theme is provided by ThemeController
import 'app/core/controllers/appearance_controller.dart';
import 'app/core/controllers/theme_controller.dart';
import 'app/core/utils/constants.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GetStorage.init();

  // register the appearance and theme controllers early so themeMode is available
  Get.put<AppearanceController>(AppearanceController(), permanent: true);
  Get.put<ThemeController>(ThemeController(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();

    return Obx(() => GetMaterialApp(
      title: Constants.appName,
          initialBinding: AppBinding(),
          locale: const Locale('ar'),
          fallbackLocale: const Locale('ar'),
          theme: themeCtrl.lightTheme,
          darkTheme: themeCtrl.darkTheme,
          themeMode: themeCtrl.themeMode.value,
          getPages: AppPages.pages,
          initialRoute: '/splash',
        ));
  }
}

