import 'package:equatable/equatable.dart';
import 'package:lotto_app/data/models/lottery_statistics/lottery_statistics_response_model.dart';

abstract class LotteryStatisticsState extends Equatable {
  const LotteryStatisticsState();

  @override
  List<Object?> get props => [];
}

class LotteryStatisticsInitial extends LotteryStatisticsState {
  const LotteryStatisticsInitial();
}

class LotteryStatisticsLoading extends LotteryStatisticsState {
  const LotteryStatisticsLoading();
}

class LotteryStatisticsLoaded extends LotteryStatisticsState {
  final LotteryStatisticsResponseModel data;

  const LotteryStatisticsLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class LotteryStatisticsError extends LotteryStatisticsState {
  final String message;

  const LotteryStatisticsError(this.message);

  @override
  List<Object?> get props => [message];
}
