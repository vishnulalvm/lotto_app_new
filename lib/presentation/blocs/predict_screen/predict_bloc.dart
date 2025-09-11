import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotto_app/data/models/predict_screen/predict_request_model.dart';
import 'package:lotto_app/data/models/predict_screen/predict_response_model.dart';
import 'package:lotto_app/domain/usecases/predict_screen/predict_usecase.dart';
import 'package:lotto_app/presentation/blocs/predict_screen/predict_event.dart';
import 'package:lotto_app/presentation/blocs/predict_screen/predict_state.dart';

class PredictBloc extends Bloc<PredictEvent, PredictState> {
  final PredictUseCase _useCase;
  PredictResponseModel? _displayData;

  PredictBloc(this._useCase) : super(const PredictInitial()) {
    on<GetPredictionEvent>(_onGetPrediction);
    on<ClearPredictionEvent>(_onClearPrediction);
    on<GetPredictionDataEvent>(_onGetPredictionData);
  }

  Future<void> _onGetPrediction(
    GetPredictionEvent event,
    Emitter<PredictState> emit,
  ) async {
    try {
      // Don't show loading if we have display data
      if (_displayData == null) {
        emit(const PredictLoading());
      }

      final request = PredictRequestModel(
        peoplesPrediction: event.peoplesPrediction,
      );

      final userPrediction = await _useCase.execute(request);
      
      if (_displayData != null) {
        emit(PredictDataWithUserPrediction(
          displayData: _displayData!,
          userPrediction: userPrediction,
          selectedNumber: event.peoplesPrediction,
        ));
      } else {
        emit(PredictLoaded(userPrediction));
      }
    } catch (e) {
      if (_displayData != null) {
        // If we have display data, keep showing it but show error for user prediction
        emit(PredictDataLoaded(_displayData!));
      } else {
        emit(PredictError('Failed to get prediction: ${e.toString()}'));
      }
    }
  }

  Future<void> _onClearPrediction(
    ClearPredictionEvent event,
    Emitter<PredictState> emit,
  ) async {
    emit(const PredictInitial());
  }

  Future<void> _onGetPredictionData(
    GetPredictionDataEvent event,
    Emitter<PredictState> emit,
  ) async {
    try {
      emit(const PredictLoading());
      final result = await _useCase.getPredictionData();
      _displayData = result;
      emit(PredictDataLoaded(result));
    } catch (e) {
      emit(PredictError('Failed to get prediction data: ${e.toString()}'));
    }
  }
}