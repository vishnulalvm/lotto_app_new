import 'package:lotto_app/data/models/predict_screen/ai_prediction_model.dart';

/// Model representing the result of comparing predictions with lottery results
class PredictionMatchModel {
  final List<AiPredictionModel> allPredictions; // All 5 prize type predictions
  final Map<String, String> matchedNumbersWithPrizeType; // number -> prize type
  final bool hasDetailedData;
  final DateTime checkedAt;
  final String lotteryName;

  const PredictionMatchModel({
    required this.allPredictions,
    required this.matchedNumbersWithPrizeType,
    required this.hasDetailedData,
    required this.checkedAt,
    required this.lotteryName,
  });

  /// Whether any predictions matched
  bool get hasMatches => matchedNumbersWithPrizeType.isNotEmpty;

  /// Number of matched predictions
  int get matchCount => matchedNumbersWithPrizeType.length;

  /// Get list of matched numbers
  List<String> get matchedNumbers => matchedNumbersWithPrizeType.keys.toList();

  /// Get list of matched prize types
  List<String> get matchedPrizeTypes => matchedNumbersWithPrizeType.values.toSet().toList();

  /// Checks if a specific number was matched
  bool isNumberMatched(String number) => matchedNumbersWithPrizeType.containsKey(number);

  /// Get prize type for a matched number
  String? getPrizeTypeForNumber(String number) => matchedNumbersWithPrizeType[number];

  /// Factory constructor for no matches
  factory PredictionMatchModel.noMatches(List<AiPredictionModel> allPredictions, String lotteryName) {
    return PredictionMatchModel(
      allPredictions: allPredictions,
      matchedNumbersWithPrizeType: const {},
      hasDetailedData: false,
      checkedAt: DateTime.now(),
      lotteryName: lotteryName,
    );
  }

  /// Factory constructor with matches
  factory PredictionMatchModel.withMatches(
    List<AiPredictionModel> allPredictions,
    Map<String, String> matchesWithPrizeType,
    String lotteryName, {
    bool hasDetailedData = false,
  }) {
    return PredictionMatchModel(
      allPredictions: allPredictions,
      matchedNumbersWithPrizeType: matchesWithPrizeType,
      hasDetailedData: hasDetailedData,
      checkedAt: DateTime.now(),
      lotteryName: lotteryName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PredictionMatchModel &&
        other.allPredictions.toString() == allPredictions.toString() &&
        other.matchedNumbersWithPrizeType.toString() == matchedNumbersWithPrizeType.toString() &&
        other.hasDetailedData == hasDetailedData;
  }

  @override
  int get hashCode {
    return allPredictions.hashCode ^
        matchedNumbersWithPrizeType.hashCode ^
        hasDetailedData.hashCode;
  }
}