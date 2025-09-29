import 'package:lotto_app/data/models/lottery_statistics/challenge_statistics_model.dart';
import 'package:lotto_app/data/models/lottery_statistics/lottery_entry_model.dart';

class LotteryStatisticsResponseModel {
  final String userId;
  final ChallengeStatisticsModel challengeStatistics;
  final List<LotteryEntryModel> lotteryEntries;

  LotteryStatisticsResponseModel({
    required this.userId,
    required this.challengeStatistics,
    required this.lotteryEntries,
  });

  factory LotteryStatisticsResponseModel.fromJson(Map<String, dynamic> json) {
    return LotteryStatisticsResponseModel(
      userId: json['user_id'] ?? '',
      challengeStatistics: ChallengeStatisticsModel.fromJson(
        json['challenge_statistics'] ?? {},
      ),
      lotteryEntries: (json['lottery_entries'] as List<dynamic>? ?? [])
          .map((entry) => LotteryEntryModel.fromJson(entry))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'challenge_statistics': challengeStatistics.toJson(),
      'lottery_entries': lotteryEntries.map((entry) => entry.toJson()).toList(),
    };
  }
}