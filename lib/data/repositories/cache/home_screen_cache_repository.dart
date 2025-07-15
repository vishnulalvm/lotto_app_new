import 'package:lotto_app/data/models/home_screen/home_screen_model.dart';
import 'package:lotto_app/data/models/home_screen/cached_home_screen_model.dart';
import 'package:lotto_app/data/services/hive_service.dart';
import 'package:lotto_app/core/errors/cache_exceptions.dart';
import 'package:hive/hive.dart';

abstract class HomeScreenCacheRepository {
  Future<HomeScreenResultsModel?> getCachedHomeScreenResults();
  Future<void> cacheHomeScreenResults(HomeScreenResultsModel results);
  Future<void> clearCache();
  Future<bool> isCacheValid();
  Future<bool> isCacheFresh();
  Future<int> getCacheAge();
}

class HomeScreenCacheRepositoryImpl implements HomeScreenCacheRepository {
  static const String _cacheKey = 'home_screen_results';

  @override
  Future<HomeScreenResultsModel?> getCachedHomeScreenResults() async {
    try {
      final cachedData = HiveService.homeScreenBox.get(_cacheKey);
      
      if (cachedData == null) {
        return null;
      }

      // Return the API model converted from cached data
      return cachedData.toApiModel();
    } on HiveError catch (e) {
      throw CacheReadException('Failed to read home screen cache from Hive', e);
    } catch (e) {
      // For any other errors (e.g., data corruption), wrap in cache exception
      if (e.toString().contains('corrupt') || e.toString().contains('invalid')) {
        throw CacheCorruptedException('Home screen cache data is corrupted', e);
      }
      throw CacheReadException('Unexpected error reading home screen cache', e);
    }
  }

  @override
  Future<void> cacheHomeScreenResults(HomeScreenResultsModel results) async {
    try {
      // Check if Hive is properly initialized
      if (!HiveService.homeScreenBox.isOpen) {
        throw CacheWriteException('Hive box is not open for writing');
      }

      final cachedModel = CachedHomeScreenModel.fromApiModel(results);
      
      await HiveService.homeScreenBox.put(_cacheKey, cachedModel);
      
    } on HiveError catch (e) {
      if (e.toString().contains('disk full') || e.toString().contains('no space')) {
        throw CacheStorageFullException('No space left to cache home screen results', e);
      }
      throw CacheWriteException('Failed to write home screen cache to Hive', e);
    } catch (e) {
      throw CacheWriteException('Unexpected error caching home screen results: ${e.toString()}', e);
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await HiveService.homeScreenBox.delete(_cacheKey);
    } on HiveError catch (e) {
      throw CacheDeleteException('Failed to delete home screen cache from Hive', e);
    } catch (e) {
      throw CacheDeleteException('Unexpected error clearing home screen cache', e);
    }
  }

  @override
  Future<bool> isCacheValid() async {
    try {
      final cachedData = HiveService.homeScreenBox.get(_cacheKey);
      
      if (cachedData == null) {
        return false;
      }

      return !cachedData.isExpired;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isCacheFresh() async {
    try {
      final cachedData = HiveService.homeScreenBox.get(_cacheKey);
      
      if (cachedData == null) {
        return false;
      }

      return cachedData.isFresh;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int> getCacheAge() async {
    try {
      final cachedData = HiveService.homeScreenBox.get(_cacheKey);
      
      if (cachedData == null) {
        return -1; // No cache
      }

      return cachedData.cacheAgeInMinutes;
    } catch (e) {
      return -1;
    }
  }

  /// Get cache metadata for debugging/monitoring
  Future<Map<String, dynamic>> getCacheMetadata() async {
    try {
      final cachedData = HiveService.homeScreenBox.get(_cacheKey);
      
      if (cachedData == null) {
        return {
          'exists': false,
          'cacheTime': null,
          'ageInMinutes': -1,
          'isExpired': true,
          'isFresh': false,
          'resultCount': 0,
        };
      }

      return {
        'exists': true,
        'cacheTime': cachedData.cacheTime.toIso8601String(),
        'ageInMinutes': cachedData.cacheAgeInMinutes,
        'isExpired': cachedData.isExpired,
        'isFresh': cachedData.isFresh,
        'resultCount': cachedData.results.length,
      };
    } catch (e) {
      return {
        'exists': false,
        'error': e.toString(),
      };
    }
  }
}