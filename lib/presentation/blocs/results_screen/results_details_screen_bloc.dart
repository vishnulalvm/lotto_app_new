import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotto_app/domain/usecases/results_screen/results_screen.dart';
import 'package:lotto_app/presentation/blocs/results_screen/results_details_screen_event.dart';
import 'package:lotto_app/presentation/blocs/results_screen/results_details_screen_state.dart';

class LotteryResultDetailsBloc
    extends Bloc<LotteryResultDetailsEvent, LotteryResultDetailsState> {
  final LotteryResultDetailsUseCase _useCase;

  // Store current unique ID for refresh functionality
  String? _currentUniqueId;

  LotteryResultDetailsBloc(this._useCase)
      : super(LotteryResultDetailsInitial()) {
    on<LoadLotteryResultDetailsEvent>(_onLoadLotteryResultDetails);
    on<RefreshLotteryResultDetailsEvent>(_onRefreshLotteryResultDetails);
  }

  Future<void> _onLoadLotteryResultDetails(
    LoadLotteryResultDetailsEvent event,
    Emitter<LotteryResultDetailsState> emit,
  ) async {
    try {
      emit(LotteryResultDetailsLoading());
      _currentUniqueId = event.uniqueId;
      final result = await _useCase.execute(event.uniqueId);
      emit(LotteryResultDetailsLoaded(result));
    } catch (e) {
      emit(LotteryResultDetailsError(
          'Failed to load lottery result: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshLotteryResultDetails(
    RefreshLotteryResultDetailsEvent event,
    Emitter<LotteryResultDetailsState> emit,
  ) async {
    try {
      // Don't show loading for refresh
      _currentUniqueId = event.uniqueId;
      final result = await _useCase.execute(event.uniqueId);
      emit(LotteryResultDetailsLoaded(result));
    } catch (e) {
      emit(LotteryResultDetailsError(
          'Failed to refresh lottery result: ${e.toString()}'));
    }
  }

  // Helper method to refresh current result
  void refreshCurrentResult() {
    if (_currentUniqueId != null) {
      add(RefreshLotteryResultDetailsEvent(_currentUniqueId!));
    }
  }
}
