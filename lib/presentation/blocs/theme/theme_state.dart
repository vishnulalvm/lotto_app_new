import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:lotto_app/core/services/theme_service.dart';

class ThemeState extends Equatable {
  final ThemeMode themeMode;
  final AppColorScheme colorScheme;

  const ThemeState({
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

  @override
  List<Object> get props => [themeMode, colorScheme];
}
