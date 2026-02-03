import 'package:get_it/get_it.dart';

// API Services
import 'package:lotto_app/data/datasource/api/auth_screen/auth_api_service.dart';
import 'package:lotto_app/data/datasource/api/home_screen/home_screen_api.dart';
import 'package:lotto_app/data/datasource/api/results_screen/results_screen.dart';
import 'package:lotto_app/data/datasource/api/scratch_card_screen/result_checker.dart';
import 'package:lotto_app/data/datasource/api/predict_screen/predict_api_service.dart';
import 'package:lotto_app/data/datasource/api/live_video_screen/live_video_api_service.dart';
import 'package:lotto_app/data/datasource/api/probability_screen/probability_api_service.dart';
import 'package:lotto_app/data/datasource/api/lottery_purchase/lottery_purchase_api_service.dart';
import 'package:lotto_app/data/datasource/api/lottery_statistics/lottery_statistics_api_service.dart';
import 'package:lotto_app/data/datasource/api/feedback_screen/feedback_api_service.dart';

// Repositories
import 'package:lotto_app/data/repositories/auth_screen/auth_repository.dart';
import 'package:lotto_app/data/repositories/home_screen/home_screen_repo.dart';
import 'package:lotto_app/data/repositories/cache/home_screen_cache_repository.dart';
import 'package:lotto_app/data/repositories/cache/result_details_cache_repository.dart';
import 'package:lotto_app/data/repositories/results_screen/result_screen.dart';
import 'package:lotto_app/data/repositories/scratch_card_screen/check_result.dart';
import 'package:lotto_app/data/repositories/predict_screen/predict_repository.dart';
import 'package:lotto_app/data/repositories/live_video_screen/live_video_repository.dart';
import 'package:lotto_app/data/repositories/probability_screen/probability_repository.dart';
import 'package:lotto_app/data/repositories/lottery_purchase/lottery_purchase_repository.dart';
import 'package:lotto_app/data/repositories/lottery_statistics/lottery_statistics_repository.dart';
import 'package:lotto_app/data/repositories/cache/lottery_statistics_cache_repository.dart';
import 'package:lotto_app/data/repositories/rate_us/rate_us_repository.dart';
import 'package:lotto_app/data/repositories/feedback_screen/feedback_repository.dart';

// Services
import 'package:lotto_app/data/services/connectivity_service.dart';
import 'package:lotto_app/data/services/user_service.dart';
import 'package:lotto_app/data/services/predict_cache_service.dart';
import 'package:lotto_app/data/services/audio_service.dart';
import 'package:lotto_app/core/services/theme_service.dart';

// Use Cases
import 'package:lotto_app/domain/usecases/home_screen/home_screen_usecase.dart';
import 'package:lotto_app/domain/usecases/results_screen/results_screen.dart';
import 'package:lotto_app/domain/usecases/scratch_card_screen/check_result.dart';
import 'package:lotto_app/domain/usecases/predict_screen/predict_usecase.dart';
import 'package:lotto_app/domain/usecases/live_video_screen/live_video_usecase.dart';
import 'package:lotto_app/domain/usecases/probability_screen/probability_usecase.dart';
import 'package:lotto_app/domain/usecases/lottery_purchase/lottery_purchase_usecase.dart';
import 'package:lotto_app/domain/usecases/lottery_statistics/lottery_statistics_usecase.dart';

// BLoCs
import 'package:lotto_app/presentation/blocs/auth_screen/bloc/auth_bloc.dart';
import 'package:lotto_app/presentation/blocs/theme/theme_cubit.dart';
import 'package:lotto_app/presentation/blocs/home_screen/home_screen_bloc.dart';
import 'package:lotto_app/presentation/blocs/results_screen/results_details_screen_bloc.dart';
import 'package:lotto_app/presentation/blocs/scrach_screen/scratch_card_bloc.dart';
import 'package:lotto_app/presentation/blocs/predict_screen/predict_bloc.dart';
import 'package:lotto_app/presentation/blocs/live_video_screen/live_video_bloc.dart';
import 'package:lotto_app/presentation/blocs/probability_screen/probability_bloc.dart';
import 'package:lotto_app/presentation/blocs/lottery_purchase/lottery_purchase_bloc.dart';
import 'package:lotto_app/presentation/blocs/lottery_statistics/lottery_statistics_bloc.dart';
import 'package:lotto_app/presentation/blocs/rate_us/rate_us_bloc.dart';
import 'package:lotto_app/presentation/blocs/feedback_screen/feedback_bloc.dart';

