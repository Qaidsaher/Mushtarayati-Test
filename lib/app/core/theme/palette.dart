import 'package:flutter/material.dart';

/// Modern color palette with accessibility-focused colors
class Palette {
  // Primary Brand Colors - Modern Green Theme
  static const Color primary = Color(0xFF0B6A4A); // Professional dark green
  static const Color primaryLight = Color(0xFF10916B); // Lighter green
  static const Color primaryDark = Color(0xFF094D36); // Deeper green

  // Secondary Colors - Complementary Blues
  static const Color secondary = Color(0xFF0B5FFF); // Modern blue
  static const Color secondaryLight = Color(0xFF4A8CFF); // Light blue
  static const Color secondaryDark = Color(0xFF0847CC); // Deep blue

  // Accent Colors - Warm Tones
  static const Color accent = Color(0xFFFF6B35); // Vibrant orange
  static const Color accentAmber = Color(0xFFFFB800); // Golden amber
  static const Color accentPurple = Color(0xFF8A4FFF); // Modern purple

  // Semantic Colors - High Contrast for Accessibility
  static const Color success = Color(0xFF059669); // Emerald green
  static const Color warning = Color(0xFFF59E0B); // Amber warning
  static const Color danger = Color(0xFFDC2626); // Strong red
  static const Color info = Color(0xFF0EA5E9); // Sky blue

  // Neutral Grays - Professional Palette
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // Background Surfaces
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF0F172A); // Slate dark
  static const Color surfaceAlt = Color(0xFFF1F5F9); // Light slate

  // Additional Theme Colors
  static const Color teal = Color(0xFF14B8A6);
  static const Color rose = Color(0xFFF43F5E);
  static const Color indigo = Color(0xFF6366F1);
  static const Color violet = Color(0xFF8B5CF6);

  // Color Seeds for Theme Generation
  static const List<ColorPalette> themeColors = [
    ColorPalette(
      name: 'أخضر احترافي',
      seed: primary,
      icon: '🌿',
      description: 'اللون الافتراضي - أخضر هادئ واحترافي',
    ),
    ColorPalette(
      name: 'أزرق حديث',
      seed: secondary,
      icon: '💙',
      description: 'أزرق عصري ومريح للعين',
    ),
    ColorPalette(
      name: 'بنفسجي أنيق',
      seed: accentPurple,
      icon: '💜',
      description: 'بنفسجي راقي وجذاب',
    ),
    ColorPalette(
      name: 'برتقالي دافئ',
      seed: accent,
      icon: '🧡',
      description: 'برتقالي نابض بالحياة',
    ),
    ColorPalette(
      name: 'كهرماني ذهبي',
      seed: accentAmber,
      icon: '🟡',
      description: 'ذهبي دافئ ومشرق',
    ),
    ColorPalette(
      name: 'فيروزي منعش',
      seed: teal,
      icon: '💚',
      description: 'فيروزي منعش وحيوي',
    ),
    ColorPalette(
      name: 'نيلي عميق',
      seed: indigo,
      icon: '💠',
      description: 'نيلي هادئ ومركز',
    ),
    ColorPalette(
      name: 'وردي ناعم',
      seed: rose,
      icon: '🌸',
      description: 'وردي رقيق وجميل',
    ),
  ];
}

/// Color palette data class
class ColorPalette {
  final String name;
  final Color seed;
  final String icon;
  final String description;

  const ColorPalette({
    required this.name,
    required this.seed,
    required this.icon,
    required this.description,
  });
}
