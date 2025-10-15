import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../theme/palette.dart';

/// Font option data class
class FontOption {
  final String name;
  final String displayName;
  final bool isDefault;

  const FontOption({
    required this.name,
    required this.displayName,
    this.isDefault = false,
  });
}

/// Button size options for accessibility
enum ButtonSize {
  small(height: 40, padding: 8, label: 'صغير'),
  medium(height: 48, padding: 12, label: 'متوسط'),
  large(height: 56, padding: 16, label: 'كبير');

  final double height;
  final double padding;
  final String label;

  const ButtonSize({
    required this.height,
    required this.padding,
    required this.label,
  });
}

class ThemeController extends GetxController {
  final box = GetStorage();

  final themeMode = ThemeMode.system.obs;
  final colorSeed = Palette.primary.obs;
  final fontFamily = 'Tajawal'.obs;
  final baseFontSize = 16.0.obs; // Increased default for better readability
  final highContrast = false.obs; // Accessibility feature
  final reducedMotion = false.obs; // Accessibility feature
  final buttonSize = ButtonSize.medium.obs; // Touch target size

  static const _kThemeKey = 'themeMode';
  static const _kColorKey = 'themeColor';
  static const _kFontKey = 'fontFamily';
  static const _kFontSizeKey = 'fontSize';
  static const _kHighContrastKey = 'highContrast';
  static const _kReducedMotionKey = 'reducedMotion';
  static const _kButtonSizeKey = 'buttonSize';

  static const Color defaultColor = Palette.primary;

  // Available font families for Arabic support
  final availableFonts = const [
    FontOption(name: 'Tajawal', displayName: 'تجول (افتراضي)', isDefault: true),
    FontOption(name: 'Cairo', displayName: 'القاهرة'),
    FontOption(name: 'Amiri', displayName: 'أميري'),
    FontOption(name: 'Rubik', displayName: 'روبيك'),
    FontOption(name: 'Almarai', displayName: 'المرعي'),
  ];

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  void _loadSettings() {
    // Load theme mode
    final savedTheme = box.read<String>(_kThemeKey);
    if (savedTheme == 'dark') {
      themeMode.value = ThemeMode.dark;
    } else if (savedTheme == 'light') {
      themeMode.value = ThemeMode.light;
    } else {
      themeMode.value = ThemeMode.system;
    }

    // Load color seed
    final savedColor = box.read<int>(_kColorKey);
    if (savedColor != null) {
      colorSeed.value = Color(savedColor);
    }

    // Load font settings
    final savedFont = box.read<String>(_kFontKey);
    final savedSize = box.read<double>(_kFontSizeKey);
    if (savedFont != null) fontFamily.value = savedFont;
    if (savedSize != null) baseFontSize.value = savedSize;

    // Load accessibility settings
    final savedContrast = box.read<bool>(_kHighContrastKey);
    final savedMotion = box.read<bool>(_kReducedMotionKey);
    final savedButtonSize = box.read<String>(_kButtonSizeKey);

    if (savedContrast != null) highContrast.value = savedContrast;
    if (savedMotion != null) reducedMotion.value = savedMotion;
    if (savedButtonSize != null) {
      buttonSize.value = ButtonSize.values.firstWhere(
        (e) => e.name == savedButtonSize,
        orElse: () => ButtonSize.medium,
      );
    }
  }

  ThemeData get lightTheme {
    final scheme =
        highContrast.value
            ? ColorScheme.fromSeed(
              seedColor: colorSeed.value,
              brightness: Brightness.light,
              contrastLevel: 1.0, // Maximum contrast
            )
            : ColorScheme.fromSeed(
              seedColor: colorSeed.value,
              brightness: Brightness.light,
            );

    return _buildTheme(scheme, Brightness.light);
  }

  ThemeData get darkTheme {
    final scheme =
        highContrast.value
            ? ColorScheme.fromSeed(
              seedColor: colorSeed.value,
              brightness: Brightness.dark,
              contrastLevel: 1.0,
            )
            : ColorScheme.fromSeed(
              seedColor: colorSeed.value,
              brightness: Brightness.dark,
            );

    return _buildTheme(scheme, Brightness.dark);
  }

  ThemeData _buildTheme(ColorScheme scheme, Brightness brightness) {
    final baseTextTheme =
        brightness == Brightness.light
            ? Typography.material2021().black
            : Typography.material2021().white;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily.value,

      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),

