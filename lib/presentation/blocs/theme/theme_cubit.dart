import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotto_app/core/services/theme_service.dart';
import 'package:lotto_app/presentation/blocs/theme/theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  final ThemeService _themeService;

  ThemeCubit(this._themeService)
      : super(const ThemeState(
          themeMode: ThemeMode.system,
          colorScheme: AppColorScheme.scarlet, // Default to crimsonRed
        )) {
    _loadThemeSettings();
  }

  /// Load saved theme settings from storage
  Future<void> _loadThemeSettings() async {
    try {
      final settings = await _themeService.loadThemeSettings();
      emit(const ThemeState(
        themeMode: ThemeMode.system,
        colorScheme: AppColorScheme.scarlet,
      ).copyWith(
        themeMode: settings.themeMode,
        colorScheme: settings.colorScheme,
      ));
    } catch (e) {
      // If loading fails, use defaults (already set in initial state)
    }
  }

  /// Change theme mode (system, light, dark)
  Future<void> changeThemeMode(ThemeMode themeMode) async {
    emit(state.copyWith(themeMode: themeMode));
    await _themeService.saveThemeMode(themeMode);
  }

  /// Change color scheme
  Future<void> changeColorScheme(AppColorScheme colorScheme) async {
    emit(state.copyWith(colorScheme: colorScheme));
    await _themeService.saveColorScheme(colorScheme);
  }

  /// Update all theme settings at once
  Future<void> updateThemeSettings({
    ThemeMode? themeMode,
    AppColorScheme? colorScheme,
  }) async {
    emit(state.copyWith(
      themeMode: themeMode,
      colorScheme: colorScheme,
    ));

    await _themeService.saveThemeSettings(
      ThemeSettings(
        themeMode: state.themeMode,
        colorScheme: state.colorScheme,
      ),
    );
  }
}
