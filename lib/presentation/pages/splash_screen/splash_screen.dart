import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    
    // Check login status after a delay
    Future.delayed(const Duration(seconds: 1), () {
      _checkLoginStatus();
    });
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