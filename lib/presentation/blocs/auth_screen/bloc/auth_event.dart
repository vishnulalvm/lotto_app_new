abstract class AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String phoneNumber;
  AuthLoginRequested(this.phoneNumber);
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String phoneNumber;
  AuthRegisterRequested(this.name, this.phoneNumber);
}

class AuthLogoutRequested extends AuthEvent {}

class AuthCheckStatus extends AuthEvent {}

class AuthAutoSignInRequested extends AuthEvent {
  final String name;
  final String phoneNumber;
  AuthAutoSignInRequested(this.name, this.phoneNumber);
}
