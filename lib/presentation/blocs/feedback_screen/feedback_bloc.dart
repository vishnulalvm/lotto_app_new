import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotto_app/data/repositories/feedback_screen/feedback_repository.dart';
import 'package:lotto_app/presentation/blocs/feedback_screen/feedback_event.dart';
import 'package:lotto_app/presentation/blocs/feedback_screen/feedback_state.dart';

class FeedbackBloc extends Bloc<FeedbackEvent, FeedbackState> {
  final FeedbackRepository repository;

  FeedbackBloc({required this.repository}) : super(FeedbackInitial()) {
    on<SubmitFeedbackEvent>(_onSubmitFeedback);
  }

  Future<void> _onSubmitFeedback(
    SubmitFeedbackEvent event,
    Emitter<FeedbackState> emit,
  ) async {
    emit(FeedbackLoading());
    try {
      final success = await repository.submitFeedback(
        phoneNumber: event.phoneNumber,
        screenName: event.screenName,
        message: event.message,
      );

      if (success) {
        emit(FeedbackSuccess());
      } else {
        emit(FeedbackError(errorMessage: 'Failed to submit feedback'));
      }
    } catch (e) {
      emit(FeedbackError(errorMessage: e.toString()));
    }
  }
}
