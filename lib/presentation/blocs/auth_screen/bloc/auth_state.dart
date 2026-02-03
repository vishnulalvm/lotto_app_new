import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  final String phoneNumber;
  final String? name;
  final String message;

  const AuthSuccess({
    required this.phoneNumber,
    this.name,
    required this.message,
  });

  @override
  List<Object?> get props => [phoneNumber, name, message];
}

class AuthFailure extends AuthState {
  final String error;

  const AuthFailure(this.error);

  @override
  List<Object?> get props => [error];
}
