import 'package:lotto_app/data/services/ai_prediction_service.dart';
import 'package:lotto_app/presentation/pages/predict_screen/widgets/ai_prediction_state.dart';

/// Simplified service for loading AI predictions with state management
class AIPredictionLoaderService {
  
  /// Loads prediction for the given prize type and returns appropriate state
  static Future<AIPredictionState> loadPrediction(int prizeType) async {
    try {
      final prediction = await AiPredictionService.getTodaysPrediction(prizeType);
      
      if (prediction != null) {
        return AIPredictionLoaded(
          prediction: prediction,
          prizeType: prizeType,
          loadedAt: DateTime.now(),
        );
      } else {
        return AIPredictionError(
          message: 'No prediction data available',
          occurredAt: DateTime.now(),
        );
      }
    } catch (e) {
      return AIPredictionError(
        message: 'Failed to load predictions: ${e.toString()}',
        occurredAt: DateTime.now(),
      );
    }
  }

  /// Validates if the prize type has changed and needs reload
  static bool shouldReloadForPrizeType(AIPredictionState currentState, int newPrizeType) {
    return switch (currentState) {
      AIPredictionLoaded(:final prizeType) => prizeType != newPrizeType,
      _ => true,
    };
  }

  /// Checks if the current state data is stale and needs refresh
  static bool isStateStale(AIPredictionState state) {
    return switch (state) {
      AIPredictionLoaded() => !state.isFresh,
      AIPredictionError() => !state.isRecent,
      _ => true,
    };
  }
}