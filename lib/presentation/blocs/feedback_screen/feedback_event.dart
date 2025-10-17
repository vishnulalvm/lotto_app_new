abstract class FeedbackEvent {}

class SubmitFeedbackEvent extends FeedbackEvent {
  final String phoneNumber;
  final String screenName;
  final String message;

  SubmitFeedbackEvent({
    required this.phoneNumber,
    required this.screenName,
    required this.message,
  });
}
