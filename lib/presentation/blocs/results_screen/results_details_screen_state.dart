import 'package:lotto_app/data/models/results_screen/results_screen.dart';

abstract class LotteryResultDetailsState {}

class LotteryResultDetailsInitial extends LotteryResultDetailsState {}

class LotteryResultDetailsLoading extends LotteryResultDetailsState {}

class LotteryResultDetailsLoaded extends LotteryResultDetailsState {
  final LotteryResultDetailsModel data;

  LotteryResultDetailsLoaded(this.data);

  @override
  String toString() => 'LotteryResultDetailsLoaded(lotteryName: ${data.result.lotteryName})';
}

class LotteryResultDetailsError extends LotteryResultDetailsState {
  final String message;

  LotteryResultDetailsError(this.message);

  @override
  String toString() => 'LotteryResultDetailsError(message: $message)';
}
