import 'dart:async';
import 'package:lotto_app/data/services/hive_service.dart';

class CacheManager {
  static const int _maxCacheSizeBytes = 50 * 1024 * 1024; // 50MB
  static const int _maxCacheAgeHours = 24 * 7; // 7 days
  static const int _cleanupIntervalMinutes = 60; // 1 hour

  static Timer? _cleanupTimer;

  /// Initialize cache management with periodic cleanup
  static void initialize() {
    // Start periodic cleanup
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: _cleanupIntervalMinutes),
      (_) => performMaintenance(),
    );
  }

  /// Stop cache management
  static void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }

  /// Perform cache maintenance (cleanup old data, manage size)
  static Future<void> performMaintenance() async {
    try {
      await _cleanupExpiredCache();
      await _manageCacheSize();
    } catch (e) {
      // Silently handle cache maintenance errors
    }
  }

  /// Clean up expired cache entries
  static Future<void> _cleanupExpiredCache() async {
    await HiveService.cleanupOldCache(maxAgeInDays: _maxCacheAgeHours ~/ 24);
  }

  /// Manage cache size to prevent excessive storage usage
  static Future<void> _manageCacheSize() async {
    if (HiveService.isCacheSizeExceeded(maxSizeInBytes: _maxCacheSizeBytes)) {
      // If cache is too large, clear older entries
      await _clearOldestCacheEntries();
    }
  }

  /// Clear oldest cache entries to free up space
  static Future<void> _clearOldestCacheEntries() async {
    // Clear entries older than 3 days first
    await HiveService.cleanupOldCache(maxAgeInDays: 3);
    
    // If still too large, clear entries older than 1 day
    if (HiveService.isCacheSizeExceeded(maxSizeInBytes: _maxCacheSizeBytes)) {
      await HiveService.cleanupOldCache(maxAgeInDays: 1);
    }
    
    // If still too large, clear all cache (last resort)
    if (HiveService.isCacheSizeExceeded(maxSizeInBytes: _maxCacheSizeBytes)) {
      await HiveService.clearAllCache();
    }
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    final sizeBytes = HiveService.getCacheSize();
    final sizeExceeded = HiveService.isCacheSizeExceeded(maxSizeInBytes: _maxCacheSizeBytes);
    
    return {
      'sizeBytes': sizeBytes,
      'sizeMB': (sizeBytes / (1024 * 1024)).toStringAsFixed(2),
      'maxSizeMB': (_maxCacheSizeBytes / (1024 * 1024)).round(),
      'sizeExceeded': sizeExceeded,
      'utilizationPercent': ((sizeBytes / _maxCacheSizeBytes) * 100).toStringAsFixed(1),
      'homeScreenEntries': HiveService.homeScreenBox.length,
      'userPreferencesEntries': HiveService.userPreferencesBox.length,
      'appMetadataEntries': HiveService.appMetadataBox.length,
    };
  }

  /// Clear all cache data
  static Future<void> clearAllCache() async {
    await HiveService.clearAllCache();
  }

  /// Check cache health
  static Future<Map<String, dynamic>> checkCacheHealth() async {
    final stats = getCacheStats();
    final now = DateTime.now();
    
    // Check for potential issues
    List<String> issues = [];
    List<String> warnings = [];
    
    if (stats['sizeExceeded'] == true) {
      issues.add('Cache size exceeded limit');
    }
    
    if (stats['homeScreenEntries'] == 0) {
      warnings.add('No home screen cache entries found');
    }
    
    final utilizationPercent = double.parse(stats['utilizationPercent']);
    if (utilizationPercent > 80) {
      warnings.add('Cache utilization is high (${stats['utilizationPercent']}%)');
    }
    
    return {
      ...stats,
      'lastChecked': now.toIso8601String(),
      'issues': issues,
      'warnings': warnings,
      'healthy': issues.isEmpty,
    };
  }

  /// Optimize cache (remove duplicates, compress data)
  static Future<void> optimizeCache() async {
    // For now, this just performs maintenance
    // In the future, we could add more sophisticated optimization
    await performMaintenance();
  }

  /// Export cache statistics for debugging
  static Future<Map<String, dynamic>> exportCacheInfo() async {
    final health = await checkCacheHealth();
    
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'health': health,
      'configuration': {
        'maxCacheSizeBytes': _maxCacheSizeBytes,
        'maxCacheAgeHours': _maxCacheAgeHours,
        'cleanupIntervalMinutes': _cleanupIntervalMinutes,
      },
    };
  }
}