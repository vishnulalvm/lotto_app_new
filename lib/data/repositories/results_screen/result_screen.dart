import 'package:lotto_app/data/datasource/api/results_screen/results_screen.dart';
import 'package:lotto_app/data/models/results_screen/results_screen.dart';
import 'package:lotto_app/data/repositories/cache/result_details_cache_repository.dart';
import 'package:lotto_app/data/services/connectivity_service.dart';

class LotteryResultDetailsRepository {
  final LotteryResultDetailsApiService _apiService;
  final ResultDetailsCacheRepository _cacheRepository;
  final ConnectivityService _connectivityService;

  LotteryResultDetailsRepository(
    this._apiService,
    this._cacheRepository,
    this._connectivityService,
  );

  Future<LotteryResultDetailsModel> getLotteryResultDetails(
    String uniqueId, {
    bool forceRefresh = false,
  }) async {
    try {
      final isConnected = _connectivityService.isConnected;
      
      // Try to get from cache first (if not forcing refresh)
      if (!forceRefresh) {
        final cachedResult = await _cacheRepository.getCachedResultDetails(uniqueId);
        if (cachedResult != null) {
          // Return cached data immediately
          final result = cachedResult.toResultDetails();
          
          // If connected and cache should be refreshed, refresh in background
          if (isConnected && cachedResult.shouldRefreshInLiveHours) {
            _refreshInBackground(uniqueId);
          }
          
          return result;
        }
      }
      
      // If not connected and no cache, throw error
      if (!isConnected) {
        throw Exception('No internet connection and no cached data available');
      }
      
      // Fetch from API
      final json = await _apiService.getLotteryResultDetails(uniqueId);
      final result = LotteryResultDetailsModel.fromJson(json);
      
      // Cache the result
      await _cacheRepository.cacheResultDetails(uniqueId, result);
      
      return result;
    } catch (e) {
      // If API fails, try to return cached data
      final cachedResult = await _cacheRepository.getCachedResultDetails(uniqueId);
      if (cachedResult != null) {
        return cachedResult.toResultDetails();
      }
      
      throw Exception('Repository error: $e');
    }
  }

  Future<void> _refreshInBackground(String uniqueId) async {
    try {
      final json = await _apiService.getLotteryResultDetails(uniqueId);
      final result = LotteryResultDetailsModel.fromJson(json);
      await _cacheRepository.cacheResultDetails(uniqueId, result);
    } catch (e) {
      // Silently fail for background refresh
    }
  }

  Future<void> clearCache(String uniqueId) async {
    await _cacheRepository.clearCachedResultDetails(uniqueId);
  }

  Future<void> clearAllCache() async {
    await _cacheRepository.clearAllCachedResultDetails();
  }
}