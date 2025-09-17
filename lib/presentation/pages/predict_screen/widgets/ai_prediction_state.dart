import 'package:lotto_app/data/models/predict_screen/ai_prediction_model.dart';

/// Sealed class representing all possible states of AI prediction loading
sealed class AIPredictionState {
  const AIPredictionState();
}

/// Initial state when no prediction has been loaded yet
class AIPredictionInitial extends AIPredictionState {
  const AIPredictionInitial();
}

/// Loading state when fetching prediction data
class AIPredictionLoading extends AIPredictionState {
  const AIPredictionLoading();
}

/// Success state with loaded prediction data
class AIPredictionLoaded extends AIPredictionState {
  final AiPredictionModel prediction;
  final int prizeType;
  final DateTime loadedAt;

  const AIPredictionLoaded({
    required this.prediction,
    required this.prizeType,
    required this.loadedAt,
  });

  /// Check if data is fresh (loaded recently)
  bool get isFresh {
    final now = DateTime.now();
    return now.difference(loadedAt).inMinutes < 30;
  }

  /// Get display count for footer
  int get predictionCount => prediction.predictedNumbers.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AIPredictionLoaded &&
        other.prediction == prediction &&
        other.prizeType == prizeType &&
        other.loadedAt == loadedAt;
  }

  @override
  int get hashCode => prediction.hashCode ^ prizeType.hashCode ^ loadedAt.hashCode;
}

/// Error state when prediction loading fails
class AIPredictionError extends AIPredictionState {
  final String message;
  final DateTime occurredAt;

  const AIPredictionError({
    required this.message,
    required this.occurredAt,
  });

  /// Check if error is recent (within last 5 minutes)
  bool get isRecent {
    final now = DateTime.now();
    return now.difference(occurredAt).inMinutes < 5;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AIPredictionError &&
        other.message == message &&
        other.occurredAt == occurredAt;
  }

  @override
  int get hashCode => message.hashCode ^ occurredAt.hashCode;
}

/// Extensions for state checking
extension AIPredictionStateExtensions on AIPredictionState {
  bool get isLoading => this is AIPredictionLoading;
  bool get isLoaded => this is AIPredictionLoaded;
  bool get isError => this is AIPredictionError;
  bool get isInitial => this is AIPredictionInitial;

  AiPredictionModel? get predictionOrNull {
    return switch (this) {
      AIPredictionLoaded(:final prediction) => prediction,
      _ => null,
    };
  }

  String? get errorMessageOrNull {
    return switch (this) {
      AIPredictionError(:final message) => message,
      _ => null,
    };
  }
}