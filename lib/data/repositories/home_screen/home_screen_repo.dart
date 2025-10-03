import 'package:lotto_app/data/datasource/api/home_screen/home_screen_api.dart';
import 'package:lotto_app/data/models/home_screen/home_screen_model.dart';
import 'package:lotto_app/data/repositories/cache/home_screen_cache_repository.dart';
import 'package:lotto_app/data/services/connectivity_service.dart';

enum DataSource { cache, network, hybrid }

class HomeScreenResultsRepository {
  final HomeScreenResultsApiService _apiService;
  final HomeScreenCacheRepository _cacheRepository;
  final ConnectivityService _connectivityService;

  HomeScreenResultsRepository(
    this._apiService,
    this._cacheRepository,
    this._connectivityService,
  );

  /// Get home screen results with cache-first strategy
  Future<HomeScreenResultsModel> getHomeScreenResults({
    bool forceRefresh = false,
    Function(HomeScreenResultsModel)? onBackgroundRefreshComplete,
  }) async {
    try {
      // If force refresh is requested and we're online, skip cache
      if (forceRefresh && _connectivityService.isOnline) {
        return await _fetchAndCacheFromNetwork();
      }

      // Cache-first strategy
      final cachedData = await _cacheRepository.getCachedHomeScreenResults();

      // If we have cached data and we're offline, return cached data (even if expired)
      if (cachedData != null && _connectivityService.isOffline) {
        return cachedData;
      }

      // ALWAYS trigger background refresh if online (regardless of cache validity)
      // This ensures fresh data is fetched every time the app opens
      if (_connectivityService.isOnline) {
        // Background refresh with callback
        _backgroundRefresh(onBackgroundRefreshComplete);

        // If we have any cached data, return it immediately (cache-first)
        if (cachedData != null) {
          return cachedData;
        }

        // No cached data - fetch from network synchronously
        return await _fetchAndCacheFromNetwork();
      }

      // If we're offline and have any cached data (even expired), return it
      if (cachedData != null) {
        return cachedData;
      }

      // No cached data and offline - throw error
      throw Exception('No cached data available and device is offline');
    } catch (e) {
      // If network fails, try to return cached data as fallback
      final cachedData = await _cacheRepository.getCachedHomeScreenResults();
      if (cachedData != null) {
        return cachedData;
      }

      throw Exception('Failed to get home screen results: $e');
    }
  }

  /// Fetch data from network and cache it
  Future<HomeScreenResultsModel> _fetchAndCacheFromNetwork() async {
    final json = await _apiService.getHomeScreenResults();
    final data = HomeScreenResultsModel.fromJson(json);
    
    // Cache the fresh data
    await _cacheRepository.cacheHomeScreenResults(data);
    
    return data;
  }

  /// Background refresh - fetch fresh data without blocking UI
  void _backgroundRefresh(Function(HomeScreenResultsModel)? onComplete) {
    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        final freshData = await _fetchAndCacheFromNetwork();
        // Notify caller with fresh data
        onComplete?.call(freshData);
      } catch (e) {
        // Silent fail for background refresh
      }
    });
  }

  /// Get data source info for debugging/UI
  Future<DataSource> getLastDataSource() async {
    if (_connectivityService.isOffline) {
      return DataSource.cache;
    }

    final isCacheFresh = await _cacheRepository.isCacheFresh();
    if (isCacheFresh) {
      return DataSource.hybrid; // Using cache but refreshing in background
    }

    return DataSource.network;
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await _cacheRepository.clearCache();
  }

  /// Get cache metadata
  Future<Map<String, dynamic>> getCacheInfo() async {
    if (_cacheRepository is HomeScreenCacheRepositoryImpl) {
      return await (_cacheRepository).getCacheMetadata();
    }
    return {};
  }
}