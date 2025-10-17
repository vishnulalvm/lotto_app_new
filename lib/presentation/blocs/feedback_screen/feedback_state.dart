abstract class FeedbackState {}

class FeedbackInitial extends FeedbackState {}

class FeedbackLoading extends FeedbackState {}

class FeedbackSuccess extends FeedbackState {
  final String message;

  FeedbackSuccess({this.message = 'Feedback submitted successfully'});
}

class FeedbackError extends FeedbackState {
  final String errorMessage;

  FeedbackError({required this.errorMessage});
}
