class PredictRequestModel {
  final String lotteryName;
  final String prizeType;

  const PredictRequestModel({
    required this.lotteryName,
    required this.prizeType,
  });

  Map<String, dynamic> toJson() {
    return {
      'lottery_name': lotteryName,
      'prize_type': prizeType,
    };
  }

  factory PredictRequestModel.fromJson(Map<String, dynamic> json) {
    return PredictRequestModel(
      lotteryName: json['lottery_name'] as String,
      prizeType: json['prize_type'] as String,
    );
  }

  @override
  String toString() {
    return 'PredictRequestModel(lotteryName: $lotteryName, prizeType: $prizeType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PredictRequestModel &&
        other.lotteryName == lotteryName &&
        other.prizeType == prizeType;
  }

  @override
  int get hashCode => lotteryName.hashCode ^ prizeType.hashCode;
}