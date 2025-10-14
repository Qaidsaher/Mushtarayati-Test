import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  final box = GetStorage();

  final themeMode = ThemeMode.system.obs;
  final colorSeed = const Color(0xFF2563EB).obs;
  final fontFamily = 'Tajawal'.obs;
  final baseFontSize = 14.0.obs;

  static const _kThemeKey = 'themeMode';
  static const _kColorKey = 'themeColor';
  static const _kFontKey = 'fontFamily';
  static const _kFontSizeKey = 'fontSize';

  final availableColors = const [
    Color(0xFF0B5FFF), // deep blue
    Color(0xFF0B6A4A), // dark green
    Color(0xFFB00020), // ruby
    Color(0xFF8A4FFF), // muted violet
    Color(0xFF0F172A), // slate
    Color(0xFF334155), // gray-blue
  ];

  static const Color defaultColor = Color(0xFF2563EB);

  @override
  void onInit() {
    super.onInit();
    final savedTheme = box.read<String>(_kThemeKey);
    final savedColor = box.read<int>(_kColorKey);
    if (savedTheme == 'dark') {
      themeMode.value = ThemeMode.dark;
    } else if (savedTheme == 'light') {
      themeMode.value = ThemeMode.light;
    } else {
      themeMode.value = ThemeMode.system;
    }

    if (savedColor != null) {
      colorSeed.value = Color(savedColor);
    }
    final savedFont = box.read<String>(_kFontKey);
    final savedSize = box.read<double>(_kFontSizeKey);
    if (savedFont != null) fontFamily.value = savedFont;
    if (savedSize != null) baseFontSize.value = savedSize;
  }

  ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: colorSeed.value,
        fontFamily: fontFamily.value,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 1),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
        ),
        textTheme: _scaledTextTheme(Typography.material2021().black, baseFontSize.value / 14.0, fontFamily.value),
      );

  ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: colorSeed.value,
        fontFamily: fontFamily.value,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 1),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
        ),
        textTheme: _scaledTextTheme(Typography.material2021().white, baseFontSize.value / 14.0, fontFamily.value),
      );

  TextTheme _scaledTextTheme(TextTheme base, double factor, String family) {
    // Material default sizes (approximate) used when a style has no explicit fontSize
    const defaults = {
      'displayLarge': 57.0,
      'displayMedium': 45.0,
      'displaySmall': 36.0,
      'headlineLarge': 32.0,
      'headlineMedium': 28.0,
      'headlineSmall': 24.0,
      'titleLarge': 22.0,
      'titleMedium': 16.0,
      'titleSmall': 14.0,
      'bodyLarge': 16.0,
      'bodyMedium': 14.0,
      'bodySmall': 12.0,
      'labelLarge': 14.0,
      'labelMedium': 12.0,
      'labelSmall': 11.0,
    };

    TextStyle scaleStyleWithDefault(TextStyle? s, String key) {
      final fs = s?.fontSize ?? defaults[key]!;
      return (s ?? const TextStyle()).copyWith(fontSize: fs * factor, fontFamily: family);
    }

    return TextTheme(
      displayLarge: scaleStyleWithDefault(base.displayLarge, 'displayLarge'),
      displayMedium: scaleStyleWithDefault(base.displayMedium, 'displayMedium'),
      displaySmall: scaleStyleWithDefault(base.displaySmall, 'displaySmall'),
      headlineLarge: scaleStyleWithDefault(base.headlineLarge, 'headlineLarge'),
      headlineMedium: scaleStyleWithDefault(base.headlineMedium, 'headlineMedium'),
      headlineSmall: scaleStyleWithDefault(base.headlineSmall, 'headlineSmall'),
      titleLarge: scaleStyleWithDefault(base.titleLarge, 'titleLarge'),
      titleMedium: scaleStyleWithDefault(base.titleMedium, 'titleMedium'),
      titleSmall: scaleStyleWithDefault(base.titleSmall, 'titleSmall'),
      bodyLarge: scaleStyleWithDefault(base.bodyLarge, 'bodyLarge'),
      bodyMedium: scaleStyleWithDefault(base.bodyMedium, 'bodyMedium'),
      bodySmall: scaleStyleWithDefault(base.bodySmall, 'bodySmall'),
      labelLarge: scaleStyleWithDefault(base.labelLarge, 'labelLarge'),
      labelMedium: scaleStyleWithDefault(base.labelMedium, 'labelMedium'),
      labelSmall: scaleStyleWithDefault(base.labelSmall, 'labelSmall'),
    );
  }

  void toggleTheme() {
    if (themeMode.value == ThemeMode.dark) {
      setTheme(ThemeMode.light);
    } else {
      setTheme(ThemeMode.dark);
    }
  }

  void setTheme(ThemeMode mode) {
    themeMode.value = mode;
    box.write(_kThemeKey, mode == ThemeMode.dark ? 'dark' : 'light');
  }

  void setColor(Color color) {
    colorSeed.value = color;
    // store as ARGB int explicitly
  final argb = (color.a.toInt() << 24) | (color.r.toInt() << 16) | (color.g.toInt() << 8) | color.b.toInt();
    box.write(_kColorKey, argb);
  }

  void setFontFamily(String f) {
    fontFamily.value = f;
    box.write(_kFontKey, f);
  }

  void setBaseFontSize(double size) {
    baseFontSize.value = size;
    box.write(_kFontSizeKey, size);
  }

  void resetToDefault() {
    colorSeed.value = defaultColor;
    themeMode.value = ThemeMode.system;
    box.remove(_kColorKey);
    box.remove(_kThemeKey);
    box.remove(_kFontKey);
    box.remove(_kFontSizeKey);
  }
}
