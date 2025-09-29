import 'package:lotto_app/data/models/lottery_statistics/lottery_statistics_response_model.dart';

abstract class LotteryStatisticsState {}

class LotteryStatisticsInitial extends LotteryStatisticsState {}

class LotteryStatisticsLoading extends LotteryStatisticsState {}

class LotteryStatisticsLoaded extends LotteryStatisticsState {
  final LotteryStatisticsResponseModel data;

  LotteryStatisticsLoaded(this.data);
}

class LotteryStatisticsError extends LotteryStatisticsState {
  final String message;

  LotteryStatisticsError(this.message);
}