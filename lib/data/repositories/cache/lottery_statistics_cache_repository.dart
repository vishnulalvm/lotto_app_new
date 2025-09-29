import 'package:lotto_app/data/models/lottery_statistics/lottery_statistics_response_model.dart';
import 'package:lotto_app/data/models/lottery_statistics/cached_lottery_statistics_model.dart';
import 'package:lotto_app/data/services/hive_service.dart';
import 'package:lotto_app/core/errors/cache_exceptions.dart';
import 'package:hive/hive.dart';

abstract class LotteryStatisticsCacheRepository {
  Future<LotteryStatisticsResponseModel?> getCachedLotteryStatistics();
  Future<void> cacheLotteryStatistics(LotteryStatisticsResponseModel statistics);
  Future<void> clearCache();
  Future<bool> isCacheValid();
  Future<bool> isCacheFresh();
  Future<int> getCacheAge();
}

class LotteryStatisticsCacheRepositoryImpl implements LotteryStatisticsCacheRepository {
  static const String _cacheKey = 'lottery_statistics';

  @override
  Future<LotteryStatisticsResponseModel?> getCachedLotteryStatistics() async {
    try {
      final cachedData = HiveService.lotteryStatisticsBox.get(_cacheKey);
      
      if (cachedData == null) {
        return null;
      }

      // Return the API model converted from cached data
      return cachedData.toApiModel();
    } on HiveError catch (e) {
      throw CacheReadException('Failed to read lottery statistics cache from Hive', e);
    } catch (e) {
      // For any other errors (e.g., data corruption), wrap in cache exception
      if (e.toString().contains('corrupt') || e.toString().contains('invalid')) {
        throw CacheCorruptedException('Lottery statistics cache data is corrupted', e);
      }
      throw CacheReadException('Unexpected error reading lottery statistics cache', e);
    }
  }

  @override
  Future<void> cacheLotteryStatistics(LotteryStatisticsResponseModel statistics) async {
    try {
      // Check if Hive is properly initialized
      if (!HiveService.lotteryStatisticsBox.isOpen) {
        throw CacheWriteException('Hive box is not open for writing');
      }

      final cachedModel = CachedLotteryStatisticsModel.fromApiModel(statistics);
      
      // Check available storage before writing (basic size check)
      final boxSize = HiveService.lotteryStatisticsBox.length;
      const maxBoxSize = 1000; // Reasonable limit for lottery statistics cache
      
      if (boxSize >= maxBoxSize) {
        throw CacheStorageFullException('Lottery statistics cache storage is full');
      }

      await HiveService.lotteryStatisticsBox.put(_cacheKey, cachedModel);
    } on HiveError catch (e) {
      throw CacheWriteException('Failed to write lottery statistics cache to Hive', e);
    } catch (e) {
      if (e is CacheStorageFullException) {
        rethrow;
      }
      throw CacheWriteException('Unexpected error writing lottery statistics cache', e);
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await HiveService.lotteryStatisticsBox.clear();
    } on HiveError catch (e) {
      throw CacheWriteException('Failed to clear lottery statistics cache', e);
    } catch (e) {
      throw CacheWriteException('Unexpected error clearing lottery statistics cache', e);
    }
  }

  @override
  Future<bool> isCacheValid() async {
    try {
      final cachedData = HiveService.lotteryStatisticsBox.get(_cacheKey);
      return cachedData != null && !cachedData.isExpired;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isCacheFresh() async {
    try {
      final cachedData = HiveService.lotteryStatisticsBox.get(_cacheKey);
      return cachedData != null && cachedData.isFresh;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int> getCacheAge() async {
    try {
      final cachedData = HiveService.lotteryStatisticsBox.get(_cacheKey);
      return cachedData?.cacheAgeInMinutes ?? -1;
    } catch (e) {
      return -1;
    }
  }
}