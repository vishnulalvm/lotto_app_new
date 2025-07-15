import 'package:hive/hive.dart';
import 'package:lotto_app/data/models/results_screen/cached_result_details_model.dart';
import 'package:lotto_app/data/models/results_screen/results_screen.dart';
import 'package:lotto_app/core/errors/cache_exceptions.dart';

abstract class ResultDetailsCacheRepository {
  Future<CachedResultDetailsModel?> getCachedResultDetails(String uniqueId);
  Future<void> cacheResultDetails(String uniqueId, LotteryResultDetailsModel result);
  Future<void> clearCachedResultDetails(String uniqueId);
  Future<void> clearAllCachedResultDetails();
}

class ResultDetailsCacheRepositoryImpl implements ResultDetailsCacheRepository {
  static const String _boxName = 'result_details_cache';

  Future<Box<CachedResultDetailsModel>> get _box async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<CachedResultDetailsModel>(_boxName);
    }
    return Hive.box<CachedResultDetailsModel>(_boxName);
  }

  @override
  Future<CachedResultDetailsModel?> getCachedResultDetails(String uniqueId) async {
    try {
      final box = await _box;
      final cachedResult = box.get(uniqueId);
      
      if (cachedResult != null && cachedResult.isExpired) {
        // Remove expired cache
        await box.delete(uniqueId);
        return null;
      }
      
      return cachedResult;
    } catch (e) {
      throw CacheReadException('Failed to read cached result details: $e');
    }
  }

  @override
  Future<void> cacheResultDetails(String uniqueId, LotteryResultDetailsModel result) async {
    try {
      final box = await _box;
      final cachedResult = CachedResultDetailsModel.fromResultDetails(uniqueId, result);
      await box.put(uniqueId, cachedResult);
    } catch (e) {
      throw CacheWriteException('Failed to cache result details: $e');
    }
  }

  @override
  Future<void> clearCachedResultDetails(String uniqueId) async {
    try {
      final box = await _box;
      await box.delete(uniqueId);
    } catch (e) {
      throw CacheWriteException('Failed to clear cached result details: $e');
    }
  }

  @override
  Future<void> clearAllCachedResultDetails() async {
    try {
      final box = await _box;
      await box.clear();
    } catch (e) {
      throw CacheWriteException('Failed to clear all cached result details: $e');
    }
  }
}