import 'package:equatable/equatable.dart';

abstract class LotteryStatisticsEvent extends Equatable {
  const LotteryStatisticsEvent();

  @override
  List<Object?> get props => [];
}

class LoadLotteryStatistics extends LotteryStatisticsEvent {
  final String userId;

  const LoadLotteryStatistics({
    required this.userId,
  });

  @override
  List<Object?> get props => [userId];
}

class RefreshLotteryStatistics extends LotteryStatisticsEvent {
  final String userId;

  const RefreshLotteryStatistics({
    required this.userId,
  });

  @override
  List<Object?> get props => [userId];
}
