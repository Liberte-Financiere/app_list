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

/// Racine de l'application avec injection des dépendances.
class ApkApp extends StatelessWidget {
  final ApkService apkService;

  const ApkApp({super.key, required this.apkService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: DashboardScreen(apkService: apkService),
    );
  }
}
