import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lotto_app/data/services/hive_service.dart';
import 'package:lotto_app/data/services/connectivity_service.dart';
import 'package:lotto_app/data/services/cache_manager.dart';
import 'package:lotto_app/data/services/save_results.dart';
import 'package:lotto_app/data/services/analytics_service.dart';
import 'package:lotto_app/data/services/firebase_messaging_service.dart';

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
    // Initialize services in background without blocking UI
    try {
      // Phase 1: Initialize Hive first (required for other services)
      await HiveService.init();
      
      // Phase 2: Initialize services that depend on Hive
      await Future.wait([
        // Initialize connectivity service
        ConnectivityService().initialize(),
        // Initialize SavedResultsService (depends on Hive)
        SavedResultsService.init(),
      ]);
      
      // Phase 3: Initialize cache manager (synchronous)
      CacheManager.initialize();
      
      // Phase 4: Initialize Firebase services (can be slower)
      await Future.wait([
        AnalyticsService.initialize(),
        FirebaseMessagingService.initialize(),
      ]);
      
      // Add minimum delay to show splash screen
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Check login status after services are initialized
      await _checkLoginStatus();
    } catch (e) {
      // Handle initialization errors gracefully
      // Still proceed to check login status
      await Future.delayed(const Duration(seconds: 1));
      await _checkLoginStatus();
    }
  }

  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      
      if (isLoggedIn) {
        // Navigate to home screen if logged in
        if (mounted) {
          context.go('/');
        }
      } else {
        // Navigate to login screen if not logged in
        if (mounted) {
          context.go('/login');
        }
      }
    } catch (e) {
      // If there's an error, navigate to login screen as fallback
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
                  // Static app logo from assets
                  Image.asset(
                    'assets/icons/logo_foreground.png',
                    width: 200,
                    height: 200,
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
            padding: const EdgeInsets.only(bottom: 40),
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