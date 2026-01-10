import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for persisting lottery draw state
class LotteryDrawStorageService {
  static const String _stateKey = 'lottery_draw_last_state';

  // Singleton with cached prefs
  static LotteryDrawStorageService? _instance;
  static SharedPreferences? _prefs;

  factory LotteryDrawStorageService() {
    _instance ??= LotteryDrawStorageService._internal();
    return _instance!;
  }

  LotteryDrawStorageService._internal();

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Save the lottery draw state
  Future<void> saveDrawState(Map<String, dynamic> stateJson) async {
    final prefs = await _getPrefs();
    final encoded = json.encode(stateJson);
    await prefs.setString(_stateKey, encoded);
  }

  /// Load the lottery draw state
  Future<Map<String, dynamic>?> loadDrawState() async {
    final prefs = await _getPrefs();
    final stateString = prefs.getString(_stateKey);

    if (stateString == null || stateString.isEmpty) {
      return null;
    }

    try {
      return json.decode(stateString) as Map<String, dynamic>;
    } catch (e) {
      // Corrupted data - clear it
      await prefs.remove(_stateKey);
      return null;
    }
  }

  /// Clear saved state
  Future<void> clearDrawState() async {
    final prefs = await _getPrefs();
    await prefs.remove(_stateKey);
  }
}