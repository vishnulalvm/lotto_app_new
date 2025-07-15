import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lotto_app/core/constants/theme/app_theme.dart';
import 'package:lotto_app/data/datasource/api/auth_screen/auth_api_service.dart';
import 'package:lotto_app/data/datasource/api/home_screen/home_screen_api.dart';
import 'package:lotto_app/data/datasource/api/news_screen/news_api_service.dart';
import 'package:lotto_app/data/datasource/api/results_screen/results_screen.dart';
import 'package:lotto_app/data/datasource/api/scratch_card_screen/result_checker.dart';
import 'package:lotto_app/data/datasource/api/predict_screen/predict_api_service.dart';
import 'package:lotto_app/data/datasource/api/probability_screen/probability_api_service.dart';
import 'package:lotto_app/data/datasource/api/live_video_screen/live_video_api_service.dart';
import 'package:lotto_app/data/repositories/auth_screen/auth_repository.dart';
import 'package:lotto_app/data/repositories/home_screen/home_screen_repo.dart';
import 'package:lotto_app/data/repositories/cache/home_screen_cache_repository.dart';
import 'package:lotto_app/data/repositories/news_screen/news_repository.dart';
import 'package:lotto_app/data/repositories/results_screen/result_screen.dart';
import 'package:lotto_app/data/repositories/scratch_card_screen/check_result.dart';
import 'package:lotto_app/data/repositories/predict_screen/predict_repository.dart';
import 'package:lotto_app/data/repositories/probability_screen/probability_repository.dart';
import 'package:lotto_app/data/repositories/live_video_screen/live_video_repository.dart';
import 'package:lotto_app/data/services/hive_service.dart';
import 'package:lotto_app/data/services/connectivity_service.dart';
import 'package:lotto_app/data/services/cache_manager.dart';
import 'package:lotto_app/data/services/save_results.dart';
import 'package:lotto_app/data/services/theme_service.dart';
import 'package:lotto_app/data/services/user_service.dart';
import 'package:lotto_app/domain/usecases/home_screen/home_screen_usecase.dart';
import 'package:lotto_app/domain/usecases/news_screen/news_usecase.dart';
import 'package:lotto_app/domain/usecases/results_screen/results_screen.dart';
import 'package:lotto_app/domain/usecases/scratch_card_screen/check_result.dart';
import 'package:lotto_app/domain/usecases/predict_screen/predict_usecase.dart';
import 'package:lotto_app/domain/usecases/probability_screen/probability_usecase.dart';
import 'package:lotto_app/domain/usecases/live_video_screen/live_video_usecase.dart';
import 'package:lotto_app/presentation/blocs/auth_screen/bloc/auth_bloc.dart';
import 'package:lotto_app/presentation/blocs/color_theme/theme_bloc.dart';
import 'package:lotto_app/presentation/blocs/color_theme/theme_event.dart';
import 'package:lotto_app/presentation/blocs/color_theme/theme_state.dart';
import 'package:lotto_app/presentation/blocs/home_screen/home_screen_bloc.dart';
import 'package:lotto_app/presentation/blocs/news_screen/news_bloc.dart';
import 'package:lotto_app/presentation/blocs/results_screen/results_details_screen_bloc.dart';
import 'package:lotto_app/presentation/blocs/scrach_screen/scratch_card_bloc.dart';
import 'package:lotto_app/presentation/blocs/predict_screen/predict_bloc.dart';
import 'package:lotto_app/presentation/blocs/probability_screen/probability_bloc.dart';
import 'package:lotto_app/presentation/blocs/live_video_screen/live_video_bloc.dart';
import 'package:lotto_app/routes/route_names.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Initialize Hive database
  await HiveService.init();

  // Initialize connectivity service
  await ConnectivityService().initialize();

  // Initialize SavedResultsService
  await SavedResultsService.init();

  // Initialize cache manager
  CacheManager.initialize();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'), // English
        Locale('ml'), // Malayalam
        Locale('hi'), // Hindi
        Locale('ta'), // Tamil - Added
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
        // Add ThemeBloc to the providers
        BlocProvider(
          create: (context) =>
              ThemeBloc(themeService: ThemeService())..add(ThemeInitialized()),
        ),
        BlocProvider(
          create: (context) => AuthBloc(
            repository: AuthRepository(
              apiService: AuthApiService(),
              userService: UserService(),
            ),
          ),
        ),
        BlocProvider<HomeScreenResultsBloc>(
          create: (context) => HomeScreenResultsBloc(
            HomeScreenResultsUseCase(
              HomeScreenResultsRepository(
                HomeScreenResultsApiService(),
                HomeScreenCacheRepositoryImpl(),
                ConnectivityService(),
              ),
            ),
            ConnectivityService(),
          ),
        ),
        BlocProvider(
          create: (context) => LotteryResultDetailsBloc(
            LotteryResultDetailsUseCase(
              LotteryResultDetailsRepository(
                LotteryResultDetailsApiService(),
              ),
            ),
          ),
        ),
        BlocProvider(
          create: (context) => TicketCheckBloc(
            TicketCheckUseCase(
              TicketCheckRepository(
                TicketCheckApiService(),
              ),
            ),
          ),
        ),
        BlocProvider(
          create: (context) => NewsBloc(
            newsUseCase: NewsUseCase(
              NewsRepositoryImpl(
                apiService: NewsApiService(),
              ),
            ),
          ),
        ),
        BlocProvider(
          create: (context) => PredictBloc(
            PredictUseCase(
              PredictRepositoryImpl(
                PredictApiService(),
              ),
            ),
          ),
        ),
        BlocProvider(
          create: (context) => LiveVideoBloc(
            LiveVideoUseCase(
              LiveVideoRepositoryImpl(
                LiveVideoApiService(),
              ),
            ),
          ),
        ),
        BlocProvider(
          create: (context) => ProbabilityBloc(
            useCase: ProbabilityUseCase(
              repository: ProbabilityRepositoryImpl(
                apiService: ProbabilityApiService(),
              ),
            ),
          ),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Lotto App',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeState.materialThemeMode, // Use the bloc state
            routerConfig: AppRouter.router,
            // Easy Localization setup with Tamil support
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: const [
              Locale('en'), // English
              Locale('ml'), // Malayalam
              Locale('hi'), // Hindi
              Locale('ta'), // Tamil - Added
            ],
            locale: context.locale,
          );
        },
      ),
    );
  }
}
