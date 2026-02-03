import 'package:equatable/equatable.dart';

abstract class FeedbackEvent extends Equatable {
  const FeedbackEvent();

  @override
  List<Object?> get props => [];
}

class SubmitFeedbackEvent extends FeedbackEvent {
  final String phoneNumber;
  final String screenName;
  final String message;

  const SubmitFeedbackEvent({
    required this.phoneNumber,
    required this.screenName,
    required this.message,
  });

  @override
  List<Object?> get props => [phoneNumber, screenName, message];
}
