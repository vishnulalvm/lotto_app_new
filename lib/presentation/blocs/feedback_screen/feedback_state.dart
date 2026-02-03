import 'package:equatable/equatable.dart';

abstract class FeedbackState extends Equatable {
  const FeedbackState();

  @override
  List<Object?> get props => [];
}

class FeedbackInitial extends FeedbackState {
  const FeedbackInitial();
}

class FeedbackLoading extends FeedbackState {
  const FeedbackLoading();
}

class FeedbackSuccess extends FeedbackState {
  final String message;

  const FeedbackSuccess({this.message = 'Feedback submitted successfully'});

  @override
  List<Object?> get props => [message];
}

class FeedbackError extends FeedbackState {
  final String errorMessage;

  const FeedbackError({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
