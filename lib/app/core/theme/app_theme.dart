import 'package:flutter/material.dart';
import 'palette.dart';

class AppTheme {
  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: Palette.primary,
    brightness: Brightness.light,
    primary: Palette.primary,
    secondary: Palette.secondary,
    tertiary: Palette.accent,
  );

  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: Palette.primary,
    brightness: Brightness.dark,
    primary: Palette.primary,
    secondary: Palette.secondary,
    tertiary: Palette.accent,
  );

  static final ThemeData light = ThemeData(
    colorScheme: _lightScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: _lightScheme.surface,
    appBarTheme: AppBarTheme(backgroundColor: _lightScheme.primaryContainer, foregroundColor: _lightScheme.onPrimaryContainer),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: _lightScheme.primary)),
  );

  static final ThemeData dark = ThemeData(
    colorScheme: _darkScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: _darkScheme.surface,
    appBarTheme: AppBarTheme(backgroundColor: _darkScheme.primaryContainer, foregroundColor: _darkScheme.onPrimaryContainer),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: _darkScheme.primary)),
  );
}
