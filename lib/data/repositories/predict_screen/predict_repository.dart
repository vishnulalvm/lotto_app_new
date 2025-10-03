import 'package:lotto_app/data/datasource/api/predict_screen/predict_api_service.dart';
import 'package:lotto_app/data/models/predict_screen/predict_request_model.dart';
import 'package:lotto_app/data/models/predict_screen/predict_response_model.dart';
import 'package:lotto_app/data/services/predict_cache_service.dart';
import 'package:hive/hive.dart';
import 'package:lotto_app/data/models/results_screen/cached_result_details_model.dart';

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
        final enrichedResult = await _enrichWithCachedData(result);
        await _cacheService.cachePredictionData(enrichedResult);
        return enrichedResult;
      }

      // Try to get cached data first
      final cachedData = await _cacheService.getCachedPredictionData();

      if (cachedData != null) {
        // Enrich cached data with two digits analysis
        final enrichedCachedData = await _enrichWithCachedData(cachedData);
        return enrichedCachedData;
      }

      // No cache available, fetch from API
      final result = await _apiService.getPredictionData();
      final enrichedResult = await _enrichWithCachedData(result);
      await _cacheService.cachePredictionData(enrichedResult);
      return enrichedResult;
    } catch (e) {
      // If API fails, try to return cached data as fallback
      final cachedData = await _cacheService.getCachedPredictionData();
      if (cachedData != null) {
        final enrichedCachedData = await _enrichWithCachedData(cachedData);
        return enrichedCachedData;
      }
      throw Exception('Failed to get prediction data: $e');
    }
  }

  Future<PredictResponseModel> _enrichWithCachedData(PredictResponseModel apiResult) async {
    try {
      final repeatedTwoDigits = await _calculateRepeatedTwoDigits();

      return PredictResponseModel(
        status: apiResult.status,
        repeatedNumbers: apiResult.repeatedNumbers,
        repeatedSingleDigits: apiResult.repeatedSingleDigits,
        peoplesPredictions: apiResult.peoplesPredictions,
        repeatedTwoDigits: repeatedTwoDigits,
      );
    } catch (e) {
      // If enrichment fails, return original result
      return apiResult;
    }
  }

  Future<List<RepeatedTwoDigit>> _calculateRepeatedTwoDigits() async {
    try {
      // Get all cached result details from last 7 days
      final box = await Hive.openBox<CachedResultDetailsModel>('result_details_cache');
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      // Map to count occurrences of each two-digit combination
      final Map<String, int> twoDigitCounts = {};

      // Iterate through all cached results
      for (final cached in box.values) {
        // Skip if expired
        if (cached.isExpired) {
          continue;
        }

        try {
          final resultDetails = cached.toResultDetails();
          final result = resultDetails.result;

          // Parse the lottery draw date from the result
          DateTime? drawDate;
          try {
            drawDate = DateTime.parse(result.date);
          } catch (e) {
            // Skip if date parsing fails
            continue;
          }

          // Skip if draw date is older than 7 days
          if (drawDate.isBefore(sevenDaysAgo)) {
            continue;
          }

          // Extract last 2 digits from all ticket numbers in all prizes
          for (final prize in result.prizes) {
            final ticketNumbers = prize.getAllTicketNumbers();

            for (final ticket in ticketNumbers) {
              if (ticket.length >= 2) {
                final lastTwoDigits = ticket.substring(ticket.length - 2);
                twoDigitCounts[lastTwoDigits] = (twoDigitCounts[lastTwoDigits] ?? 0) + 1;
              }
            }
          }
        } catch (e) {
          // Skip corrupted entries
          continue;
        }
      }

      // Sort by count and take top 6
      final sortedEntries = twoDigitCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final top6 = sortedEntries.take(6).map((entry) {
        return RepeatedTwoDigit(
          digits: entry.key,
          count: entry.value,
        );
      }).toList();

      return top6;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<PredictResponseModel?> getCachedPredictionData() async {
    try {
      final cachedData = await _cacheService.getCachedPredictionData();
      if (cachedData != null) {
        // Enrich cached data with two digits analysis
        return await _enrichWithCachedData(cachedData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> refreshPredictionDataInBackground() async {
    try {
      final result = await _apiService.getPredictionData();
      final enrichedResult = await _enrichWithCachedData(result);
      await _cacheService.cachePredictionData(enrichedResult);
    } catch (e) {
      // Silent fail for background refresh
    }
  }
}