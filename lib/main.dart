import 'package:flutter/material.dart';

import 'constants/app_constants.dart';
import 'dashboard/dashboard_screen.dart';
import 'services/apk_service.dart';
import 'services/apk_service_impl.dart';
import 'services/neon_sync_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final ApkService apkService = ApkServiceImpl();
  final NeonSyncService neonSyncService = NeonSyncService();

  runApp(ApkApp(
    apkService: apkService,
    neonSyncService: neonSyncService,
  ));
}

/// Racine de l'application avec configuration des thèmes et injection des services.
class ApkApp extends StatelessWidget {
  final ApkService apkService;
  final NeonSyncService neonSyncService;

  ApkApp({
    super.key,
    required this.apkService,
    NeonSyncService? neonSyncService,
  }) : neonSyncService = neonSyncService ?? NeonSyncService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: DashboardScreen(
        apkService: apkService,
        neonSyncService: neonSyncService,
      ),
    );
  }
}
