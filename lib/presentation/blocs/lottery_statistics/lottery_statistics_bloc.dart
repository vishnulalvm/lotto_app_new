import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotto_app/domain/usecases/lottery_statistics/lottery_statistics_usecase.dart';
import 'package:lotto_app/presentation/blocs/lottery_statistics/lottery_statistics_event.dart';
import 'package:lotto_app/presentation/blocs/lottery_statistics/lottery_statistics_state.dart';

class LotteryStatisticsBloc extends Bloc<LotteryStatisticsEvent, LotteryStatisticsState> {
  final LotteryStatisticsUseCase useCase;

  LotteryStatisticsBloc({required this.useCase}) : super(LotteryStatisticsInitial()) {
    on<LoadLotteryStatistics>(_onLoadLotteryStatistics);
    on<RefreshLotteryStatistics>(_onRefreshLotteryStatistics);
  }

  Future<void> _onLoadLotteryStatistics(
    LoadLotteryStatistics event,
    Emitter<LotteryStatisticsState> emit,
  ) async {
    emit(LotteryStatisticsLoading());
    try {
      final response = await useCase.execute(
        userId: event.userId,
        onBackgroundRefreshComplete: (freshData) {
          // Update the state with fresh data when background refresh completes
          if (!emit.isDone) {
            emit(LotteryStatisticsLoaded(freshData));
          }
        },
      );
      emit(LotteryStatisticsLoaded(response));
    } catch (e) {
      emit(LotteryStatisticsError(e.toString()));
    }
  }

  Future<void> _onRefreshLotteryStatistics(
    RefreshLotteryStatistics event,
    Emitter<LotteryStatisticsState> emit,
  ) async {
    try {
      final response = await useCase.execute(
        userId: event.userId,
        forceRefresh: true,
      );
      emit(LotteryStatisticsLoaded(response));
    } catch (e) {
      emit(LotteryStatisticsError(e.toString()));
    }
  }
}