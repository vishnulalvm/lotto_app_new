class PredictResponseModel {
  final String status;
  final String lotteryName;
  final String prizeType;
  final List<String> predictedNumbers;
  final String note;

  const PredictResponseModel({
    required this.status,
    required this.lotteryName,
    required this.prizeType,
    required this.predictedNumbers,
    required this.note,
  });

  factory PredictResponseModel.fromJson(Map<String, dynamic> json) {
    return PredictResponseModel(
      status: json['status'] as String,
      lotteryName: json['lottery_name'] as String,
      prizeType: json['prize_type'] as String,
      predictedNumbers: List<String>.from(json['predicted_numbers'] as List),
      note: json['note'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'lottery_name': lotteryName,
      'prize_type': prizeType,
      'predicted_numbers': predictedNumbers,
      'note': note,
    };
  }

  @override
  String toString() {
    return 'PredictResponseModel(status: $status, lotteryName: $lotteryName, prizeType: $prizeType, predictedNumbers: $predictedNumbers, note: $note)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PredictResponseModel &&
        other.status == status &&
        other.lotteryName == lotteryName &&
        other.prizeType == prizeType &&
        _listEquals(other.predictedNumbers, predictedNumbers) &&
        other.note == note;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        lotteryName.hashCode ^
        prizeType.hashCode ^
        predictedNumbers.hashCode ^
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