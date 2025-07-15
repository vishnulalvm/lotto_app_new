class ProbabilityRequestModel {
  final String lotteryName;
  final String lotteryNumber;

  const ProbabilityRequestModel({
    required this.lotteryName,
    required this.lotteryNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'lottery_name': lotteryName,
      'lottery_number': lotteryNumber,
    };
  }

  factory ProbabilityRequestModel.fromJson(Map<String, dynamic> json) {
    return ProbabilityRequestModel(
      lotteryName: json['lottery_name'] as String,
      lotteryNumber: json['lottery_number'] as String,
    );
  }

  @override
  String toString() {
    return 'ProbabilityRequestModel(lotteryName: $lotteryName, lotteryNumber: $lotteryNumber)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProbabilityRequestModel &&
        other.lotteryName == lotteryName &&
        other.lotteryNumber == lotteryNumber;
  }

  @override
  int get hashCode => lotteryName.hashCode ^ lotteryNumber.hashCode;
}