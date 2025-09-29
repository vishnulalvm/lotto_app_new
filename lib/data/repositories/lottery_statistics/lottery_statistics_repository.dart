import 'package:lotto_app/data/datasource/api/lottery_statistics/lottery_statistics_api_service.dart';
import 'package:lotto_app/data/models/lottery_statistics/lottery_statistics_request_model.dart';
import 'package:lotto_app/data/models/lottery_statistics/lottery_statistics_response_model.dart';
import 'package:lotto_app/data/repositories/cache/lottery_statistics_cache_repository.dart';
import 'package:lotto_app/data/services/connectivity_service.dart';

enum DataSource { cache, api, hybrid }

class LotteryStatisticsRepository {
  final LotteryStatisticsApiService apiService;
  final LotteryStatisticsCacheRepository cacheRepository;
  final ConnectivityService connectivityService;

  LotteryStatisticsRepository({
    required this.apiService,
    required this.cacheRepository,
    required this.connectivityService,
  });

  DataSource _lastDataSource = DataSource.cache;

  /// Get lottery statistics with cache-first strategy
  Future<LotteryStatisticsResponseModel> getLotteryStatistics(
    String userId, {
    bool forceRefresh = false,
    Function(LotteryStatisticsResponseModel)? onBackgroundRefreshComplete,
  }) async {
    // If force refresh is requested, skip cache and fetch from API
    if (forceRefresh) {
      final apiData = await _fetchFromApi(userId);
      await _updateCache(apiData);
      _lastDataSource = DataSource.api;
      return apiData;
    }

    // Try to get cached data first
    final cachedData = await cacheRepository.getCachedLotteryStatistics();
    final isCacheValid = await cacheRepository.isCacheValid();
    final isCacheFresh = await cacheRepository.isCacheFresh();
    final isOnline = connectivityService.isConnected;

    // If cache is fresh, return it and optionally refresh in background
    if (cachedData != null && isCacheFresh) {
      _lastDataSource = DataSource.cache;
      
      // Optionally trigger background refresh if online
      if (isOnline && onBackgroundRefreshComplete != null) {
        _performBackgroundRefresh(userId, onBackgroundRefreshComplete);
      }
      
      return cachedData;
    }

    // If cache is valid but not fresh, and we're online, try hybrid approach
    if (cachedData != null && isCacheValid && isOnline) {
      _lastDataSource = DataSource.hybrid;
      
      // Return cached data immediately
      final cacheResult = cachedData;
      
      // Fetch fresh data in background
      if (onBackgroundRefreshComplete != null) {
        _performBackgroundRefresh(userId, onBackgroundRefreshComplete);
      }
      
      return cacheResult;
    }

    // If we're online, fetch from API
    if (isOnline) {
      try {
        final apiData = await _fetchFromApi(userId);
        await _updateCache(apiData);
        _lastDataSource = DataSource.api;
        return apiData;
      } catch (e) {
        // If API fails but we have cached data, return it
        if (cachedData != null) {
          _lastDataSource = DataSource.cache;
          return cachedData;
        }
        rethrow;
      }
    }

    // If offline and we have cached data, return it
    if (cachedData != null) {
      _lastDataSource = DataSource.cache;
      return cachedData;
    }

    // No cache and offline - throw error
    throw Exception('No cached data available and device is offline');
  }

  /// Perform background refresh without blocking UI
  void _performBackgroundRefresh(
    String userId,
    Function(LotteryStatisticsResponseModel) onComplete,
  ) {
    _fetchFromApi(userId).then((freshData) {
      _updateCache(freshData);
      onComplete(freshData);
    }).catchError((error) {
      // Silently handle background refresh errors
    });
  }

  /// Fetch data from API
  Future<LotteryStatisticsResponseModel> _fetchFromApi(String userId) async {
    final request = LotteryStatisticsRequestModel(userId: userId);
    return await apiService.getLotteryStatistics(request);
  }

  /// Update cache with new data
  Future<void> _updateCache(LotteryStatisticsResponseModel data) async {
    try {
      await cacheRepository.cacheLotteryStatistics(data);
    } catch (e) {
      // Log cache error but don't fail the operation
    }
  }

  /// Get the data source of the last request
  Future<DataSource> getLastDataSource() async {
    return _lastDataSource;
  }

  /// Clear cached data
  Future<void> clearCache() async {
    await cacheRepository.clearCache();
  }

  /// Get cache information
  Future<Map<String, dynamic>> getCacheInfo() async {
    final isCacheValid = await cacheRepository.isCacheValid();
    final isCacheFresh = await cacheRepository.isCacheFresh();
    final cacheAge = await cacheRepository.getCacheAge();
    
    return {
      'isValid': isCacheValid,
      'isFresh': isCacheFresh,
      'ageInMinutes': cacheAge,
      'lastDataSource': _lastDataSource.toString(),
    };
  }
}