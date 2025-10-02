import 'package:equatable/equatable.dart';

abstract class PredictEvent extends Equatable {
  const PredictEvent();

  @override
  List<Object?> get props => [];
}

class GetPredictionEvent extends PredictEvent {
  final String peoplesPrediction;

  const GetPredictionEvent({
    required this.peoplesPrediction,
  });

  @override
  List<Object?> get props => [peoplesPrediction];
}

class ClearPredictionEvent extends PredictEvent {
  const ClearPredictionEvent();
}

class GetPredictionDataEvent extends PredictEvent {
  const GetPredictionDataEvent();
}

class UpdatePredictionDataEvent extends PredictEvent {
  const UpdatePredictionDataEvent();
}