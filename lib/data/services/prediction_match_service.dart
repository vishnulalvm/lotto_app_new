import 'package:flutter/foundation.dart';
import 'package:lotto_app/data/models/predict_screen/ai_prediction_model.dart';
import 'package:lotto_app/data/models/results_screen/results_screen.dart';
import 'package:lotto_app/data/models/home_screen/home_screen_model.dart';
import 'package:lotto_app/data/services/ai_prediction_service.dart';
import 'package:lotto_app/data/repositories/cache/home_screen_cache_repository.dart';
import 'package:lotto_app/data/repositories/cache/result_details_cache_repository.dart';

/// Service responsible for matching AI predictions with lottery results
class PredictionMatchService {
  static final HomeScreenCacheRepositoryImpl _homeScreenCacheRepo = HomeScreenCacheRepositoryImpl();
  static final ResultDetailsCacheRepositoryImpl _detailsCacheRepo = ResultDetailsCacheRepositoryImpl();

  /// Fetches prediction for the appropriate date based on current time
  /// Before 4:30 PM: gets yesterday's prediction
  /// After 4:30 PM: gets today's prediction
  static Future<AiPredictionModel?> getTodaysPrediction(int prizeType) async {
    try {
      final targetDate = getTargetDateForPrediction();
      debugPrint('🔍 [PredictionMatch] Getting prediction for date: $targetDate, prizeType: $prizeType');
      
      // Get prediction for the appropriate date
      return await AiPredictionService.getPredictionForDate(targetDate, prizeType);
    } catch (e) {
      debugPrint('❌ [PredictionMatch] Error getting prediction: $e');
      return null;
    }
  }

  /// Gets lottery results for the same date as predictions
  /// Uses the same target date logic as predictions to ensure they match
  static Future<HomeScreenResultModel?> getTodaysResults() async {
    try {
      final cachedResults = await _homeScreenCacheRepo.getCachedHomeScreenResults();
      if (cachedResults == null || cachedResults.results.isEmpty) {
        debugPrint('❌ [PredictionMatch] No cached results available');
        return null;
      }

      // Use the same target date as predictions for consistency
      final targetDate = getTargetDateForPrediction();
      debugPrint('🔍 [PredictionMatch] Looking for results on same date as prediction: $targetDate');
      
      // Try to find results for the target date
      HomeScreenResultModel? targetResult;
      for (final result in cachedResults.results) {
        debugPrint('📅 [PredictionMatch] Found result for date: ${result.date}, published: ${result.isPublished}');
        if (result.date == targetDate && result.isPublished) {
          targetResult = result;
          break;
        }
      }
      
      // If no results for target date, get the latest published result
      if (targetResult == null) {
        debugPrint('⚠️ [PredictionMatch] No results for exact target date, getting latest published result');
        for (final result in cachedResults.results) {
          if (result.isPublished) {
            targetResult = result;
            debugPrint('📊 [PredictionMatch] Using fallback result: ${result.date}');
            break;
          }
        }
      }
      
      debugPrint('✅ [PredictionMatch] Final result selected: ${targetResult?.date}, lottery: ${targetResult?.lotteryName}');
      return targetResult;
    } catch (e) {
      debugPrint('❌ [PredictionMatch] Error getting results: $e');
      return null;
    }
  }

  /// Gets detailed lottery results from result details cache
  static Future<LotteryResultModel?> getDetailedResults(String uniqueId) async {
    try {
      final cachedDetails = await _detailsCacheRepo.getCachedResultDetails(uniqueId);
      return cachedDetails?.toResultDetails().result;
    } catch (e) {
      return null;
    }
  }

