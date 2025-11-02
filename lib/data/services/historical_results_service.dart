import 'package:hive/hive.dart';
import 'package:lotto_app/data/models/results_screen/results_screen.dart';
import 'package:lotto_app/data/models/results_screen/cached_result_details_model.dart';

/// Service to fetch historical lottery results for pattern analysis
class HistoricalResultsService {
  static const String _cacheBoxName = 'result_details_cache';
  static const String _lastCleanupKey = 'last_weekly_cleanup';
  static const int _daysToKeep = 7;

  /// Fetches historical lottery results from cache for pattern analysis
  /// Only returns results from the last 7 days
  static Future<List<LotteryResultModel>> getHistoricalResults({int limit = 50}) async {
    try {
      // Open or get the result details cache box
      Box<CachedResultDetailsModel> box;
      if (!Hive.isBoxOpen(_cacheBoxName)) {
        box = await Hive.openBox<CachedResultDetailsModel>(_cacheBoxName);
      } else {
        box = Hive.box<CachedResultDetailsModel>(_cacheBoxName);
      }

      // Perform weekly cleanup if needed
      await _performWeeklyCleanup(box);

      // Calculate cutoff date (7 days ago)
      final now = DateTime.now();
      final cutoffDate = now.subtract(const Duration(days: _daysToKeep));

      // Get cached results from last 7 days only
      final cachedResults = <LotteryResultModel>[];

      for (var key in box.keys) {
        if (key == _lastCleanupKey) continue; // Skip cleanup metadata key

        try {
          final cachedData = box.get(key);

          if (cachedData != null && !cachedData.isExpired) {
            final resultDetails = cachedData.toResultDetails();

            // Parse result date and check if it's within last 7 days
            try {
              final resultDate = DateTime.parse(resultDetails.result.date);

              if (resultDate.isAfter(cutoffDate) && resultDetails.result.isPublished) {
                cachedResults.add(resultDetails.result);
              }
            } catch (e) {
              // Error parsing date for result, skip this entry
            }
          }
        } catch (e) {
          // Error parsing cached result, skip this entry
        }
      }

      // Sort by date (newest first) and limit
      cachedResults.sort((a, b) => b.date.compareTo(a.date));
      final limitedResults = cachedResults.take(limit).toList();

      return limitedResults;
    } catch (e) {
      // Error fetching historical results from cache
      return [];
    }
  }

  /// Performs weekly cleanup of old cached data
  static Future<void> _performWeeklyCleanup(Box<CachedResultDetailsModel> box) async {
    try {
      // Check last cleanup time
      final lastCleanup = box.get(_lastCleanupKey);
      final now = DateTime.now();

      bool shouldCleanup = false;

      if (lastCleanup == null) {
        // Never cleaned up before
        shouldCleanup = true;
      } else {
        // Check if it's been more than 7 days since last cleanup
        final daysSinceCleanup = now.difference(lastCleanup.cachedAt).inDays;
        shouldCleanup = daysSinceCleanup >= _daysToKeep;
      }

      if (shouldCleanup) {
        final cutoffDate = now.subtract(const Duration(days: _daysToKeep));

        final keysToDelete = <dynamic>[];

        for (var key in box.keys) {
          if (key == _lastCleanupKey) continue;

          try {
            final cachedData = box.get(key);
            if (cachedData != null) {
              final resultDetails = cachedData.toResultDetails();
              final resultDate = DateTime.parse(resultDetails.result.date);

              // Delete if older than 7 days
              if (resultDate.isBefore(cutoffDate)) {
                keysToDelete.add(key);
              }
            }
          } catch (e) {
            // If we can't parse it, mark for deletion
            keysToDelete.add(key);
          }
        }

        // Delete old entries
        for (var key in keysToDelete) {
          await box.delete(key);
        }

        // Store cleanup timestamp
        await box.put(
          _lastCleanupKey,
          CachedResultDetailsModel(
            uniqueId: _lastCleanupKey,
            data: {'last_cleanup': now.toIso8601String()},
            cachedAt: now,
            expiresAt: now.add(const Duration(days: 365)), // Never expires
          ),
        );
      }
    } catch (e) {
      // Error during weekly cleanup
    }
  }

  /// Manually trigger cache cleanup (for testing or manual reset)
  static Future<void> clearOldCache() async {
    try {
      Box<CachedResultDetailsModel> box;
      if (!Hive.isBoxOpen(_cacheBoxName)) {
        box = await Hive.openBox<CachedResultDetailsModel>(_cacheBoxName);
      } else {
        box = Hive.box<CachedResultDetailsModel>(_cacheBoxName);
      }

      // Force cleanup by removing last cleanup timestamp
      await box.delete(_lastCleanupKey);
      await _performWeeklyCleanup(box);
    } catch (e) {
      // Error during manual cleanup
    }
  }
}
