import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lotto_app/core/constants/theme/app_theme.dart';
import 'firebase_options.dart';
import 'package:lotto_app/core/di/service_locator.dart';
import 'package:lotto_app/presentation/blocs/auth_screen/bloc/auth_bloc.dart';
import 'package:lotto_app/presentation/blocs/lottery_purchase/lottery_purchase_bloc.dart';
import 'package:lotto_app/presentation/blocs/lottery_statistics/lottery_statistics_bloc.dart';
import 'package:lotto_app/presentation/blocs/theme/theme_cubit.dart';
import 'package:lotto_app/presentation/blocs/theme/theme_state.dart';
import 'package:lotto_app/presentation/blocs/home_screen/home_screen_bloc.dart';
import 'package:lotto_app/presentation/blocs/results_screen/results_details_screen_bloc.dart';
import 'package:lotto_app/presentation/blocs/scrach_screen/scratch_card_bloc.dart';
import 'package:lotto_app/presentation/blocs/predict_screen/predict_bloc.dart';
import 'package:lotto_app/presentation/blocs/live_video_screen/live_video_bloc.dart';
import 'package:lotto_app/presentation/blocs/probability_screen/probability_bloc.dart';
import 'package:lotto_app/presentation/blocs/rate_us/rate_us_bloc.dart';
import 'package:lotto_app/presentation/blocs/feedback_screen/feedback_bloc.dart';
import 'package:lotto_app/routes/route_names.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // BOOTSTRAP PATTERN: Initialize ONLY what's absolutely required to render the app
  // Everything else is handled by SplashScreen asynchronously
  await Future.wait([
    EasyLocalization.ensureInitialized(),
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    setupServiceLocator(), // Initialize DI container
  ]);

  // Set up background message handler after Firebase is initialized
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Render app immediately - SplashScreen will handle all other initialization
  // AudioService initialization moved to SplashScreen for faster cold start
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'), // English
        Locale('ml'), // Malayalam
        Locale('hi'), // Hindi
        Locale('ta'), // Tamil
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Critical BLoCs - loaded immediately (using DI)
        BlocProvider(
          create: (context) => getIt<ThemeCubit>(),
        ),
        BlocProvider(
          create: (context) => getIt<AuthBloc>(),
        ),
        BlocProvider<HomeScreenResultsBloc>(
          create: (context) => getIt<HomeScreenResultsBloc>(),
        ),
        // Non-critical BLoCs - lazy loaded (using DI)
        BlocProvider(
          lazy: true,
          create: (context) => getIt<LotteryResultDetailsBloc>(),
        ),
        BlocProvider(
          lazy: true,
          create: (context) => getIt<TicketCheckBloc>(),
        ),
        BlocProvider(
          lazy: true,
          create: (context) => getIt<PredictBloc>(),
        ),
        BlocProvider(
          lazy: true,
          create: (context) => getIt<ProbabilityBloc>(),
        ),
        BlocProvider(
          lazy: true,
          create: (context) => getIt<LiveVideoBloc>(),
        ),
        BlocProvider(
          lazy: true,
          create: (context) => getIt<LotteryPurchaseBloc>(),
        ),
        BlocProvider(
          lazy: true,
          create: (context) => getIt<LotteryStatisticsBloc>(),
        ),
        BlocProvider(
          create: (context) => getIt<RateUsBloc>(),
        ),
        BlocProvider(
          lazy: true,
          create: (context) => getIt<FeedbackBloc>(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        buildWhen: (previous, current) =>
            previous.themeMode != current.themeMode ||
            previous.colorScheme != current.colorScheme,
        builder: (context, themeState) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Lotto App',
            theme: AppTheme.lightTheme(themeState.colorScheme),
            darkTheme: AppTheme.darkTheme(themeState.colorScheme),
            themeMode: themeState.themeMode,
            routerConfig: AppRouter.router,
            builder: (context, child) {
              return child ?? const SizedBox();
            },
            // Easy Localization setup with Tamil support
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: const [
              Locale('en'), // English
              Locale('ml'), // Malayalam
              Locale('hi'), // Hindi
              Locale('ta'), // Tamil
            ],
            locale: context.locale,
          );
        },
      ),
    );
  }
}