  /// Compares predictions with ALL numbers from the specified prize type
  /// This method collects ALL winning ticket numbers from ALL prizes of the specified type
  /// and compares them against the prediction numbers (simplified comparison logic)
  static List<String> compareWithDetailedResults(
    List<String> predictions,
    LotteryResultModel result,
    int prizeType,
  ) {
    final matchedNumbers = <String>[];
    final prizeTypeString = _getPrizeTypeString(prizeType);
    final targetPrizes = result.getPrizesByType(prizeTypeString);

    debugPrint('🔍 [PredictionMatch] Comparing with prize type: $prizeTypeString');
    debugPrint('🔍 [PredictionMatch] Found ${targetPrizes.length} prizes for this type');

    if (targetPrizes.isNotEmpty) {
      final winningNumbers = <String>[];
      
      // Collect ALL winning numbers for this prize type (from all prizes)
      for (final prize in targetPrizes) {
        final prizeNumbers = prize.getAllTicketNumbers();
        winningNumbers.addAll(prizeNumbers);
        debugPrint('🎟️ [PredictionMatch] Prize numbers: $prizeNumbers');
      }
      
      debugPrint('🎯 [PredictionMatch] Total winning numbers for $prizeTypeString: ${winningNumbers.length} - $winningNumbers');
      debugPrint('🎲 [PredictionMatch] Prediction numbers: ${predictions.length} - $predictions');
      
      // Compare predictions with winning numbers
      for (final prediction in predictions) {
        if (winningNumbers.contains(prediction)) {
          matchedNumbers.add(prediction);
          debugPrint('✅ [PredictionMatch] MATCH FOUND: $prediction');
        }
      }
    } else {
      debugPrint('⚠️ [PredictionMatch] No prizes found for type: $prizeTypeString');
    }

    debugPrint('🏆 [PredictionMatch] Final matches for $prizeTypeString: ${matchedNumbers.length} - $matchedNumbers');
    return matchedNumbers;
  }

  /// Compares ALL predictions from ALL prize types (5-9) with detailed results
  /// Returns a map of matched numbers to their winning prize types
  static Map<String, String> compareAllPredictionsWithDetailedResults(
    List<AiPredictionModel> allPredictions,
    LotteryResultModel result,
  ) {
    final matchedNumbersWithPrizeType = <String, String>{};
    
    debugPrint('🔍 [PredictionMatch] === COMPREHENSIVE DETAILED COMPARISON START ===');
    debugPrint('🔍 [PredictionMatch] Predictions to check: ${allPredictions.length} prize types');
    
    // Get all winning numbers from ALL prize types (5th to 9th)
    final allWinningNumbers = <String, String>{}; // number -> prize type
    
    for (int prizeType = 5; prizeType <= 9; prizeType++) {
      final prizeTypeString = _getPrizeTypeString(prizeType);
      final targetPrizes = result.getPrizesByType(prizeTypeString);
      
      debugPrint('🎯 [PredictionMatch] Checking $prizeTypeString: found ${targetPrizes.length} prizes');
      
      for (final prize in targetPrizes) {
        final prizeNumbers = prize.getAllTicketNumbers();
        for (final number in prizeNumbers) {
          allWinningNumbers[number] = prizeTypeString;
        }
        debugPrint('🎟️ [PredictionMatch] $prizeTypeString prize numbers: $prizeNumbers');
      }
    }
    
    debugPrint('🎯 [PredictionMatch] Total winning numbers across all prize types: ${allWinningNumbers.length}');
    
    // Count total prediction numbers
    int totalPredictionNumbers = 0;
    for (final prediction in allPredictions) {
      totalPredictionNumbers += prediction.predictedNumbers.length;
    }
    debugPrint('🎲 [PredictionMatch] Total prediction numbers to check: $totalPredictionNumbers');
    
    // Compare ALL prediction numbers against ALL winning numbers
    for (final prediction in allPredictions) {
      for (final predictionNumber in prediction.predictedNumbers) {
        if (allWinningNumbers.containsKey(predictionNumber)) {
          final winningPrizeType = allWinningNumbers[predictionNumber]!;
          matchedNumbersWithPrizeType[predictionNumber] = winningPrizeType;
          debugPrint('✅ [PredictionMatch] MATCH FOUND: $predictionNumber wins in $winningPrizeType');
        }
      }
    }
    
    debugPrint('🏆 [PredictionMatch] Final comprehensive matches: ${matchedNumbersWithPrizeType.length}');
    debugPrint('🔍 [PredictionMatch] === COMPREHENSIVE DETAILED COMPARISON END ===');
    
    return matchedNumbersWithPrizeType;
  }

