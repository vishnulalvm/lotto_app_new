import 'package:lotto_app/data/models/predict_screen/ai_prediction_model.dart';

/// Model representing the result of comparing predictions with lottery results
class PredictionMatchModel {
  final AiPredictionModel prediction;
  final List<String> matchedNumbers;
  final bool hasDetailedData;
  final DateTime checkedAt;

  const PredictionMatchModel({
    required this.prediction,
    required this.matchedNumbers,
    required this.hasDetailedData,
    required this.checkedAt,
  });

  /// Whether any predictions matched
  bool get hasMatches => matchedNumbers.isNotEmpty;

  /// Number of matched predictions
  int get matchCount => matchedNumbers.length;

  /// Checks if a specific number was matched
  bool isNumberMatched(String number) => matchedNumbers.contains(number);

  /// Factory constructor for no matches
  factory PredictionMatchModel.noMatches(AiPredictionModel prediction) {
    return PredictionMatchModel(
      prediction: prediction,
      matchedNumbers: const [],
      hasDetailedData: false,
      checkedAt: DateTime.now(),
    );
  }

  /// Factory constructor with matches
  factory PredictionMatchModel.withMatches(
    AiPredictionModel prediction,
    List<String> matches, {
    bool hasDetailedData = false,
  }) {
    return PredictionMatchModel(
      prediction: prediction,
      matchedNumbers: matches,
      hasDetailedData: hasDetailedData,
      checkedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PredictionMatchModel &&
        other.prediction == prediction &&
        other.matchedNumbers.toString() == matchedNumbers.toString() &&
        other.hasDetailedData == hasDetailedData;
  }

  @override
  int get hashCode {
    return prediction.hashCode ^
        matchedNumbers.hashCode ^
        hasDetailedData.hashCode;
  }
}