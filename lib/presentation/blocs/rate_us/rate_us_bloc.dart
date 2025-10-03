import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotto_app/data/repositories/rate_us/rate_us_repository.dart';
import 'package:lotto_app/presentation/blocs/rate_us/rate_us_event.dart';
import 'package:lotto_app/presentation/blocs/rate_us/rate_us_state.dart';

class RateUsBloc extends Bloc<RateUsEvent, RateUsState> {
  final RateUsRepository _repository;
  static const int _rateUsShowThreshold = 3;

  RateUsBloc(this._repository) : super(RateUsInitial()) {
    on<CheckRateUsDialogEvent>(_onCheckRateUsDialog);
    on<RateUsNotNowEvent>(_onRateUsNotNow);
    on<RateUsContinueEvent>(_onRateUsContinue);
  }

  Future<void> _onCheckRateUsDialog(
    CheckRateUsDialogEvent event,
    Emitter<RateUsState> emit,
  ) async {
    try {
      // Check if permanently dismissed
      final isPermanentlyDismissed = await _repository.isPermanentlyDismissed();
      if (isPermanentlyDismissed) {
        emit(RateUsHideDialog());
        return;
      }

      // Increment visit count
      await _repository.incrementVisitCount();
      final visitCount = await _repository.getVisitCount();

      // Show dialog on threshold visit
      if (visitCount == _rateUsShowThreshold) {
        emit(RateUsShowDialog());
      } else {
        emit(RateUsHideDialog());
      }
    } catch (e) {
      // Silent fail - don't bother user with rate us errors
      emit(RateUsError(e.toString()));
    }
  }

  Future<void> _onRateUsNotNow(
    RateUsNotNowEvent event,
    Emitter<RateUsState> emit,
  ) async {
    try {
      // Reset counter so they see it again after 3 more visits
      await _repository.resetVisitCount();
      emit(RateUsHideDialog());
    } catch (e) {
      emit(RateUsError(e.toString()));
    }
  }

  Future<void> _onRateUsContinue(
    RateUsContinueEvent event,
    Emitter<RateUsState> emit,
  ) async {
    try {
      // Permanently dismiss
      await _repository.markPermanentlyDismissed();
      emit(RateUsHideDialog());
    } catch (e) {
      emit(RateUsError(e.toString()));
    }
  }
}
