import 'package:equatable/equatable.dart';
import 'package:lotto_app/data/models/predict_screen/predict_response_model.dart';

abstract class PredictState extends Equatable {
  const PredictState();

  @override
  List<Object?> get props => [];
}

class PredictInitial extends PredictState {
  const PredictInitial();
}

class PredictLoading extends PredictState {
  const PredictLoading();
}

class PredictLoaded extends PredictState {
  final PredictResponseModel prediction;

  const PredictLoaded(this.prediction);

  @override
  List<Object?> get props => [prediction];
}

class PredictError extends PredictState {
  final String message;

  const PredictError(this.message);

  @override
  List<Object?> get props => [message];
}