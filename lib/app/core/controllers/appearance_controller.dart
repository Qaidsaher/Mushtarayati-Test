import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/theme_service.dart';

class AppearanceController extends GetxController {
  final ThemeService _themeService = ThemeService();

  // true = dark
  final _isDark = false.obs;
  bool get isDark => _isDark.value;

  Locale get locale => const Locale('ar');

  ThemeMode get themeMode => isDark ? ThemeMode.dark : ThemeMode.light;

  @override
  void onInit() {
    super.onInit();
    _isDark.value = _themeService.isDarkMode();
  }

  void toggleTheme() {
    _isDark.value = !_isDark.value;
    _themeService.saveThemeMode(_isDark.value);
    Get.changeThemeMode(themeMode);
  }
}
