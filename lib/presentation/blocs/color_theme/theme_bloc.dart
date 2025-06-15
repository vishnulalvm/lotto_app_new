import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotto_app/data/services/theme_service.dart';
import 'package:lotto_app/presentation/blocs/color_theme/theme_event.dart';
import 'package:lotto_app/presentation/blocs/color_theme/theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final ThemeService themeService;

  ThemeBloc({required this.themeService}) : super(ThemeState.initial()) {
    on<ThemeInitialized>(_onThemeInitialized);
    on<ThemeChanged>(_onThemeChanged);
  }

  Future<void> _onThemeInitialized(
    ThemeInitialized event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      final savedThemeMode = await themeService.getThemeMode();
      emit(ThemeState.fromThemeMode(savedThemeMode));
    } catch (e) {
      // If there's an error, use system default
      emit(ThemeState.initial());
    }
  }

  Future<void> _onThemeChanged(
    ThemeChanged event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      await themeService.saveThemeMode(event.themeMode);
      emit(ThemeState.fromThemeMode(event.themeMode));
    } catch (e) {
      // If saving fails, still update the UI but don't persist
      emit(ThemeState.fromThemeMode(event.themeMode));
    }
  }
}
