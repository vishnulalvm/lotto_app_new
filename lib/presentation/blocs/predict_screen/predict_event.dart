import 'package:equatable/equatable.dart';

abstract class PredictEvent extends Equatable {
  const PredictEvent();

  @override
  List<Object?> get props => [];
}

class GetPredictionEvent extends PredictEvent {
  final String lotteryName;
  final String prizeType;

  const GetPredictionEvent({
    required this.lotteryName,
    required this.prizeType,
  });

  @override
  List<Object?> get props => [lotteryName, prizeType];
}

class ClearPredictionEvent extends PredictEvent {
  const ClearPredictionEvent();
}