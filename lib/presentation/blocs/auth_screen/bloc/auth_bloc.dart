import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotto_app/data/repositories/auth_screen/auth_repository.dart';
import 'package:lotto_app/presentation/blocs/auth_screen/bloc/auth_event.dart';
import 'package:lotto_app/presentation/blocs/auth_screen/bloc/auth_state.dart';
import 'package:lotto_app/data/services/firebase_messaging_service.dart';
import 'dart:developer' as developer;

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;

  AuthBloc({required this.repository}) : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthAutoSignInRequested>(_onAutoSignIn);
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await repository.login(event.phoneNumber);

      // Register FCM token after successful login
      await _registerFcmToken('login');

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

      // Register FCM token after successful registration
      await _registerFcmToken('register');

      emit(AuthSuccess(
        phoneNumber: user.phoneNumber,
        name: user.name,
        message: user.message ?? 'Registration successful',
      ));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  /// Helper method to register FCM token with logging
  Future<void> _registerFcmToken(String source) async {
    try {
      developer.log('Attempting FCM token registration from: $source',
          name: 'AuthBloc');

      final success = await FirebaseMessagingService.registerToken(
        notificationsEnabled: true,
      );

      if (success) {
        developer.log('FCM token registered successfully from: $source',
            name: 'AuthBloc');
      } else {
        developer.log('FCM token registration failed from: $source',
            name: 'AuthBloc');
      }
    } catch (e) {
      developer.log('FCM token registration error from: $source - $e',
          name: 'AuthBloc', error: e);
      // Don't throw - allow authentication to succeed even if FCM registration fails
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

  Future<void> _onAutoSignIn(
    AuthAutoSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // First try to register the user
      final user = await repository.register(event.name, event.phoneNumber);

      // Register FCM token after successful registration
      await _registerFcmToken('autoSignIn-register');

      emit(AuthSuccess(
        phoneNumber: user.phoneNumber,
        name: user.name,
        message: user.message ?? 'Registration successful',
      ));
    } catch (e) {
      // Check if the error is due to user already existing
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('user with this phone number already exists') ||
          errorString.contains('phone_number') ||
          errorString.contains('already exists')) {
        // User exists, try to sign in instead
        try {
          final user = await repository.login(event.phoneNumber);

          // Register FCM token after successful login
          await _registerFcmToken('autoSignIn-login');

          emit(AuthSuccess(
            phoneNumber: user.phoneNumber,
            name: user.name,
            message: user.message ?? 'Welcome back!',
          ));
        } catch (loginError) {
          emit(AuthFailure(loginError.toString()));
        }
      } else {
        // Other registration error, show original error
        emit(AuthFailure(e.toString()));
      }
    }
  }
}
