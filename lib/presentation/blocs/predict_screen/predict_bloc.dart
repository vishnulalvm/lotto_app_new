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
    on<UpdatePredictionDataEvent>(_onUpdatePredictionData);
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
      // Try to get cached data first for immediate display
      final cachedData = await _useCase.getCachedPredictionData();

      if (cachedData != null) {
        // Show cached data immediately for smooth UI
        _displayData = cachedData;
        emit(PredictDataLoaded(cachedData));

        // Refresh in background
        _useCase.refreshPredictionDataInBackground().then((updatedData) {
          if (updatedData != null) {
            _displayData = updatedData;
            // Only emit new state if still in loaded state
            if (state is PredictDataLoaded || state is PredictDataWithUserPrediction) {
              add(const UpdatePredictionDataEvent());
            }
          }
        }).catchError((_) {
          // Silent fail for background refresh
        });
      } else {
        // No cache, show loading and fetch from API
        emit(const PredictLoading());
        final result = await _useCase.getPredictionData();
        _displayData = result;
        emit(PredictDataLoaded(result));
      }
    } catch (e) {
      emit(PredictError('Failed to get prediction data: ${e.toString()}'));
    }
  }

  Future<void> _onUpdatePredictionData(
    UpdatePredictionDataEvent event,
    Emitter<PredictState> emit,
  ) async {
    if (_displayData != null) {
      emit(PredictDataLoaded(_displayData!));
    }
  }
}