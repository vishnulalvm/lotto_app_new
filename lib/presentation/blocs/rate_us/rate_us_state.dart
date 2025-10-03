abstract class RateUsState {}

class RateUsInitial extends RateUsState {}

class RateUsLoading extends RateUsState {}

/// State when rate us dialog should be shown
class RateUsShowDialog extends RateUsState {
  @override
  String toString() => 'RateUsShowDialog()';
}

/// State when rate us dialog should not be shown
class RateUsHideDialog extends RateUsState {
  @override
  String toString() => 'RateUsHideDialog()';
}

/// State for errors (silent fail)
class RateUsError extends RateUsState {
  final String message;

  RateUsError(this.message);

  @override
  String toString() => 'RateUsError(message: $message)';
}
