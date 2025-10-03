abstract class RateUsEvent {}

/// Event to check if rate us dialog should be shown
class CheckRateUsDialogEvent extends RateUsEvent {
  @override
  String toString() => 'CheckRateUsDialogEvent()';
}

/// Event when user taps "Not Now"
class RateUsNotNowEvent extends RateUsEvent {
  @override
  String toString() => 'RateUsNotNowEvent()';
}

/// Event when user taps "Continue" to rate
class RateUsContinueEvent extends RateUsEvent {
  @override
  String toString() => 'RateUsContinueEvent()';
}
