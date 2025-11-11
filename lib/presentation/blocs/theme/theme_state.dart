import 'package:flutter/material.dart';
import 'package:lotto_app/core/services/theme_service.dart';

class ThemeState {
  final ThemeMode themeMode;
  final AppColorScheme colorScheme;

  ThemeState({
    required this.themeMode,
    required this.colorScheme,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    AppColorScheme? colorScheme,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      colorScheme: colorScheme ?? this.colorScheme,
    );
  }
}
