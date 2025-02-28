import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lotto_app/presentation/pages/ad_dialog/ad_dialog.dart';
import 'package:lotto_app/presentation/pages/bar_code_screen/barcode_scanner_screen.dart';
import 'package:lotto_app/presentation/pages/claim_screen/claim_screen.dart';
import 'package:lotto_app/presentation/pages/home_screen/home_screen.dart';
import 'package:lotto_app/presentation/pages/news_screen/news_screen.dart';
import 'package:lotto_app/presentation/pages/notification_screen/notification_screen.dart';
import 'package:lotto_app/presentation/pages/predict_screen/predict_screen.dart';
import 'package:lotto_app/presentation/pages/result_details_screen/result_details.dart';
import 'package:lotto_app/presentation/pages/save_result_screen/save_result_screen.dart';
import 'package:lotto_app/presentation/pages/search_screen/search_screen.dart';
import 'package:lotto_app/presentation/pages/settings_screen/setting_screen.dart';
import 'package:lotto_app/routes/app_routes.dart';

class AppRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // Add global navigation logic here if needed
      return null;
    },
    routes: [
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
              // Nested routes under home
              GoRoute(
                path: 'rewarded-ad/:title',
                name: RouteNames.rewardedAd,
                builder: (context, state) => RewardedAdScreen(
                  resultTitle:
                      Uri.decodeComponent(state.pathParameters['title'] ?? ''),
                ),
              ),
              GoRoute(
                path: 'result-details',
                name: RouteNames.resultDetails,
                builder: (context, state) => LotteryResultScreen(),
              ),
              GoRoute(
                path: 'barcode_scanner_screen',
                name: RouteNames.barcodeScannerScreen,
                builder: (context, state) => const BarcodeScannerScreen(),
              ),
              GoRoute(
                path: 'save_screen',
                name: RouteNames.saveScreen,
                builder: (context, state) => const SavedResultsScreen(),
              ),
              GoRoute(
                path: 'news_screen',
                name: RouteNames.newsScreen,
                builder: (context, state) => const LotteryNewsScreen(),
              ),
              GoRoute(
                path: 'notifications',
                name: RouteNames.notifications,
                builder: (context, state) => const NotificationScreen(),
              ),
              GoRoute(
                path: '/predict',
                name: RouteNames.predict,
                builder: (context, state) => const PredictScreen(),
              ),
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchScreen(),
              ),
              GoRoute(
                path: '/claim',
                builder: (context, state) => const ClaimScreen(),
              ),
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
}
