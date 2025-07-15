class ProbabilityResponseModel {
  final String status;
  final String lotteryNumber;
  final String lotteryName;
  final double percentage;
  final String message;

  const ProbabilityResponseModel({
    required this.status,
    required this.lotteryNumber,
    required this.lotteryName,
    required this.percentage,
    required this.message,
  });

  factory ProbabilityResponseModel.fromJson(Map<String, dynamic> json) {
    return ProbabilityResponseModel(
      status: json['status'] as String,
      lotteryNumber: json['lottery_number'] as String,
      lotteryName: json['lottery_name'] as String,
      percentage: (json['percentage'] as num).toDouble(),
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'lottery_number': lotteryNumber,
      'lottery_name': lotteryName,
      'percentage': percentage,
      'message': message,
    };
  }

  @override
  String toString() {
    return 'ProbabilityResponseModel(status: $status, lotteryNumber: $lotteryNumber, lotteryName: $lotteryName, percentage: $percentage, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProbabilityResponseModel &&
        other.status == status &&
        other.lotteryNumber == lotteryNumber &&
        other.lotteryName == lotteryName &&
        other.percentage == percentage &&
        other.message == message;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        lotteryNumber.hashCode ^
        lotteryName.hashCode ^
        percentage.hashCode ^
        message.hashCode;
  }
}