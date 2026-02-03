import 'package:equatable/equatable.dart';

abstract class RateUsEvent extends Equatable {
  const RateUsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to check if rate us dialog should be shown
class CheckRateUsDialogEvent extends RateUsEvent {
  const CheckRateUsDialogEvent();

  @override
  String toString() => 'CheckRateUsDialogEvent()';
}

/// Event when user taps "Not Now"
class RateUsNotNowEvent extends RateUsEvent {
  const RateUsNotNowEvent();

  @override
  String toString() => 'RateUsNotNowEvent()';
}

/// Event when user taps "Continue" to rate
class RateUsContinueEvent extends RateUsEvent {
  const RateUsContinueEvent();

  @override
  String toString() => 'RateUsContinueEvent()';
}
