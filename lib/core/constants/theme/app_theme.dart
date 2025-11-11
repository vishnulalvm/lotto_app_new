import 'package:flutter/material.dart';
import 'package:lotto_app/core/services/theme_service.dart';

class AppTheme {
  // Custom Red color constant (default)
  static const Color crimsonRed = Color(0xFFEF5458); // #EF5458

  // Color scheme mapping
  static Color getColorFromScheme(AppColorScheme scheme) {
    switch (scheme) {
      case AppColorScheme.blue:
        return const Color(0xFF1565C0);
      case AppColorScheme.scarlet:
        return crimsonRed; // Use crimsonRed for scarlet
      case AppColorScheme.green:
        return const Color(0xFF2E7D32);
      case AppColorScheme.tigerOrange:
        return const Color(0xFFE65100);
      case AppColorScheme.caramel:
        return const Color(0xFFB67233);
      case AppColorScheme.ocean:
        return const Color(0xFF075E54);
      case AppColorScheme.purple:
        return const Color(0xFF7B1FA2);
      case AppColorScheme.cyan:
        return const Color(0xFF546E7A);
    }
  }

  static ThemeData lightTheme(AppColorScheme colorScheme) {
    final primaryColor = getColorFromScheme(colorScheme);
    // Create a light tinted background based on the primary color
    final scaffoldColor = Color.alphaBlend(
      primaryColor.withValues(alpha: 0.05),
      Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      disabledColor: Colors.grey[300]!,
      scaffoldBackgroundColor: scaffoldColor,
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black87, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.black87, fontSize: 14),
        bodySmall: TextStyle(color: Colors.black54, fontSize: 12),
        titleLarge: TextStyle(
            color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(
            color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(
            color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
        headlineLarge: TextStyle(
            color: Colors.black87, fontSize: 32, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(
            color: Colors.black87, fontSize: 28, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(
            color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold),
        labelLarge: TextStyle(color: Colors.black87, fontSize: 14),
        labelMedium: TextStyle(color: Colors.black87, fontSize: 12),
        labelSmall: TextStyle(color: Colors.black54, fontSize: 11),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actionsIconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(
          fontSize: 24,
          color: primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: Colors.black54,
        indicatorColor: primaryColor,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey[400],
      ),
      iconTheme: const IconThemeData(
        color: Colors.black87,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: primaryColor,
        surface: Colors.white,
        error: primaryColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black87,
        onError: Colors.white,
      ),
    );
  }

  static ThemeData darkTheme(AppColorScheme colorScheme) {
    final primaryColor = getColorFromScheme(colorScheme);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      disabledColor: const Color(0xFF424242),
      scaffoldBackgroundColor: const Color(0xFF121212),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF1E1E1E),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
        bodyMedium: TextStyle(color: Color(0xFFE0E0E0), fontSize: 14),
        bodySmall: TextStyle(color: Color(0xFFBDBDBD), fontSize: 12),
        titleLarge: TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(
            color: Color(0xFFE0E0E0),
            fontSize: 16,
            fontWeight: FontWeight.w500),
        titleSmall: TextStyle(
            color: Color(0xFFE0E0E0),
            fontSize: 14,
            fontWeight: FontWeight.w500),
        headlineLarge: TextStyle(
            color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(
            color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(
            color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        labelLarge: TextStyle(color: Color(0xFFE0E0E0), fontSize: 14),
        labelMedium: TextStyle(color: Color(0xFFE0E0E0), fontSize: 12),
        labelSmall: TextStyle(color: Color(0xFFBDBDBD), fontSize: 11),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontSize: 24,
          color: primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: const Color(0xFFBDBDBD),
        indicatorColor: primaryColor,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF424242),
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFFE0E0E0),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryColor,
        surface: const Color(0xFF1E1E1E),
        error: primaryColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
    );
  }
}
