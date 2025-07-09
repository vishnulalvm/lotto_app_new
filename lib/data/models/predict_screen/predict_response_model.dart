class PredictResponseModel {
  final String status;
  final String lotteryName;
  final String prizeType;
  final List<String> predictedNumbers;
  final List<String> repeatedNumbers;
  final YesterdayPredictionAccuracy?
      yesterdayPredictionAccuracy; // Made optional
  final String note;

  const PredictResponseModel({
    required this.status,
    required this.lotteryName,
    required this.prizeType,
    required this.predictedNumbers,
    required this.repeatedNumbers,
    this.yesterdayPredictionAccuracy, // Optional parameter
    required this.note,
  });

  factory PredictResponseModel.fromJson(Map<String, dynamic> json) {
    return PredictResponseModel(
      status: json['status'] as String,
      lotteryName: json['lottery_name'] as String,
      prizeType: json['prize_type'] as String,
      predictedNumbers: List<String>.from(json['predicted_numbers'] as List),
      repeatedNumbers: List<String>.from(json['repeated_numbers'] as List),
      yesterdayPredictionAccuracy: json['yesterday_prediction_accuracy'] != null
          ? YesterdayPredictionAccuracy.fromJson(
              json['yesterday_prediction_accuracy'] as Map<String, dynamic>)
          : null,
      note: json['note'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'lottery_name': lotteryName,
      'prize_type': prizeType,
      'predicted_numbers': predictedNumbers,
      'repeated_numbers': repeatedNumbers,
      if (yesterdayPredictionAccuracy != null)
        'yesterday_prediction_accuracy': yesterdayPredictionAccuracy!.toJson(),
      'note': note,
    };
  }

  @override
  String toString() {
    return 'PredictResponseModel(status: $status, lotteryName: $lotteryName, prizeType: $prizeType, predictedNumbers: $predictedNumbers, repeatedNumbers: $repeatedNumbers, yesterdayPredictionAccuracy: $yesterdayPredictionAccuracy, note: $note)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PredictResponseModel &&
        other.status == status &&
        other.lotteryName == lotteryName &&
        other.prizeType == prizeType &&
        _listEquals(other.predictedNumbers, predictedNumbers) &&
        _listEquals(other.repeatedNumbers, repeatedNumbers) &&
        other.yesterdayPredictionAccuracy == yesterdayPredictionAccuracy &&
        other.note == note;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        lotteryName.hashCode ^
        prizeType.hashCode ^
        predictedNumbers.hashCode ^
        repeatedNumbers.hashCode ^
        yesterdayPredictionAccuracy.hashCode ^
        note.hashCode;
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    if (identical(a, b)) return true;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}

class YesterdayPredictionAccuracy {
  final String date;
  final AccuracySummary summary;
  final DigitAccuracy digitAccuracy;

  const YesterdayPredictionAccuracy({
    required this.date,
    required this.summary,
    required this.digitAccuracy,
  });

  factory YesterdayPredictionAccuracy.fromJson(Map<String, dynamic> json) {
    return YesterdayPredictionAccuracy(
      date: json['date'] as String,
      summary:
          AccuracySummary.fromJson(json['summary'] as Map<String, dynamic>),
      digitAccuracy: DigitAccuracy.fromJson(
          json['digit_accuracy'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'summary': summary.toJson(),
      'digit_accuracy': digitAccuracy.toJson(),
    };
  }

  @override
  String toString() {
    return 'YesterdayPredictionAccuracy(date: $date, summary: $summary, digitAccuracy: $digitAccuracy)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is YesterdayPredictionAccuracy &&
        other.date == date &&
        other.summary == summary &&
        other.digitAccuracy == digitAccuracy;
  }

  @override
  int get hashCode {
    return date.hashCode ^ summary.hashCode ^ digitAccuracy.hashCode;
  }
}

class AccuracySummary {
  final int perfectMatchCount;
  final double overallAccuracyPercent;

  const AccuracySummary({
    required this.perfectMatchCount,
    required this.overallAccuracyPercent,
  });

  factory AccuracySummary.fromJson(Map<String, dynamic> json) {
    return AccuracySummary(
      perfectMatchCount: json['perfect_match_count'] as int,
      overallAccuracyPercent:
          (json['overall_accuracy_percent'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'perfect_match_count': perfectMatchCount,
      'overall_accuracy_percent': overallAccuracyPercent,
    };
  }

  @override
  String toString() {
    return 'AccuracySummary(perfectMatchCount: $perfectMatchCount, overallAccuracyPercent: $overallAccuracyPercent)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccuracySummary &&
        other.perfectMatchCount == perfectMatchCount &&
        other.overallAccuracyPercent == overallAccuracyPercent;
  }

  @override
  int get hashCode {
    return perfectMatchCount.hashCode ^ overallAccuracyPercent.hashCode;
  }
}

class DigitAccuracy {
  final List<String> hundredPercent;
  final List<String> seventyFivePercent;
  final List<String> fiftyPercent;
  final List<String> twentyFivePercent;

  const DigitAccuracy({
    required this.hundredPercent,
    required this.seventyFivePercent,
    required this.fiftyPercent,
    required this.twentyFivePercent,
  });

  factory DigitAccuracy.fromJson(Map<String, dynamic> json) {
    return DigitAccuracy(
      hundredPercent: List<String>.from(json['100%'] as List),
      seventyFivePercent: List<String>.from(json['75%'] as List),
      fiftyPercent: List<String>.from(json['50%'] as List),
      twentyFivePercent: List<String>.from(json['25%'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '100%': hundredPercent,
      '75%': seventyFivePercent,
      '50%': fiftyPercent,
      '25%': twentyFivePercent,
    };
  }

  @override
  String toString() {
    return 'DigitAccuracy(hundredPercent: $hundredPercent, seventyFivePercent: $seventyFivePercent, fiftyPercent: $fiftyPercent, twentyFivePercent: $twentyFivePercent)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DigitAccuracy &&
        _listEquals(other.hundredPercent, hundredPercent) &&
        _listEquals(other.seventyFivePercent, seventyFivePercent) &&
        _listEquals(other.fiftyPercent, fiftyPercent) &&
        _listEquals(other.twentyFivePercent, twentyFivePercent);
  }

  @override
  int get hashCode {
    return hundredPercent.hashCode ^
        seventyFivePercent.hashCode ^
        fiftyPercent.hashCode ^
        twentyFivePercent.hashCode;
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    if (identical(a, b)) return true;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
