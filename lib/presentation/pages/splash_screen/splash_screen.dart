import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lotto_app/data/services/hive_service.dart';
import 'package:lotto_app/data/services/connectivity_service.dart';
import 'package:lotto_app/data/services/cache_manager.dart';
import 'package:lotto_app/data/services/save_results.dart';
import 'package:lotto_app/data/services/analytics_service.dart';
import 'package:lotto_app/data/services/firebase_messaging_service.dart';
import 'package:lotto_app/data/services/admob_service.dart';
import 'package:lotto_app/data/services/user_service.dart';
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
        debugPrint('ConnectivityService init failed: $e');
      }));

      // Phase 2: Initialize essential app services
      unawaited(SavedResultsService.init().catchError((e) {
        debugPrint('SavedResultsService init failed: $e');
      }));

      // Phase 3: Initialize heavy services with delays to spread CPU load
      unawaited(Future.delayed(const Duration(milliseconds: 100), () {
        AnalyticsService.initialize().catchError((e) {
          debugPrint('AnalyticsService init failed: $e');
        });
      }));

      unawaited(Future.delayed(const Duration(milliseconds: 200), () {
        FirebaseMessagingService.initialize().catchError((e) {
          debugPrint('FirebaseMessaging init failed: $e');
        });
      }));

      unawaited(Future.delayed(const Duration(milliseconds: 300), () {
        _initializeAdMobServices().catchError((e) {
          debugPrint('AdMob services init failed: $e');
        });
      }));

      // Phase 4: Initialize cache manager last (least critical)
      unawaited(Future.delayed(const Duration(milliseconds: 400), () {
        try {
          CacheManager.initialize();
        } catch (e) {
          debugPrint('CacheManager init failed: $e');
        }
      }));
    } catch (e) {
      debugPrint('Background services initialization failed: $e');
    }
  }

  Future<void> _initializeAdMobServices() async {
    try {
      // Initialize AdMob service
      await AdMobService.initialize();

      // Create notification channel in parallel (non-blocking)
      unawaited(_createNotificationChannel().catchError((e) {
        debugPrint('Notification channel creation failed: $e');
      }));

      // Preload ads with even more delay to not impact initial UX
      unawaited(Future.delayed(const Duration(seconds: 2), () {
        _preloadAdsInBackground();
      }));
    } catch (e) {
      debugPrint('AdMob services initialization failed: $e');
    }
  }
  
  void _preloadAdsInBackground() async {
    try {
      // Preload high-priority ads with error handling
      await AdMobService.instance.preloadAds().catchError((e) {
        debugPrint('Primary ad preload failed: $e');
      });
      
      // Additional delay to ensure app is fully settled
      await Future.delayed(const Duration(seconds: 2));
      
      // Preload specific ads for key screens
      await AdMobService.instance.preloadAds(
        adTypes: ['home_results', 'predict_interstitial'],
      ).catchError((e) {
        debugPrint('Specific ad preload failed: $e');
      });
      
      debugPrint('✅ Background ad preload completed');
    } catch (e) {
      debugPrint('❌ Ad preload failed: $e');
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
      
      debugPrint('✅ Notification channel created');
    } catch (e) {
      debugPrint('❌ Notification channel creation failed: $e');
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
        context.go('/login');
      }

    } catch (e) {
      if (mounted) {
        context.go('/login');
      }
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