      // Cards
      cardTheme: CardTheme(
        elevation: highContrast.value ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side:
              highContrast.value
                  ? BorderSide(color: scheme.outline, width: 1)
                  : BorderSide.none,
        ),
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: scheme.outline,
            width: highContrast.value ? 2 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: scheme.outline,
            width: highContrast.value ? 2 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: buttonSize.value.padding,
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(88, buttonSize.value.height),
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: buttonSize.value.padding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(88, buttonSize.value.height),
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: buttonSize.value.padding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(88, buttonSize.value.height),
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: buttonSize.value.padding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(width: highContrast.value ? 2 : 1),
        ),
      ),

      // Text theme
      textTheme: _scaledTextTheme(
        baseTextTheme,
        baseFontSize.value / 16.0, // Changed base from 14 to 16
        fontFamily.value,
      ),

      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: highContrast.value ? 8 : 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // List tiles - larger touch targets
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: buttonSize.value == ButtonSize.large ? 8 : 4,
        ),
        minVerticalPadding: buttonSize.value == ButtonSize.large ? 12 : 8,
      ),

      // Chips
      chipTheme: ChipThemeData(
        side:
            highContrast.value
                ? BorderSide(color: scheme.outline, width: 1)
                : null,
      ),
    );
  }

  TextTheme _scaledTextTheme(TextTheme base, double factor, String family) {
    // Material 3 default sizes with better readability
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
      'bodyMedium': 16.0, // Increased from 14
      'bodySmall': 14.0, // Increased from 12
      'labelLarge': 14.0,
      'labelMedium': 13.0, // Increased from 12
      'labelSmall': 12.0, // Increased from 11
    };

    TextStyle scaleStyleWithDefault(TextStyle? s, String key) {
      final fs = s?.fontSize ?? defaults[key]!;
      final scaled = fs * factor;

      // Apply better letter spacing for Arabic text readability
      final letterSpacing =
          key.contains('body') || key.contains('label') ? 0.2 : 0.0;

      // Increase line height for better readability
      final height = key.contains('body') ? 1.6 : 1.4;

      return (s ?? const TextStyle()).copyWith(
        fontSize: scaled,
        fontFamily: family,
        letterSpacing: letterSpacing,
        height: height,
        fontWeight:
            highContrast.value && key.contains('title')
                ? FontWeight.w600
                : s?.fontWeight,
      );
    }

    return TextTheme(
      displayLarge: scaleStyleWithDefault(base.displayLarge, 'displayLarge'),
      displayMedium: scaleStyleWithDefault(base.displayMedium, 'displayMedium'),
      displaySmall: scaleStyleWithDefault(base.displaySmall, 'displaySmall'),
      headlineLarge: scaleStyleWithDefault(base.headlineLarge, 'headlineLarge'),
      headlineMedium: scaleStyleWithDefault(
        base.headlineMedium,
        'headlineMedium',
      ),
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
    final argb =
        (color.a.toInt() << 24) |
        (color.r.toInt() << 16) |
        (color.g.toInt() << 8) |
        color.b.toInt();
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

  void setHighContrast(bool enabled) {
    highContrast.value = enabled;
    box.write(_kHighContrastKey, enabled);
  }

  void setReducedMotion(bool enabled) {
    reducedMotion.value = enabled;
    box.write(_kReducedMotionKey, enabled);
  }

  void setButtonSize(ButtonSize size) {
    buttonSize.value = size;
    box.write(_kButtonSizeKey, size.name);
  }

  void increaseFontSize() {
    if (baseFontSize.value < 24) {
      setBaseFontSize(baseFontSize.value + 2);
    }
  }

  void decreaseFontSize() {
    if (baseFontSize.value > 12) {
      setBaseFontSize(baseFontSize.value - 2);
    }
  }

  void resetToDefault() {
    colorSeed.value = defaultColor;
    themeMode.value = ThemeMode.system;
    baseFontSize.value = 16.0;
    fontFamily.value = 'Tajawal';
    highContrast.value = false;
    reducedMotion.value = false;
    buttonSize.value = ButtonSize.medium;

    box.remove(_kColorKey);
    box.remove(_kThemeKey);
    box.remove(_kFontKey);
    box.remove(_kFontSizeKey);
    box.remove(_kHighContrastKey);
    box.remove(_kReducedMotionKey);
    box.remove(_kButtonSizeKey);
  }
}
