class LotteryStatisticsRequestModel {
  final String userId;

  LotteryStatisticsRequestModel({
    required this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
    };
  }
}