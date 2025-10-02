import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lotto_app/data/models/predict_screen/predict_response_model.dart';

class PredictCacheService {
  static const String _cacheKey = 'predict_data_cache';
  static const String _timestampKey = 'predict_data_timestamp';
  static const Duration _cacheExpiry = Duration(hours: 24);

  /// Save prediction data to cache
  Future<void> cachePredictionData(PredictResponseModel data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(data.toJson());
      await prefs.setString(_cacheKey, jsonString);
      await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Silent fail - cache is not critical
    }
  }

  /// Get cached prediction data if valid
  Future<PredictResponseModel?> getCachedPredictionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      final timestamp = prefs.getInt(_timestampKey);

      if (jsonString == null || timestamp == null) {
        return null;
      }

      // Check if cache is expired
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(cacheTime);

      if (difference > _cacheExpiry) {
        // Cache expired, clear it
        await clearCache();
        return null;
      }

      // Parse and return cached data
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      return PredictResponseModel.fromJson(jsonData);
    } catch (e) {
      // If there's any error reading cache, clear it and return null
      await clearCache();
      return null;
    }
  }

  /// Check if cache exists and is valid
  Future<bool> isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_timestampKey);

      if (timestamp == null) {
        return false;
      }

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(cacheTime);

      return difference <= _cacheExpiry;
    } catch (e) {
      return false;
    }
  }

  /// Clear cached prediction data
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_timestampKey);
    } catch (e) {
      // Silent fail
    }
  }

  /// Get cache age in minutes
  Future<int?> getCacheAgeInMinutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_timestampKey);

      if (timestamp == null) {
        return null;
      }

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(cacheTime);

      return difference.inMinutes;
    } catch (e) {
      return null;
    }
  }
}
