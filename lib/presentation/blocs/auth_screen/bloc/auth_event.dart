import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String phoneNumber;

  const AuthLoginRequested(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String phoneNumber;

  const AuthRegisterRequested(this.name, this.phoneNumber);

  @override
  List<Object?> get props => [name, phoneNumber];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthCheckStatus extends AuthEvent {
  const AuthCheckStatus();
}

class AuthAutoSignInRequested extends AuthEvent {
  final String name;
  final String phoneNumber;

  const AuthAutoSignInRequested(this.name, this.phoneNumber);

  @override
  List<Object?> get props => [name, phoneNumber];
}
