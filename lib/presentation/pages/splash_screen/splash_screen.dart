import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lotto_app/data/services/hive_service.dart';
import 'package:lotto_app/data/services/connectivity_service.dart';
import 'package:lotto_app/data/services/cache_manager.dart';
import 'package:lotto_app/data/services/save_results.dart';
import 'package:lotto_app/data/services/analytics_service.dart';
import 'package:lotto_app/data/services/firebase_messaging_service.dart';
import 'package:lotto_app/data/services/admob_service.dart';
import 'package:lotto_app/data/services/user_service.dart';
import 'package:lotto_app/data/services/audio_service.dart';
import 'package:lotto_app/data/services/app_update_service.dart';
import 'package:lotto_app/core/constants/timing_constants.dart';
import 'package:lotto_app/core/di/service_locator.dart';
import 'package:lotto_app/presentation/blocs/auth_screen/bloc/auth_bloc.dart';
import 'package:lotto_app/presentation/blocs/auth_screen/bloc/auth_event.dart';
import 'package:lotto_app/presentation/blocs/auth_screen/bloc/auth_state.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

@immutable
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Phase 1: Initialize CRITICAL services required for app to function
      // These must complete before navigation
      // Note: AudioService is already registered via DI, just initialize it here
      await Future.wait([
        HiveService.init(), // Required for cache and user data
        getIt<AudioService>().initialize(), // Audio service for UI feedback
      ]);

      // Warm up audio in background (non-blocking)
      unawaited(getIt<AudioService>().ensureWarmedUp());

      // Phase 2: Check login status (requires Hive to be initialized)
      await _checkLoginStatus();

      // Phase 3: Initialize all other services in background AFTER navigation
      unawaited(_initializeBackgroundServices());
    } catch (e) {
      // Graceful degradation: navigate even if services fail
      await _checkLoginStatus();
      unawaited(_initializeBackgroundServices());
    }
  }

  /// Initialize all non-critical services in background after navigation
  /// Services are staggered to prevent UI jank and spread CPU load
  Future<void> _initializeBackgroundServices() async {
    try {
      // Phase 1: Lightweight services - start immediately after navigation
      unawaited(getIt<ConnectivityService>().initialize().catchError((e) {}));
      unawaited(SavedResultsService.init().catchError((e) {}));

      // Phase 2: Analytics - using timing constant
      unawaited(Future.delayed(TimingConstants.analyticsInitDelay, () {
        AnalyticsService.initialize().catchError((e) {});
      }));

      // Phase 3: App updates check - using timing constant
      unawaited(Future.delayed(TimingConstants.appUpdateInitDelay, () {
        AppUpdateService().initialize().catchError((e) {});
      }));

      // Phase 4: FCM initialization - using timing constant
      unawaited(Future.delayed(TimingConstants.fcmInitDelay, () {
        FirebaseMessagingService.initialize().catchError((e) {});
      }));

      // Phase 5: AdMob services - using timing constant
      unawaited(Future.delayed(TimingConstants.adMobInitDelay, () {
        _initializeAdMobServices().catchError((e) {});
      }));

      // Phase 6: Cache manager - using timing constant
      unawaited(Future.delayed(TimingConstants.cacheManagerInitDelay, () {
        try {
          CacheManager.initialize();
        } catch (e) {
          // Ignore cache initialization errors - non-critical background task
        }
      }));

      // Phase 7: User activity tracking - using timing constant
      unawaited(Future.delayed(TimingConstants.userActivityInitDelay, () {
        getIt<UserService>().trackActivity().catchError((e) => false);
      }));
    } catch (e) {
      // Silent fail - background services are non-critical
    }
  }

  Future<void> _initializeAdMobServices() async {
    try {
      // Initialize AdMob service
      await AdMobService.initialize();

      // Create notification channel in parallel (non-blocking)
      unawaited(_createNotificationChannel().catchError((e) {
        // Ignore notification channel creation errors
      }));
    } catch (e) {
      // Ignore AdMob services initialization errors
    }
  }

  Future<void> _createNotificationChannel() async {
    try {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'default_channel',
        'Default Notifications',
        description: 'Channel for default notifications',
        importance: Importance.high,
      );

      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
      // Ignore notification channel creation errors
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final userService = getIt<UserService>();
      final isLoggedIn = await userService.isLoggedIn();

      if (!mounted) {
        return;
      }

      if (isLoggedIn) {
        context.go('/');
      } else {
        // Auto-login for new users
        await _performAutoLogin();
      }
    } catch (e) {
      if (mounted) {
        // On error, try auto-login anyway
        await _performAutoLogin();
      }
    }
  }

  /// Performs automatic login for first-time users
  /// Generates unique phone number based on current timestamp: YYYYMMDDHHMMSS
  Future<void> _performAutoLogin() async {
    try {
      if (!mounted) return;

      // Generate unique phone number using current timestamp
      final now = DateTime.now();
      final phoneNumber = '${now.year}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}';

      // Trigger auto-login through AuthBloc
      final authBloc = context.read<AuthBloc>();
      authBloc.add(AuthAutoSignInRequested(
        'Unknown',
        phoneNumber,
      ));

      // Wait for authentication result
      await for (final state in authBloc.stream) {
        if (state is AuthSuccess) {
          if (mounted) context.go('/');
          break;
        } else if (state is AuthFailure) {
          // Even on failure, navigate to home (graceful degradation)
          if (mounted) context.go('/');
          break;
        }
      }
    } catch (e) {
      // Fallback: navigate to home anyway
      if (mounted) context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App logo
                  SvgPicture.asset(
                    'assets/icons/LOTTOSVG.svg',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'LOTTO',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Company name at bottom center
          Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: Text(
              'SOLID APPS',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
