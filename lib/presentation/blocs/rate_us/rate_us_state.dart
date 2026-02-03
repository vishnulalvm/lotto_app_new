import 'package:equatable/equatable.dart';

abstract class RateUsState extends Equatable {
  const RateUsState();

  @override
  List<Object?> get props => [];
}

class RateUsInitial extends RateUsState {
  const RateUsInitial();
}

class RateUsLoading extends RateUsState {
  const RateUsLoading();
}

/// State when rate us dialog should be shown
class RateUsShowDialog extends RateUsState {
  const RateUsShowDialog();

  @override
  String toString() => 'RateUsShowDialog()';
}

/// State when rate us dialog should not be shown
class RateUsHideDialog extends RateUsState {
  const RateUsHideDialog();

  @override
  String toString() => 'RateUsHideDialog()';
}

/// State for errors (silent fail)
class RateUsError extends RateUsState {
  final String message;

  const RateUsError(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'RateUsError(message: $message)';
}
