import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lotto_app/data/services/hive_service.dart';
import 'package:lotto_app/data/services/connectivity_service.dart';
import 'package:lotto_app/data/services/cache_manager.dart';
import 'package:lotto_app/data/services/save_results.dart';
import 'package:lotto_app/data/services/analytics_service.dart';
import 'package:lotto_app/data/services/firebase_messaging_service.dart';
import 'package:lotto_app/data/services/admob_service.dart';
import 'package:lotto_app/data/services/user_service.dart';
import 'package:lotto_app/presentation/blocs/auth_screen/bloc/auth_bloc.dart';
import 'package:lotto_app/presentation/blocs/auth_screen/bloc/auth_event.dart';
import 'package:lotto_app/presentation/blocs/auth_screen/bloc/auth_state.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasPreloadedImages = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Move precache to didChangeDependencies where MediaQuery is available
    if (!_hasPreloadedImages) {
      _precacheImages();
      _hasPreloadedImages = true;
    }
  }

  void _precacheImages() {
    // Precache logo to improve initial loading
    precacheImage(
      const AssetImage('assets/icons/logo_foreground.png'),
      context,
    );
  }


  Future<void> _initializeApp() async {
    try {
      // Phase 1: Only the most critical service for navigation
      await HiveService.init();

      // Phase 2: Navigate immediately - everything else is background
      await _checkLoginStatus();

      // Phase 3: Initialize all other services in background after navigation
      unawaited(_initializeBackgroundServices());
    } catch (e) {
      // Still navigate even if critical services fail
      await _checkLoginStatus();
      // Try background services anyway
      unawaited(_initializeBackgroundServices());
    }
  }

  /// Initialize all non-critical services in background after navigation
  Future<void> _initializeBackgroundServices() async {
    try {
      // Phase 1: Start connectivity service (needed for cache decisions)
      unawaited(ConnectivityService().initialize().catchError((e) {
        // Ignore connectivity service init errors
      }));

      // Phase 2: Initialize essential app services
      unawaited(SavedResultsService.init().catchError((e) {
        // Ignore saved results service init errors
      }));

      // Phase 3: Initialize heavy services with delays to spread CPU load
      unawaited(Future.delayed(const Duration(milliseconds: 100), () {
        AnalyticsService.initialize().catchError((e) {
          // Ignore analytics service init errors
        });
      }));

      unawaited(Future.delayed(const Duration(milliseconds: 200), () {
        FirebaseMessagingService.initialize().catchError((e) {
          // Ignore firebase messaging init errors
        });
      }));

      unawaited(Future.delayed(const Duration(milliseconds: 300), () {
        _initializeAdMobServices().catchError((e) {
          // Ignore AdMob services init errors
        });
      }));

      // Phase 4: Initialize cache manager last (least critical)
      unawaited(Future.delayed(const Duration(milliseconds: 400), () {
        try {
          CacheManager.initialize();
        } catch (e) {
          // Ignore cache manager init errors
        }
      }));

      // Phase 5: Track user activity (non-blocking, least critical)
      unawaited(Future.delayed(const Duration(milliseconds: 500), () {
        UserService().trackActivity().catchError((e) {
          // Ignore tracking errors
          return false;
        });
      }));
    } catch (e) {
      // Ignore background services initialization errors
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
      final userService = UserService();
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
                    Image.asset(
                      'assets/icons/logo_foreground.png',
                      width: 200,
                      height: 200,
                      cacheWidth: 400, // 2x for better quality on high DPI
                      cacheHeight: 400,
                      filterQuality: FilterQuality.low, // Faster loading
                      fit: BoxFit.contain,
                      isAntiAlias: true,
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
