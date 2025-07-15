import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotto_app/domain/usecases/results_screen/results_screen.dart';
import 'package:lotto_app/presentation/blocs/results_screen/results_details_screen_event.dart';
import 'package:lotto_app/presentation/blocs/results_screen/results_details_screen_state.dart';

class LotteryResultDetailsBloc
    extends Bloc<LotteryResultDetailsEvent, LotteryResultDetailsState> {
  final LotteryResultDetailsUseCase _useCase;

  // Store current unique ID for refresh functionality
  String? _currentUniqueId;
  
  // Timer for live hour background refresh
  Timer? _liveRefreshTimer;

  LotteryResultDetailsBloc(this._useCase)
      : super(LotteryResultDetailsInitial()) {
    on<LoadLotteryResultDetailsEvent>(_onLoadLotteryResultDetails);
    on<RefreshLotteryResultDetailsEvent>(_onRefreshLotteryResultDetails);
    on<BackgroundRefreshResultDetailsEvent>(_onBackgroundRefreshResultDetails);
  }

  @override
  Future<void> close() {
    _liveRefreshTimer?.cancel();
    return super.close();
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
      
      // Start live refresh timer if in live hours
      _startLiveRefreshTimer();
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
      final result = await _useCase.execute(event.uniqueId, forceRefresh: true);
      emit(LotteryResultDetailsLoaded(result));
      
      // Restart live refresh timer
      _startLiveRefreshTimer();
    } catch (e) {
      emit(LotteryResultDetailsError(
          'Failed to refresh lottery result: ${e.toString()}'));
    }
  }

  Future<void> _onBackgroundRefreshResultDetails(
    BackgroundRefreshResultDetailsEvent event,
    Emitter<LotteryResultDetailsState> emit,
  ) async {
    try {
      // Only refresh if we have a current uniqueId
      if (_currentUniqueId != null) {
        final result = await _useCase.execute(_currentUniqueId!, forceRefresh: true);
        emit(LotteryResultDetailsLoaded(result));
      }
    } catch (e) {
      // Silently fail for background refresh
    }
  }

  void _startLiveRefreshTimer() {
    _liveRefreshTimer?.cancel();
    
    final now = DateTime.now();
    final isLiveHour = now.hour >= 15 && now.hour < 16;
    
    if (isLiveHour) {
      // During live hours, refresh every 30 seconds
      _liveRefreshTimer = Timer.periodic(
        const Duration(seconds: 30),
        (timer) {
          final currentTime = DateTime.now();
          final stillLiveHour = currentTime.hour >= 15 && currentTime.hour < 16;
          
          if (stillLiveHour) {
            add(BackgroundRefreshResultDetailsEvent());
          } else {
            // Stop timer if no longer in live hours
            timer.cancel();
          }
        },
      );
    }
  }

  // Helper method to refresh current result
  void refreshCurrentResult() {
    if (_currentUniqueId != null) {
      add(RefreshLotteryResultDetailsEvent(_currentUniqueId!));
    }
  }

  // Helper method to clear cache
  Future<void> clearCache() async {
    if (_currentUniqueId != null) {
      await _useCase.clearCache(_currentUniqueId!);
    }
  }
}
