import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

enum AppColorScheme {
  blue,
  scarlet,
  green,
  tigerOrange,
  caramel,
  ocean,
  purple,
  cyan,
}

class ThemeService {
  static const String _themeModeKey = 'theme_mode';
  static const String _colorSchemeKey = 'color_scheme';

  /// Save theme mode (system, light, dark)
  Future<void> saveThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, themeMode.name);
  }

  /// Load theme mode
  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString(_themeModeKey);

    if (themeModeString == null) {
      return ThemeMode.system; // Default
    }

    return ThemeMode.values.firstWhere(
      (mode) => mode.name == themeModeString,
      orElse: () => ThemeMode.system,
    );
  }

  /// Save color scheme
  Future<void> saveColorScheme(AppColorScheme colorScheme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_colorSchemeKey, colorScheme.name);
  }

  /// Load color scheme
  Future<AppColorScheme> loadColorScheme() async {
    final prefs = await SharedPreferences.getInstance();
    final colorSchemeString = prefs.getString(_colorSchemeKey);

    if (colorSchemeString == null) {
      return AppColorScheme.scarlet; // Default to crimsonRed
    }

    return AppColorScheme.values.firstWhere(
      (scheme) => scheme.name == colorSchemeString,
      orElse: () => AppColorScheme.scarlet,
    );
  }

  /// Load all theme settings
  Future<ThemeSettings> loadThemeSettings() async {
    final themeMode = await loadThemeMode();
    final colorScheme = await loadColorScheme();

    return ThemeSettings(
      themeMode: themeMode,
      colorScheme: colorScheme,
    );
  }

  /// Save all theme settings
  Future<void> saveThemeSettings(ThemeSettings settings) async {
    await Future.wait([
      saveThemeMode(settings.themeMode),
      saveColorScheme(settings.colorScheme),
    ]);
  }
}

class ThemeSettings {
  final ThemeMode themeMode;
  final AppColorScheme colorScheme;

  ThemeSettings({
    required this.themeMode,
    required this.colorScheme,
  });

  ThemeSettings copyWith({
    ThemeMode? themeMode,
    AppColorScheme? colorScheme,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      colorScheme: colorScheme ?? this.colorScheme,
    );
  }
}
