import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotto_app/data/repositories/auth_screen/auth_repository.dart';
import 'package:lotto_app/presentation/blocs/auth_screen/bloc/auth_event.dart';
import 'package:lotto_app/presentation/blocs/auth_screen/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;

  AuthBloc({required this.repository}) : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthCheckStatus>(_onCheckStatus);
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

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await repository.logout();
      emit(AuthInitial());
    } catch (e) {
      emit(AuthFailure('Logout failed: ${e.toString()}'));
    }
  }

  Future<void> _onCheckStatus(
    AuthCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final isLoggedIn = await repository.isLoggedIn();
      if (isLoggedIn) {
        final user = await repository.getCurrentUser();
        if (user != null) {
          emit(AuthSuccess(
            phoneNumber: user.phoneNumber,
            name: user.name,
            message: 'Already logged in',
          ));
        } else {
          emit(AuthInitial());
        }
      } else {
        emit(AuthInitial());
      }
    } catch (e) {
      emit(AuthInitial());
    }
  }
}
