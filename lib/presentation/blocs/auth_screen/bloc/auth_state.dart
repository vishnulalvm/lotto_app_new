abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String phoneNumber;
  final String? name;
  final String message;

  AuthSuccess({
    required this.phoneNumber,
    this.name,
    required this.message,
  });
}

class AuthFailure extends AuthState {
  final String error;
  AuthFailure(this.error);
}
