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

class PredictDataLoaded extends PredictState {
  final PredictResponseModel displayData;

  const PredictDataLoaded(this.displayData);

  @override
  List<Object?> get props => [displayData];
}

class PredictDataWithUserPrediction extends PredictState {
  final PredictResponseModel displayData;
  final PredictResponseModel userPrediction;
  final String selectedNumber;

  const PredictDataWithUserPrediction({
    required this.displayData,
    required this.userPrediction, 
    required this.selectedNumber,
  });

  @override
  List<Object?> get props => [displayData, userPrediction, selectedNumber];
}

class PredictError extends PredictState {
  final String message;

  const PredictError(this.message);

  @override
  List<Object?> get props => [message];
}