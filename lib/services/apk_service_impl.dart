import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'apk_service.dart';
import '../constants/app_constants.dart';
import '../models/apk_model.dart';

/// Implémentation de production interagissant avec les packages Android réels.
class ApkServiceImpl implements ApkService {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  @override
  Future<bool> hasUserConsent() async {
    try {
      final consent = await _prefs.getBool(AppConstants.prefUserConsentKey);
      return consent ?? false;
    } on Object catch (e) {
      debugPrint('Erreur lors de la lecture du consentement: $e');
      return false;
    }
  }

  @override
  Future<void> setUserConsent(bool granted) async {
    try {
      await _prefs.setBool(AppConstants.prefUserConsentKey, granted);
    } on Object catch (e) {
      throw ApkServiceException(
        'Impossible d\'enregistrer le consentement de l\'utilisateur.',
        e,
      );
    }
  }

  @override
  Future<List<ApkModel>> fetchInstalledApps({bool includeSystemApps = false}) async {
    // Si la plateforme n'est pas Android (ex. tests unitaires ou Linux Desktop en dev)
    if (kIsWeb || !Platform.isAndroid) {
      return _getFallbackData(includeSystemApps: includeSystemApps);
    }

    try {
      final List<AppInfo> apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: !includeSystemApps,
        excludeNonLaunchableApps: true,
        withIcon: true,
      );

      final List<ApkModel> apkList = apps.map((app) {
        final installTimestamp = app.installedTimestamp;
        final installDate = installTimestamp > 0
            ? DateTime.fromMillisecondsSinceEpoch(installTimestamp)
            : DateTime.now();

        return ApkModel(
          id: app.packageName,
          name: app.name.trim().isEmpty ? app.packageName : app.name,
          packageName: app.packageName,
          versionName: app.versionName.trim().isEmpty ? 'Inconnue' : app.versionName,
          versionCode: app.versionCode,
          sizeInBytes: 0,
          filePath: '',
          installDate: installDate,
          iconBytes: app.icon,
          isSystemApp: app.isSystemApp,
        );
      }).toList();

      // Tri alphabétique par nom d'application
      apkList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return List.unmodifiable(apkList);
    } on Object catch (e) {
      throw ApkServiceException(
        'Erreur lors de la récupération des applications installées.',
        e,
      );
    }
  }

  @override
  Future<bool> launchApp(String packageName) async {
    if (packageName.trim().isEmpty) {
      throw const ApkServiceException('Nom de package vide ou invalide.');
    }

    if (kIsWeb || !Platform.isAndroid) {
      debugPrint('Simulation du lancement de $packageName sur cette plateforme.');
      return true;
    }

    try {
      final result = await InstalledApps.startApp(packageName);
      return result ?? false;
    } on Object catch (e) {
      throw ApkServiceException('Échec du lancement de l\'application $packageName.', e);
    }
  }

  @override
  Future<void> openAppSettings(String packageName) async {
    if (packageName.trim().isEmpty) {
      throw const ApkServiceException('Nom de package vide ou invalide.');
    }

    if (kIsWeb || !Platform.isAndroid) {
      debugPrint('Simulation de l\'ouverture des paramètres pour $packageName.');
      return;
    }

    try {
      InstalledApps.openSettings(packageName);
    } on Object catch (e) {
      throw ApkServiceException(
        'Échec de l\'ouverture des paramètres pour $packageName.',
        e,
      );
    }
  }

  List<ApkModel> _getFallbackData({required bool includeSystemApps}) {
    final list = [
      ApkModel(
        id: 'com.whatsapp',
        name: 'WhatsApp',
        packageName: 'com.whatsapp',
        versionName: '2.24.1.6',
        versionCode: 224016,
        sizeInBytes: 42000000,
        filePath: '/data/app/com.whatsapp.apk',
        installDate: DateTime.now().subtract(const Duration(days: 30)),
      ),
      ApkModel(
        id: 'com.spotify.music',
        name: 'Spotify',
        packageName: 'com.spotify.music',
        versionName: '8.9.10',
        versionCode: 8910,
        sizeInBytes: 65000000,
        filePath: '/data/app/com.spotify.music.apk',
        installDate: DateTime.now().subtract(const Duration(days: 15)),
      ),
      if (includeSystemApps)
        ApkModel(
          id: 'com.android.settings',
          name: 'Paramètres Système',
          packageName: 'com.android.settings',
          versionName: '14.0',
          versionCode: 34,
          sizeInBytes: 12000000,
          filePath: '/system/priv-app/Settings.apk',
          installDate: DateTime.now().subtract(const Duration(days: 180)),
          isSystemApp: true,
        ),
    ];
    return List.unmodifiable(list);
  }
}
