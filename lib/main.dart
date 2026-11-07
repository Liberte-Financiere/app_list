import 'package:flutter/material.dart';

import 'constants/app_constants.dart';
import 'dashboard/dashboard_screen.dart';
import 'services/apk_service.dart';
import 'services/apk_service_impl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final ApkService apkService = ApkServiceImpl();

  runApp(ApkApp(apkService: apkService));
}

/// Racine de l'application avec configuration des thèmes et injection du service.
class ApkApp extends StatelessWidget {
  final ApkService apkService;

  const ApkApp({super.key, required this.apkService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: DashboardScreen(apkService: apkService),
    );
  }
}
