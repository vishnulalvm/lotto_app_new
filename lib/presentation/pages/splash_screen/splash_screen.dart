import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lotto_app/data/services/hive_service.dart';
import 'package:lotto_app/data/services/connectivity_service.dart';
import 'package:lotto_app/data/services/cache_manager.dart';
import 'package:lotto_app/data/services/save_results.dart';
import 'package:lotto_app/data/services/analytics_service.dart';
import 'package:lotto_app/data/services/firebase_messaging_service.dart';
import 'package:lotto_app/data/services/admob_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _scaleController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Phase 1: Critical services only
      await HiveService.init();
      
      // Phase 2: Essential services in parallel
      await Future.wait([
        ConnectivityService().initialize(),
        SavedResultsService.init(),
      ]);
      
      // Phase 3: Navigate early to prevent UI blocking
      await Future.delayed(const Duration(milliseconds: 1500));
      await _checkLoginStatus();
      
      // Phase 4: Initialize remaining services in background after navigation
      unawaited(_initializeBackgroundServices());
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🚨 Splash screen initialization error: $e');
      }
      
      // Still proceed to navigate
      await Future.delayed(const Duration(milliseconds: 1000));
      await _checkLoginStatus();
    }
  }
  
  /// Initialize heavy services in background after navigation
  Future<void> _initializeBackgroundServices() async {
    try {
      // Run heavy services after navigation
      await Future.wait([
        AnalyticsService.initialize(),
        FirebaseMessagingService.initialize(),
        _initializeAdMobServices(),
      ]);
      
      CacheManager.initialize();
      
      if (kDebugMode) {
        debugPrint('✅ Background services initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Background services failed: $e');
      }
    }
  }

  Future<void> _initializeAdMobServices() async {
    try {
      // Initialize AdMob service
      await AdMobService.initialize();
      
      // Create notification channel in parallel
      unawaited(_createNotificationChannel());
      
      // Preload ads with longer delay to prevent blocking
      unawaited(Future.delayed(const Duration(seconds: 3), () {
        AdMobService.instance.preloadAds();
      }));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ AdMob initialization failed: $e');
      }
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
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Notification channel creation failed: $e');
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 Checking login status...');
      }
      
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      
      if (kDebugMode) {
        debugPrint('🔑 Login status: $isLoggedIn');
      }
      
      if (!mounted) {
        if (kDebugMode) {
          debugPrint('⚠️ Widget not mounted, skipping navigation');
        }
        return;
      }
      
      if (isLoggedIn) {
        if (kDebugMode) {
          debugPrint('🏠 Navigating to home screen');
        }
        context.go('/');
      } else {
        if (kDebugMode) {
          debugPrint('🔐 Navigating to login screen');
        }
        context.go('/login');
      }
      
      if (kDebugMode) {
        debugPrint('✅ Navigation completed from splash screen');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🚨 Error in _checkLoginStatus: $e');
      }
      
      if (mounted) {
        if (kDebugMode) {
          debugPrint('🔄 Fallback navigation to login');
        }
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated app logo with scaling
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Image.asset(
                        'assets/icons/logo_foreground.png',
                        width: 200,
                        height: 200,
                        cacheWidth: 200,
                        cacheHeight: 200,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Text(
                        'LOTTO',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Company name at bottom center
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'SOLID APPS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}