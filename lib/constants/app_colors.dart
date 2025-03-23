import 'package:flutter/material.dart';

class AppColors {
  // Primary brand colors
  static const Color gold = Color(0xFFD2982A); // Gold per design guidelines
  static const Color darkGray =
      Color(0xFF2D2C31); // Dark gray per design guidelines

  // Define these as getters to resolve the errors
  static Color get primary => gold;
  static Color get secondary => darkGray;

  // Additional UI colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color lightGrey = Color(0xFFEEEEEE);
  static const Color mediumGrey = Color(0xFFAAAAAA);
  static const Color darkGrey = Color(0xFF757575);

  // Functional colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // Background colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color card = Colors.white;
  static const Color divider = Color(0xFFEEEEEE);
  static const Color shadow = Color(0x1A000000);

  // Text colors
  static const Color textPrimary = Color(0xFF2D2C31);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFAAAAAA);

  // Button colors
  static const Color buttonPrimary = gold;
  static const Color buttonSecondary = darkGray;
  static const Color buttonDisabled = Color(0xFFCCCCCC);

  // Link colors
  static const Color link = Color(0xFF1976D2);
  static const Color linkVisited = Color(0xFF7B1FA2);
}
