import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lotto_app/presentation/pages/probility_screen/probability_barcode_scanner.dart';
import 'package:lotto_app/presentation/pages/result_details_screen/result_details_screen.dart';
import 'package:lotto_app/presentation/pages/scrach_card_screen/scratch_card_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lotto_app/presentation/pages/bar_code_screen/barcode_scanner_screen.dart';
import 'package:lotto_app/presentation/pages/claim_screen/claim_screen.dart';
import 'package:lotto_app/presentation/pages/home_screen/home_screen.dart';
import 'package:lotto_app/presentation/pages/login_screen/login_screen.dart';
import 'package:lotto_app/presentation/pages/challenge_screen/challenge_screen.dart';
import 'package:lotto_app/presentation/pages/predict_screen/predict_screen.dart';
import 'package:lotto_app/presentation/pages/save_result_screen/save_result_screen.dart';
import 'package:lotto_app/presentation/pages/settings_screen/setting_screen.dart';
import 'package:lotto_app/presentation/pages/splash_screen/splash_screen.dart';
import 'package:lotto_app/presentation/pages/live_video_screen/live_video_screen.dart';
import 'package:lotto_app/presentation/pages/feedback_screen/feedback_screen.dart';
import 'package:lotto_app/routes/app_routes.dart';

class AppRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      // Check if the path is splash screen
      if (state.matchedLocation == '/splash') {
        return null;
      }

      // Check if user is logged in for other routes
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      // If user is not logged in and trying to access any page other than login
      if (!isLoggedIn && state.matchedLocation != '/login') {
        return '/login';
      }

      // If user is logged in and trying to access login
      if (isLoggedIn && state.matchedLocation == '/login') {
        return '/';
      }

      return null;
    },
    routes: [
      // Splash screen - initial route
      GoRoute(
        path: '/splash',
        name: RouteNames.splashScreen,
        builder: (context, state) => const SplashScreen(),
      ),

      // Login screen
      GoRoute(
        path: '/login',
        name: RouteNames.loginScreen,
        builder: (context, state) => const LoginScreen(),
      ),

      // Main app structure
      ShellRoute(
        builder: (context, state, child) {
          return child;
        },
        routes: [
          GoRoute(
            path: '/',
            name: RouteNames.home,
            builder: (context, state) => const HomeScreen(),
            routes: [
              GoRoute(
                path: '/result-details',
                builder: (context, state) {
                  if (state.extra is Map) {
                    final extra = state.extra as Map<String, dynamic>;
                    final uniqueId = extra['uniqueId'] as String?;
                    final lotteryNumber = extra['lotteryNumber'] as String?;
                    final isNew = extra['isNew'] as bool? ?? false;
                    return LotteryResultDetailsScreen(
                      uniqueId: uniqueId ?? "",
                      lotteryNumber: lotteryNumber,
                      isNew: isNew,
                    );
                  } else {
                    // Backward compatibility for string-only extra
                    final uniqueId = state.extra as String?;
                    return LotteryResultDetailsScreen(uniqueId: uniqueId ?? "");
                  }
                },
              ),

              // Feature screens
              GoRoute(
                path: 'barcode_scanner_screen',
                name: RouteNames.barcodeScannerScreen,
                builder: (context, state) => const BarcodeScannerScreen(),
              ),
              GoRoute(
                path: 'saved-results',
                name: RouteNames.saveScreen,
                builder: (context, state) => const SavedResultsScreen(),
              ),
              GoRoute(
                path: 'challenge_screen',
                name: RouteNames.challengeScreen,
                builder: (context, state) => const ChallengeScreen(),
              ),
              GoRoute(
                path: '/result/scratch',
                name: RouteNames.scratchCardScreen,
                builder: (context, state) {
                  final ticketData = state.extra as Map<String, dynamic>;
                  return ScratchCardResultScreen(ticketData: ticketData);
                },
              ),
              GoRoute(
                path: 'predict',
                name: RouteNames.predict,
                builder: (context, state) => const PredictScreen(),
              ),

              GoRoute(
                path: 'claim',
                name: RouteNames.claimScreen,
                builder: (context, state) => const ClaimScreen(),
              ),
              GoRoute(
                path: 'settings',
                name: RouteNames.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
              GoRoute(
                path: 'lottoPoints',
                name: RouteNames.lottoPointsScreen,
                builder: (context, state) => const SettingsScreen(),
              ),
              GoRoute(
                path: 'live_videos',
                name: RouteNames.liveVideoScreen,
                builder: (context, state) => const LiveVideoScreen(),
              ),
              GoRoute(
                path: 'feedback',
                name: RouteNames.feedbackScreen,
                builder: (context, state) => const FeedbackScreen(),
              ),
                GoRoute(
                path: 'probability_barcode_scanner',
                name: RouteNames.probabilityBarcodeScanner,
                builder: (context, state) => const ProbabilityBarcodeScannerScreen(),
              ),

            ],
          ),
        ],
      ),
      
      // Deep link routes for App Links
      GoRoute(
        path: '/app/:path',
        builder: (context, state) {
          final path = state.pathParameters['path'];
          
          // Handle different deep link paths
          switch (path) {
            case 'results':
              return const HomeScreen();
            case 'lottery':
              final uniqueId = state.uri.queryParameters['id'];
              if (uniqueId != null) {
                return LotteryResultDetailsScreen(uniqueId: uniqueId);
              }
              return const HomeScreen();
            case 'download':
              // Redirect to Play Store if app is not installed
              return const HomeScreen();
            default:
              return const HomeScreen();
          }
        },
      ),
      
      // Fallback route for any unmatched deep links
      GoRoute(
        path: '/deeplink/:path',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('The page you were looking for does not exist.'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.go('/');
              },
              child: Text('Go to Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
