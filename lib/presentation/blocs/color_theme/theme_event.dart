import 'package:lotto_app/data/services/theme_service.dart';

abstract class ThemeEvent {}

class ThemeChanged extends ThemeEvent {
  final ThemeMode themeMode;
  ThemeChanged(this.themeMode);
}

class ThemeInitialized extends ThemeEvent {}
