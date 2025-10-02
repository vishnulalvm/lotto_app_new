import 'package:lotto_app/data/datasource/api/predict_screen/predict_api_service.dart';
import 'package:lotto_app/data/models/predict_screen/predict_request_model.dart';
import 'package:lotto_app/data/models/predict_screen/predict_response_model.dart';
import 'package:lotto_app/data/services/predict_cache_service.dart';

abstract class PredictRepository {
  Future<PredictResponseModel> getPrediction(PredictRequestModel request);
  Future<PredictResponseModel> getPredictionData({bool forceRefresh = false});
  Future<PredictResponseModel?> getCachedPredictionData();
  Future<void> refreshPredictionDataInBackground();
}

class PredictRepositoryImpl implements PredictRepository {
  final PredictApiService _apiService;
  final PredictCacheService _cacheService;

  PredictRepositoryImpl(this._apiService, this._cacheService);

  @override
  Future<PredictResponseModel> getPrediction(PredictRequestModel request) async {
    try {
      return await _apiService.getPrediction(request);
    } catch (e) {
      throw Exception('Failed to get prediction: $e');
    }
  }

  @override
  Future<PredictResponseModel> getPredictionData({bool forceRefresh = false}) async {
    try {
      // If force refresh, skip cache and fetch from API
      if (forceRefresh) {
        final result = await _apiService.getPredictionData();
        await _cacheService.cachePredictionData(result);
        return result;
      }

      // Try to get cached data first
      final cachedData = await _cacheService.getCachedPredictionData();

      if (cachedData != null) {
        // Return cached data immediately for smooth UI
        return cachedData;
      }

      // No cache available, fetch from API
      final result = await _apiService.getPredictionData();
      await _cacheService.cachePredictionData(result);
      return result;
    } catch (e) {
      // If API fails, try to return cached data as fallback
      final cachedData = await _cacheService.getCachedPredictionData();
      if (cachedData != null) {
        return cachedData;
      }
      throw Exception('Failed to get prediction data: $e');
    }
  }

  @override
  Future<PredictResponseModel?> getCachedPredictionData() async {
    try {
      return await _cacheService.getCachedPredictionData();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> refreshPredictionDataInBackground() async {
    try {
      final result = await _apiService.getPredictionData();
      await _cacheService.cachePredictionData(result);
    } catch (e) {
      // Silent fail for background refresh
    }
  }
}