/// Global service locator instance
final getIt = GetIt.instance;

/// Initialize all dependencies
/// Call this once in main() before runApp()
Future<void> setupServiceLocator() async {
  // ============================================
  // SERVICES (Singletons - already handle own state)
  // ============================================
  getIt.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  getIt.registerLazySingleton<UserService>(() => UserService());
  getIt.registerLazySingleton<AudioService>(() => AudioService());
  getIt.registerLazySingleton<ThemeService>(() => ThemeService());
  getIt.registerLazySingleton<PredictCacheService>(() => PredictCacheService());

  // ============================================
  // API SERVICES (Lazy Singletons)
  // ============================================
  getIt.registerLazySingleton<AuthApiService>(() => AuthApiService());
  getIt.registerLazySingleton<HomeScreenResultsApiService>(
      () => HomeScreenResultsApiService());
  getIt.registerLazySingleton<LotteryResultDetailsApiService>(
      () => LotteryResultDetailsApiService());
  getIt.registerLazySingleton<TicketCheckApiService>(
      () => TicketCheckApiService());
  getIt.registerLazySingleton<PredictApiService>(() => PredictApiService());
  getIt.registerLazySingleton<LiveVideoApiService>(() => LiveVideoApiService());
  getIt.registerLazySingleton<ProbabilityApiService>(
      () => ProbabilityApiService());
  getIt.registerLazySingleton<LotteryPurchaseApiService>(
      () => LotteryPurchaseApiService());
  getIt.registerLazySingleton<LotteryStatisticsApiService>(
      () => LotteryStatisticsApiService());
  getIt.registerLazySingleton<FeedbackApiService>(() => FeedbackApiService());

  // ============================================
  // CACHE REPOSITORIES (Lazy Singletons)
  // ============================================
  getIt.registerLazySingleton<HomeScreenCacheRepositoryImpl>(
      () => HomeScreenCacheRepositoryImpl());
  getIt.registerLazySingleton<ResultDetailsCacheRepositoryImpl>(
      () => ResultDetailsCacheRepositoryImpl());
  getIt.registerLazySingleton<LotteryStatisticsCacheRepositoryImpl>(
      () => LotteryStatisticsCacheRepositoryImpl());

  // ============================================
  // REPOSITORIES (Factories - depend on services)
  // ============================================
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      apiService: getIt<AuthApiService>(),
      userService: getIt<UserService>(),
    ),
  );

  getIt.registerLazySingleton<HomeScreenResultsRepository>(
    () => HomeScreenResultsRepository(
      getIt<HomeScreenResultsApiService>(),
      getIt<HomeScreenCacheRepositoryImpl>(),
      getIt<ConnectivityService>(),
    ),
  );

  getIt.registerLazySingleton<LotteryResultDetailsRepository>(
    () => LotteryResultDetailsRepository(
      getIt<LotteryResultDetailsApiService>(),
      getIt<ResultDetailsCacheRepositoryImpl>(),
      getIt<ConnectivityService>(),
    ),
  );

  getIt.registerLazySingleton<TicketCheckRepository>(
    () => TicketCheckRepository(getIt<TicketCheckApiService>()),
  );

  getIt.registerLazySingleton<PredictRepositoryImpl>(
    () => PredictRepositoryImpl(
      getIt<PredictApiService>(),
      getIt<PredictCacheService>(),
    ),
  );

  getIt.registerLazySingleton<LiveVideoRepositoryImpl>(
    () => LiveVideoRepositoryImpl(getIt<LiveVideoApiService>()),
  );

  getIt.registerLazySingleton<ProbabilityRepositoryImpl>(
    () => ProbabilityRepositoryImpl(apiService: getIt<ProbabilityApiService>()),
  );

  getIt.registerLazySingleton<LotteryPurchaseRepository>(
    () => LotteryPurchaseRepository(
        apiService: getIt<LotteryPurchaseApiService>()),
  );

  getIt.registerLazySingleton<LotteryStatisticsRepository>(
    () => LotteryStatisticsRepository(
      apiService: getIt<LotteryStatisticsApiService>(),
      cacheRepository: getIt<LotteryStatisticsCacheRepositoryImpl>(),
      connectivityService: getIt<ConnectivityService>(),
    ),
  );

  getIt.registerLazySingleton<RateUsRepositoryImpl>(
      () => RateUsRepositoryImpl());

  getIt.registerLazySingleton<FeedbackRepository>(
    () => FeedbackRepository(apiService: getIt<FeedbackApiService>()),
  );

  // ============================================
  // USE CASES (Factories)
  // ============================================
  getIt.registerLazySingleton<HomeScreenResultsUseCase>(
    () => HomeScreenResultsUseCase(getIt<HomeScreenResultsRepository>()),
  );

  getIt.registerLazySingleton<LotteryResultDetailsUseCase>(
    () => LotteryResultDetailsUseCase(getIt<LotteryResultDetailsRepository>()),
  );

  getIt.registerLazySingleton<TicketCheckUseCase>(
    () => TicketCheckUseCase(getIt<TicketCheckRepository>()),
  );

  getIt.registerLazySingleton<PredictUseCase>(
    () => PredictUseCase(getIt<PredictRepositoryImpl>()),
  );

  getIt.registerLazySingleton<LiveVideoUseCase>(
    () => LiveVideoUseCase(getIt<LiveVideoRepositoryImpl>()),
  );

  getIt.registerLazySingleton<ProbabilityUseCase>(
    () => ProbabilityUseCase(repository: getIt<ProbabilityRepositoryImpl>()),
  );

  getIt.registerLazySingleton<LotteryPurchaseUseCase>(
    () => LotteryPurchaseUseCase(getIt<LotteryPurchaseRepository>()),
  );

  getIt.registerLazySingleton<LotteryStatisticsUseCase>(
    () => LotteryStatisticsUseCase(getIt<LotteryStatisticsRepository>()),
  );

  // ============================================
  // BLOCs (Factories - create new instance each time for proper lifecycle)
  // ============================================
  getIt.registerFactory<ThemeCubit>(
    () => ThemeCubit(getIt<ThemeService>()),
  );

  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(repository: getIt<AuthRepository>()),
  );

  getIt.registerFactory<HomeScreenResultsBloc>(
    () => HomeScreenResultsBloc(
      getIt<HomeScreenResultsUseCase>(),
      getIt<ConnectivityService>(),
    ),
  );

  getIt.registerFactory<LotteryResultDetailsBloc>(
    () => LotteryResultDetailsBloc(getIt<LotteryResultDetailsUseCase>()),
  );

  getIt.registerFactory<TicketCheckBloc>(
    () => TicketCheckBloc(
      getIt<TicketCheckUseCase>(),
      getIt<LotteryResultDetailsRepository>(),
    ),
  );

  getIt.registerFactory<PredictBloc>(
    () => PredictBloc(getIt<PredictUseCase>()),
  );

  getIt.registerFactory<LiveVideoBloc>(
    () => LiveVideoBloc(getIt<LiveVideoUseCase>()),
  );

  getIt.registerFactory<ProbabilityBloc>(
    () => ProbabilityBloc(useCase: getIt<ProbabilityUseCase>()),
  );

  getIt.registerFactory<LotteryPurchaseBloc>(
    () => LotteryPurchaseBloc(useCase: getIt<LotteryPurchaseUseCase>()),
  );

  getIt.registerFactory<LotteryStatisticsBloc>(
    () => LotteryStatisticsBloc(useCase: getIt<LotteryStatisticsUseCase>()),
  );

  getIt.registerFactory<RateUsBloc>(
    () => RateUsBloc(getIt<RateUsRepositoryImpl>()),
  );

  getIt.registerFactory<FeedbackBloc>(
    () => FeedbackBloc(repository: getIt<FeedbackRepository>()),
  );
}
