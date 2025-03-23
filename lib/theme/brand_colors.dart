import 'package:flutter/material.dart';

class BrandColors {
  // Primary colors from design guide
  static const Color gold = Color(0xFFD2982A); // #d2982a specified in guide
  static const Color darkGray = Color(0xFF2D2C31); // #2d2c31 specified in guide

  // Additional color variants for UI elements
  static const Color goldLight =
      Color(0xFFE5C070); // Lighter version for hover states
  static const Color goldDark =
      Color(0xFFB07B18); // Darker version for pressed states

  // Standard colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color error = Color(0xFFD32F2F); // Standard error color

  // Background colors
  static const Color backgroundLight = Color(0xFFF8F8F8);
  static const Color cardBackground = Colors.white;

  // Text colors
  static const Color textPrimary = Color(0xFF2D2C31); // Same as darkGray
  static const Color textSecondary = Color(0xFF6C6C6C);
  static const Color textLight = Color(0xFF9E9E9E);
}
