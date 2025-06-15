import 'package:flutter/material.dart' as material;
import 'package:lotto_app/data/services/theme_service.dart';

class ThemeState {
  final ThemeMode themeMode;
  final material.ThemeMode materialThemeMode;

  ThemeState({
    required this.themeMode,
    required this.materialThemeMode,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    material.ThemeMode? materialThemeMode,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      materialThemeMode: materialThemeMode ?? this.materialThemeMode,
    );
  }

  // Convert custom ThemeMode to Material ThemeMode
  static material.ThemeMode _convertToMaterialThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return material.ThemeMode.light;
      case ThemeMode.dark:
        return material.ThemeMode.dark;
      case ThemeMode.system:
        return material.ThemeMode.system;
    }
  }

  factory ThemeState.initial() {
    return ThemeState(
      themeMode: ThemeMode.system,
      materialThemeMode: material.ThemeMode.system,
    );
  }

  factory ThemeState.fromThemeMode(ThemeMode themeMode) {
    return ThemeState(
      themeMode: themeMode,
      materialThemeMode: _convertToMaterialThemeMode(themeMode),
    );
  }
}