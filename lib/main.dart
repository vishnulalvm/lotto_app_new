import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lotto_app/core/constants/theme/app_theme.dart';
import 'package:lotto_app/data/datasource/api/auth_screen/auth_api_service.dart';
import 'package:lotto_app/data/datasource/api/home_screen/home_screen_api.dart';
import 'package:lotto_app/data/datasource/api/results_screen/results_screen.dart';
import 'package:lotto_app/data/datasource/api/scratch_card_screen/result_checker.dart';
import 'package:lotto_app/data/repositories/auth_screen/auth_repository.dart';
import 'package:lotto_app/data/repositories/home_screen/home_screen_repo.dart';
import 'package:lotto_app/data/repositories/results_screen/result_screen.dart';
import 'package:lotto_app/data/repositories/scratch_card_screen/check_result.dart';
import 'package:lotto_app/domain/usecases/home_screen/home_screen_usecase.dart';
import 'package:lotto_app/domain/usecases/results_screen/results_screen.dart';
import 'package:lotto_app/domain/usecases/scratch_card_screen/check_result.dart';
import 'package:lotto_app/presentation/blocs/auth_screen/bloc/auth_bloc.dart';
import 'package:lotto_app/presentation/blocs/home_screen/home_screen_bloc.dart';
import 'package:lotto_app/presentation/blocs/results_screen/results_details_screen_bloc.dart';
import 'package:lotto_app/presentation/blocs/scrach_screen/scratch_card_bloc.dart';
import 'package:lotto_app/routes/route_names.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('ml'),
        Locale('hi'),
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
        BlocProvider(
          create: (context) => AuthBloc(
            repository: AuthRepository(
              apiService: AuthApiService(),
            ),
          ),
        ),
        BlocProvider<HomeScreenResultsBloc>(
          create: (context) => HomeScreenResultsBloc(
            HomeScreenResultsUseCase(
              (HomeScreenResultsRepository(
                HomeScreenResultsApiService(),
              )),
            ),
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
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Lotto App',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        routerConfig: AppRouter.router,
        // Easy Localization setup
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
      ),
    );
  }
}
