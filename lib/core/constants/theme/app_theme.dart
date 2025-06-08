import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        primaryColor: Colors.red,
        scaffoldBackgroundColor: const Color(0xFFFFF1F2),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87, fontSize: 16),
          bodyMedium: TextStyle(color: Colors.black87, fontSize: 14),
          titleLarge: TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(
              color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFF1F2),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          actionsIconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            fontSize: 24,
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Corrected: Use CardThemeData instead of CardTheme
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.grey[400],
        ),
        iconTheme: const IconThemeData(
          color: Colors.black87,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor:
            const Color(0xFFFF5252), // Vibrant red (Material Red A200)
        // Rich dark background with subtle red warmth - vibrant but comfortable
        scaffoldBackgroundColor:
            const Color(0xFF121212), // Material Design dark surface
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
              color: Colors.white, fontSize: 16), // Pure white for vibrancy
          bodyMedium:
              TextStyle(color: Color(0xFFE0E0E0), fontSize: 14), // Light grey
          titleLarge: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold), // Pure white
          titleMedium: TextStyle(
              color: Color(0xFFE0E0E0),
              fontSize: 16,
              fontWeight: FontWeight.w500), // Light grey
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212), // Same as scaffold background
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          actionsIconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            fontSize: 24,
            color: Color(0xFFFF5252), // Vibrant red
            fontWeight: FontWeight.bold,
          ),
        ),
        // Corrected: Use CardThemeData instead of CardTheme
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E), // Rich dark grey cards
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF424242), // Medium grey for good contrast
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFFE0E0E0), // Light grey for icons
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFFF5252), // Vibrant red
          foregroundColor: Colors.white,
        ),
      );
}
