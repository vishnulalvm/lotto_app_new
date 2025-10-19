import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotto_app/domain/usecases/probability_screen/probability_usecase.dart';
import 'package:lotto_app/presentation/blocs/probability_screen/probability_event.dart';
import 'package:lotto_app/presentation/blocs/probability_screen/probability_state.dart';

class ProbabilityBloc extends Bloc<ProbabilityEvent, ProbabilityState> {
  final ProbabilityUseCase useCase;

  ProbabilityBloc({required this.useCase}) : super(ProbabilityInitial()) {
    on<GetProbabilityEvent>(_onGetProbability);
    on<GetProbabilityByLotteryNumberEvent>(_onGetProbabilityByLotteryNumber);
    on<ResetProbabilityEvent>(_onResetProbability);
  }

  Future<void> _onGetProbability(
    GetProbabilityEvent event,
    Emitter<ProbabilityState> emit,
  ) async {
    emit(ProbabilityLoading());
    try {
      final response = await useCase.execute(event.request);
      emit(ProbabilityLoaded(response: response));
    } catch (e) {
      emit(ProbabilityError(message: e.toString()));
    }
  }

  Future<void> _onGetProbabilityByLotteryNumber(
    GetProbabilityByLotteryNumberEvent event,
    Emitter<ProbabilityState> emit,
  ) async {
    emit(ProbabilityLoading());
    try {
      final request = useCase.createRequest(event.lotteryNumber);
      final response = await useCase.execute(request);
      emit(ProbabilityLoaded(response: response));
    } catch (e) {
      emit(ProbabilityError(message: e.toString()));
    }
  }

  Future<void> _onResetProbability(
    ResetProbabilityEvent event,
    Emitter<ProbabilityState> emit,
  ) async {
    emit(ProbabilityInitial());
  }
}