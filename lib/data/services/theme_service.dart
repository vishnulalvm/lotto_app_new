import 'package:shared_preferences/shared_preferences.dart';

enum ThemeMode { light, dark, system }

class ThemeService {
  static const String _themeModeKey = 'theme_mode';

  // Save theme mode
  Future<void> saveThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, themeMode.name);
  }

  // Get saved theme mode
  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString(_themeModeKey);
    
    if (themeModeString != null) {
      switch (themeModeString) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
        case 'system':
          return ThemeMode.system;
        default:
          return ThemeMode.system;
      }
    }
    return ThemeMode.system; // Default to system
  }

  // Clear theme mode (reset to system)
  Future<void> clearThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeModeKey);
  }
}
