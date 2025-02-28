import 'package:flutter/material.dart';
import 'package:lotto_app/core/constants/theme/app_theme.dart';
import 'package:lotto_app/routes/route_names.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Lotto App',
      theme: AppTheme.lightTheme,
      
      darkTheme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
    );
  }
}