  /// Fallback: Compares ALL predictions from ALL prize types with basic results
  /// Returns a map of matched numbers to estimated prize types
  static Map<String, String> compareAllPredictionsWithBasicResults(
    List<AiPredictionModel> allPredictions,
    HomeScreenResultModel result,
  ) {
    final matchedNumbersWithPrizeType = <String, String>{};
    
    debugPrint('🔍 [PredictionMatch] === COMPREHENSIVE BASIC COMPARISON START ===');
    
    final winningNumbers = <String>[];

    // Add first prize ticket number (check last 4 digits)
    final firstPrizeNumber = result.firstPrize.ticketNumber;
    if (firstPrizeNumber.length >= 4) {
      winningNumbers.add(firstPrizeNumber.substring(firstPrizeNumber.length - 4));
    }

    // Add consolation prize numbers (check last 4 digits of each)
    if (result.hasConsolationPrizes) {
      final consolationNumbers = result.consolationTicketsList;
      for (final number in consolationNumbers) {
        if (number.length >= 4) {
          winningNumbers.add(number.substring(number.length - 4));
        }
      }
    }

    debugPrint('🎯 [PredictionMatch] Basic winning numbers: $winningNumbers');
    
    // Compare ALL prediction numbers against winning numbers
    for (final prediction in allPredictions) {
      for (final predictionNumber in prediction.predictedNumbers) {
        if (winningNumbers.contains(predictionNumber)) {
          // Assign to estimated prize type (since we don't have detailed data)
          matchedNumbersWithPrizeType[predictionNumber] = 'estimated';
          debugPrint('✅ [PredictionMatch] BASIC MATCH: $predictionNumber');
        }
      }
    }
    
    debugPrint('🏆 [PredictionMatch] Final basic matches: ${matchedNumbersWithPrizeType.length}');
    debugPrint('🔍 [PredictionMatch] === COMPREHENSIVE BASIC COMPARISON END ===');
    
    return matchedNumbersWithPrizeType;
  }

  /// Fallback comparison using basic home screen result data
  static List<String> compareWithBasicResults(
    List<String> predictions,
    HomeScreenResultModel result,
  ) {
    final matchedNumbers = <String>[];
    final winningNumbers = <String>[];

    // Add first prize ticket number (check last 4 digits)
    final firstPrizeNumber = result.firstPrize.ticketNumber;
    if (firstPrizeNumber.length >= 4) {
      winningNumbers.add(firstPrizeNumber.substring(firstPrizeNumber.length - 4));
    }

    // Add consolation prize numbers (check last 4 digits of each)
    if (result.hasConsolationPrizes) {
      final consolationNumbers = result.consolationTicketsList;
      for (final number in consolationNumbers) {
        if (number.length >= 4) {
          winningNumbers.add(number.substring(number.length - 4));
        }
      }
    }

    // Compare predictions with winning numbers
    for (final prediction in predictions) {
      if (winningNumbers.contains(prediction)) {
        matchedNumbers.add(prediction);
      }
    }

    return matchedNumbers;
  }

  /// Always return true - we always show results (either previous day or current day)
  static bool shouldShowResults() {
    return true;
  }

  /// Never reset - we don't need the waiting state anymore
  static bool shouldResetForNewDay() {
    return false;
  }

  /// Gets the target date for both predictions and results based on current time
  /// Before 4:30 PM: yesterday's date (compare yesterday's prediction vs yesterday's result)
  /// After 4:30 PM: today's date (compare today's prediction vs today's result)
  /// This ensures predictions and results are always for the same date
  static String getTargetDateForPrediction() {
    final now = DateTime.now();
    final isAfter430PM = now.hour > 16 || (now.hour == 16 && now.minute >= 30);
    
    final targetDate = isAfter430PM ? now : now.subtract(const Duration(days: 1));
    final dateString = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
    
    debugPrint('🕐 [PredictionMatch] Current time: ${now.hour}:${now.minute.toString().padLeft(2, '0')}, After 4:30 PM: $isAfter430PM, Target date for both prediction & result: $dateString');
    return dateString;
  }


  /// Gets the lottery name for today based on weekday
  static String getLotteryNameForToday() {
    final now = DateTime.now();
    final weekday = now.weekday;

    switch (weekday) {
      case DateTime.sunday:
        return 'SAMRUDHI';
      case DateTime.monday:
        return 'BHAGYATHARA';
      case DateTime.tuesday:
        return 'STHREE SAKTHI';
      case DateTime.wednesday:
        return 'DHANALEKSHMI';
      case DateTime.thursday:
        return 'KARUNYA PLUS';
      case DateTime.friday:
        return 'SUVARNA KERALAM';
      case DateTime.saturday:
        return 'KARUNYA';
      default:
        return 'KARUNYA';
    }
  }


  /// Converts prize type number to string
  static String _getPrizeTypeString(int prizeType) {
    switch (prizeType) {
      case 5:
        return '5th';
      case 6:
        return '6th';
      case 7:
        return '7th';
      case 8:
        return '8th';
      case 9:
        return '9th';
      default:
        return '5th';
    }
  }


}