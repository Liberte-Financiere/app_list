import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'apk_service.dart';
import '../constants/app_strings.dart';
import '../models/apk_model.dart';

/// Implémentation de production interagissant avec les packages Android réels
/// et le canal de plateforme natif pour la taille et les métadonnées de stockage.
class ApkServiceImpl implements ApkService {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  static const MethodChannel _nativeChannel =
      MethodChannel('com.example.apk_list/native_details');

  final StreamController<String> _packageChangeController =
      StreamController<String>.broadcast();

  ApkServiceImpl() {
    _nativeChannel.setMethodCallHandler(_handleNativeCall);
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onPackageChanged') {
      final data = call.arguments;
      final String packageName = (data is Map && data['packageName'] is String)
          ? data['packageName'] as String
          : '';
      _packageChangeController.add(packageName);
    }
  }

  @override
  Stream<String> get onPackageChanged => _packageChangeController.stream;

  @override
  Future<bool> hasUserConsent() async {
    try {
      final consent = await _prefs.getBool(AppStrings.prefConsentKey);
      return consent ?? false;
    } on Object catch (e) {
      debugPrint('Erreur lors de la lecture du consentement: $e');
      return false;
    }
  }

  @override
  Future<void> setUserConsent(bool granted) async {
    try {
      await _prefs.setBool(AppStrings.prefConsentKey, granted);
    } on Object catch (e) {
      throw ApkServiceException(
        'Impossible d\'enregistrer le consentement de l\'utilisateur.',
        e,
      );
    }
  }

  @override
  Future<String?> getUserName() async {
    try {
      final name = await _prefs.getString(AppStrings.prefUserNameKey);
      if (name != null && name.trim().isNotEmpty) {
        return name.trim();
      }
      return null;
    } on Object catch (e) {
      debugPrint('Erreur lors de la lecture du nom d\'utilisateur: $e');
      return null;
    }
  }

  @override
  Future<void> setUserName(String name) async {
    final cleanName = name.trim();
    if (cleanName.length < 2) {
      throw const ApkServiceException('Le nom d\'utilisateur doit comporter au moins 2 caractères.');
    }
    try {
      await _prefs.setString(AppStrings.prefUserNameKey, cleanName);
    } on Object catch (e) {
      throw ApkServiceException(
        'Impossible d\'enregistrer le nom d\'utilisateur.',
        e,
      );
    }
  }

  @override
  Future<List<ApkModel>> fetchInstalledApps({bool includeSystemApps = false}) async {
    if (kIsWeb || !Platform.isAndroid) {
      return _getFallbackData(includeSystemApps: includeSystemApps);
    }

    try {
      final List<AppInfo> apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: !includeSystemApps,
        excludeNonLaunchableApps: true,
        withIcon: true,
      );

      // Extraction asynchrone des métadonnées de stockage (tailles APK réelles)
      Map<dynamic, dynamic>? nativeDetails;
      try {
        nativeDetails = await _nativeChannel.invokeMethod<Map<dynamic, dynamic>>(
          'getAppsDetails',
          {'packages': apps.map((e) => e.packageName).toList()},
        );
      } on Object catch (e) {
        debugPrint('Extraction des détails natifs ignorée ou indisponible: $e');
      }

      final List<ApkModel> apkList = apps.map((app) {
        final installTimestamp = app.installedTimestamp;
        final pkgDetails = nativeDetails?[app.packageName];

        final int sizeInBytes = (pkgDetails is Map && pkgDetails['sizeInBytes'] is int)
            ? pkgDetails['sizeInBytes'] as int
            : 0;

        final String filePath = (pkgDetails is Map && pkgDetails['sourceDir'] is String)
            ? pkgDetails['sourceDir'] as String
            : '';

        final int firstInstallTime =
            (pkgDetails is Map && pkgDetails['firstInstallTime'] is int)
                ? pkgDetails['firstInstallTime'] as int
                : 0;

        final int lastUpdateTime =
            (pkgDetails is Map && pkgDetails['lastUpdateTime'] is int)
                ? pkgDetails['lastUpdateTime'] as int
                : 0;

        final int targetSdkVersion =
            (pkgDetails is Map && pkgDetails['targetSdkVersion'] is int)
                ? pkgDetails['targetSdkVersion'] as int
                : 0;

        final String installerPackageName =
            (pkgDetails is Map && pkgDetails['installerPackageName'] is String)
                ? pkgDetails['installerPackageName'] as String
                : '';

        final List<String> grantedPermissions =
            (pkgDetails is Map && pkgDetails['grantedPermissions'] is List)
                ? (pkgDetails['grantedPermissions'] as List)
                    .whereType<String>()
                    .map((e) => e.trim())
                    .toList()
                : const [];

        final List<String> declaredPermissions =
            (pkgDetails is Map && pkgDetails['declaredPermissions'] is List)
                ? (pkgDetails['declaredPermissions'] as List)
                    .whereType<String>()
                    .map((e) => e.trim())
                    .toList()
                : const [];

        final installDate = firstInstallTime > 0
            ? DateTime.fromMillisecondsSinceEpoch(firstInstallTime)
            : (installTimestamp > 0
                ? DateTime.fromMillisecondsSinceEpoch(installTimestamp)
                : DateTime.now());

        final lastUpdateDate = lastUpdateTime > 0
            ? DateTime.fromMillisecondsSinceEpoch(lastUpdateTime)
            : null;

        return ApkModel(
          id: app.packageName,
          name: app.name.trim().isEmpty ? app.packageName : app.name,
          packageName: app.packageName,
          versionName: app.versionName.trim().isEmpty ? 'Inconnue' : app.versionName,
          versionCode: app.versionCode,
          sizeInBytes: sizeInBytes,
          filePath: filePath,
          installDate: installDate,
          lastUpdateDate: lastUpdateDate,
          targetSdkVersion: targetSdkVersion,
          iconBytes: app.icon,
          isSystemApp: app.isSystemApp,
          installerPackageName: installerPackageName,
          grantedPermissions: grantedPermissions,
          declaredPermissions: declaredPermissions,
        );
      }).toList();

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
        lastUpdateDate: DateTime.now().subtract(const Duration(days: 2)),
        targetSdkVersion: 34,
        installerPackageName: 'com.android.vending',
        grantedPermissions: const [
          'android.permission.INTERNET',
          'android.permission.CAMERA',
          'android.permission.RECORD_AUDIO',
          'android.permission.READ_CONTACTS',
        ],
        declaredPermissions: const [
          'android.permission.INTERNET',
          'android.permission.CAMERA',
          'android.permission.RECORD_AUDIO',
          'android.permission.READ_CONTACTS',
          'android.permission.ACCESS_FINE_LOCATION',
        ],
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
        lastUpdateDate: DateTime.now().subtract(const Duration(days: 5)),
        targetSdkVersion: 34,
        installerPackageName: 'com.transsion.phoenix',
        grantedPermissions: const [
          'android.permission.INTERNET',
          'android.permission.POST_NOTIFICATIONS',
        ],
        declaredPermissions: const [
          'android.permission.INTERNET',
          'android.permission.POST_NOTIFICATIONS',
          'android.permission.ACCESS_NETWORK_STATE',
        ],
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
          targetSdkVersion: 34,
          isSystemApp: true,
          installerPackageName: 'com.google.android.packageinstaller',
          grantedPermissions: const [
            'android.permission.WRITE_SETTINGS',
          ],
          declaredPermissions: const [
            'android.permission.WRITE_SETTINGS',
            'android.permission.MANAGE_USERS',
          ],
        ),
    ];
    return List.unmodifiable(list);
  }
}
