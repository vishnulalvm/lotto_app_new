import 'package:equatable/equatable.dart';
import 'package:lotto_app/data/models/probability_screen/probability_request_model.dart';

abstract class ProbabilityEvent extends Equatable {
  const ProbabilityEvent();

  @override
  List<Object?> get props => [];
}

class GetProbabilityEvent extends ProbabilityEvent {
  final ProbabilityRequestModel request;

  const GetProbabilityEvent({required this.request});

  @override
  List<Object?> get props => [request];
}

class GetProbabilityByLotteryNumberEvent extends ProbabilityEvent {
  final String lotteryNumber;

  const GetProbabilityByLotteryNumberEvent({required this.lotteryNumber});

  @override
  List<Object?> get props => [lotteryNumber];
}

class ResetProbabilityEvent extends ProbabilityEvent {
  const ResetProbabilityEvent();
}
