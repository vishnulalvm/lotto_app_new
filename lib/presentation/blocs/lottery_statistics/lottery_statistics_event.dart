abstract class LotteryStatisticsEvent {}

class LoadLotteryStatistics extends LotteryStatisticsEvent {
  final String userId;

  LoadLotteryStatistics({
    required this.userId,
  });
}

class RefreshLotteryStatistics extends LotteryStatisticsEvent {
  final String userId;

  RefreshLotteryStatistics({
    required this.userId,
  });
}