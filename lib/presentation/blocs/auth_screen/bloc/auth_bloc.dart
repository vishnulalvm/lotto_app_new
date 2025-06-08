// lib/presentation/bloc/auth/auth_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotto_app/data/repositories/auth_screen/auth_repository.dart';
import 'package:lotto_app/presentation/blocs/auth_screen/bloc/auth_event.dart';
import 'package:lotto_app/presentation/blocs/auth_screen/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;

  AuthBloc({required this.repository}) : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await repository.login(event.phoneNumber);
      emit(AuthSuccess(
        phoneNumber: user.phoneNumber,
        name: user.name,
        message: user.message ?? 'Login successful',
      ));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await repository.register(event.name, event.phoneNumber);
      emit(AuthSuccess(
        phoneNumber: user.phoneNumber,
        name: user.name,
        message: user.message ?? 'Registration successful',
      ));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }
}
