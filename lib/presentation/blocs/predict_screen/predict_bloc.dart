import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotto_app/data/models/predict_screen/predict_request_model.dart';
import 'package:lotto_app/domain/usecases/predict_screen/predict_usecase.dart';
import 'package:lotto_app/presentation/blocs/predict_screen/predict_event.dart';
import 'package:lotto_app/presentation/blocs/predict_screen/predict_state.dart';

class PredictBloc extends Bloc<PredictEvent, PredictState> {
  final PredictUseCase _useCase;

  PredictBloc(this._useCase) : super(const PredictInitial()) {
    on<GetPredictionEvent>(_onGetPrediction);
    on<ClearPredictionEvent>(_onClearPrediction);
  }

  Future<void> _onGetPrediction(
    GetPredictionEvent event,
    Emitter<PredictState> emit,
  ) async {
    try {
      emit(const PredictLoading());

      final request = PredictRequestModel(
        lotteryName: event.lotteryName,
        prizeType: event.prizeType,
      );

      final result = await _useCase.execute(request);
      emit(PredictLoaded(result));
    } catch (e) {
      emit(PredictError('Failed to get prediction: ${e.toString()}'));
    }
  }

  Future<void> _onClearPrediction(
    ClearPredictionEvent event,
    Emitter<PredictState> emit,
  ) async {
    emit(const PredictInitial());
  }
}