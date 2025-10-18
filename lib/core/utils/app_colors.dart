import 'package:flutter/material.dart';

class AppColors {
  // Primary color - Custom Red (same for both themes)
  static const primary = Color(0xFFFA5053); // #FA5053

  // Light theme colors
  static const lightBackground = Color(0xFFFFF1F2);
  static const lightCardBackground = Colors.white;
  static const lightIconColor = Colors.black87;
  static const lightTextPrimary = Colors.black87;
  static const lightTextSecondary = Colors.black54;

  // Dark theme colors
  static const darkBackground = Color(0xFF121212);
  static const darkCardBackground = Color(0xFF1E1E1E);
  static const darkIconColor = Color(0xFFE0E0E0);
  static const darkTextPrimary = Colors.white;
  static const darkTextSecondary = Color(0xFFBDBDBD);

  // Helper methods to get colors based on theme
  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextPrimary
        : lightTextPrimary;
  }

  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextSecondary
        : lightTextSecondary;
  }

  static Color getIconColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkIconColor
        : lightIconColor;
  }

  static Color getCardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCardBackground
        : lightCardBackground;
  }

  static Color getBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : lightBackground;
  }
}
