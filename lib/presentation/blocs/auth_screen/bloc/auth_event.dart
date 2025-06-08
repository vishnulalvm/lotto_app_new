// lib/presentation/bloc/auth/auth_event.dart
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