import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: const Color.fromARGB(255, 200, 12, 12),
        disabledColor: Colors.grey[300]!,
        scaffoldBackgroundColor: const Color(0xFFFFF1F2),
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
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFF1F2),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black87),
          actionsIconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            fontSize: 24,
            color: Color.fromARGB(255, 200, 12, 12),
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
        tabBarTheme: const TabBarThemeData(
          labelColor: Color.fromARGB(255, 200, 12, 12),
          unselectedLabelColor: Colors.black54,
          indicatorColor: Color.fromARGB(255, 200, 12, 12),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.grey[400],
        ),
        iconTheme: const IconThemeData(
          color: Colors.black87,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color.fromARGB(255, 200, 12, 12),
          foregroundColor: Colors.white,
        ),
        colorScheme: const ColorScheme.light(
          primary: Color.fromARGB(255, 200, 12, 12),
          secondary: Color.fromARGB(255, 200, 12, 12),
          surface: Colors.white,
          error: Colors.red,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.black87,
          onError: Colors.white,
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: const Color.fromARGB(255, 200, 12, 12),
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
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          actionsIconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            fontSize: 24,
            color: Color.fromARGB(255, 200, 12, 12),
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
        tabBarTheme: const TabBarThemeData(
          labelColor: Color.fromARGB(255, 200, 12, 12),
          unselectedLabelColor: Color(0xFFBDBDBD),
          indicatorColor: Color.fromARGB(255, 200, 12, 12),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF424242),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFFE0E0E0),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color.fromARGB(255, 200, 12, 12),
          foregroundColor: Colors.white,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color.fromARGB(255, 200, 12, 12),
          secondary: Color.fromARGB(255, 200, 12, 12),
          surface: Color(0xFF1E1E1E),
          error: Color(0xFFCF6679),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
          onError: Colors.black,
        ),
      );
}
