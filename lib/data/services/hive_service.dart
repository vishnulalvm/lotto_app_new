import 'package:hive_flutter/hive_flutter.dart';
import 'package:lotto_app/data/models/home_screen/cached_home_screen_model.dart';
import 'package:lotto_app/data/models/results_screen/cached_result_details_model.dart';
import 'package:lotto_app/data/models/results_screen/save_result.dart';
import 'package:lotto_app/data/models/predict_screen/ai_prediction_model.dart';

class HiveService {
  static const String _homeScreenBoxName = 'home_screen_cache';
  static const String _userPreferencesBoxName = 'user_preferences';
  static const String _appMetadataBoxName = 'app_metadata';
  
  static late Box<CachedHomeScreenModel> _homeScreenBox;
  static late Box<dynamic> _userPreferencesBox;
  static late Box<dynamic> _appMetadataBox;

  /// Initialize Hive database
  static Future<void> init() async {
    try {
      // Initialize Hive
      await Hive.initFlutter();
      
      // Register adapters (check if already registered to avoid conflicts)
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(CachedHomeScreenModelAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(CachedHomeScreenResultModelAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(CachedFirstPrizeModelAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(CachedConsolationPrizesModelAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(CachedUpdatesModelAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(CachedResultDetailsModelAdapter());
      }
      if (!Hive.isAdapterRegistered(6)) {
        Hive.registerAdapter(SavedLotteryResultAdapter());
      }
      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(AiPredictionModelAdapter());
      }
      
      // Try to open boxes with error handling for schema changes
      try {
        _homeScreenBox = await Hive.openBox<CachedHomeScreenModel>(_homeScreenBoxName);
        _userPreferencesBox = await Hive.openBox(_userPreferencesBoxName);
        _appMetadataBox = await Hive.openBox(_appMetadataBoxName);
      } catch (e) {
        // Clear existing boxes if there's a schema mismatch
        await Hive.deleteBoxFromDisk(_homeScreenBoxName);
        await Hive.deleteBoxFromDisk(_userPreferencesBoxName);
        await Hive.deleteBoxFromDisk(_appMetadataBoxName);
        
        // Reopen boxes with fresh schema
        _homeScreenBox = await Hive.openBox<CachedHomeScreenModel>(_homeScreenBoxName);
        _userPreferencesBox = await Hive.openBox(_userPreferencesBoxName);
        _appMetadataBox = await Hive.openBox(_appMetadataBoxName);
      }
      
    } catch (e) {
      rethrow;
    }
  }

  /// Get home screen cache box
  static Box<CachedHomeScreenModel> get homeScreenBox => _homeScreenBox;

  /// Get user preferences box
  static Box<dynamic> get userPreferencesBox => _userPreferencesBox;

  /// Get app metadata box
  static Box<dynamic> get appMetadataBox => _appMetadataBox;

  /// Close all boxes
  static Future<void> close() async {
    await _homeScreenBox.close();
    await _userPreferencesBox.close();
    await _appMetadataBox.close();
  }

  /// Clear all cache data
  static Future<void> clearAllCache() async {
    await _homeScreenBox.clear();
    await _userPreferencesBox.clear();
    await _appMetadataBox.clear();
  }

  /// Get cache size in bytes
  static int getCacheSize() {
    int totalSize = 0;
    
    // Calculate approximate size
    totalSize += _homeScreenBox.length * 2048; // Approximate 2KB per entry
    totalSize += _userPreferencesBox.length * 512; // Approximate 512B per entry
    totalSize += _appMetadataBox.length * 256; // Approximate 256B per entry
    
    return totalSize;
  }

  /// Check if cache size exceeds limit (default 50MB)
  static bool isCacheSizeExceeded({int maxSizeInBytes = 50 * 1024 * 1024}) {
    return getCacheSize() > maxSizeInBytes;
  }

  /// Clean up old cache entries
  static Future<void> cleanupOldCache({int maxAgeInDays = 7}) async {
    final cutoffTime = DateTime.now().subtract(Duration(days: maxAgeInDays));
    
    // Clean home screen cache
    final keysToDelete = <String>[];
    for (final key in _homeScreenBox.keys) {
      final cachedData = _homeScreenBox.get(key);
      if (cachedData != null && cachedData.cacheTime.isBefore(cutoffTime)) {
        keysToDelete.add(key.toString());
      }
    }
    
    for (final key in keysToDelete) {
      await _homeScreenBox.delete(key);
    }
  }
}