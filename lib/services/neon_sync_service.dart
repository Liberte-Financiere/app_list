import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:postgres/postgres.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/apk_model.dart';

/// Exception dédiée aux erreurs de synchronisation Neon.
class NeonSyncException implements Exception {
  final String message;
  final Object? cause;

  const NeonSyncException(this.message, [this.cause]);

  @override
  String toString() =>
      'NeonSyncException: $message${cause != null ? ' (Cause: $cause)' : ''}';
}

/// Statut de synchronisation avec le backend Neon.
enum NeonSyncStatus {
  idle,
  syncing,
  success,
  error,
}

/// État réactif de synchronisation avec horodatage et métadonnées d'utilisateur.
class NeonSyncState {
  final NeonSyncStatus status;
  final DateTime? lastSyncTime;
  final int syncedCount;
  final String? errorMessage;
  final String? deviceId;
  final String? userLabel;
  final String? deviceModel;

  const NeonSyncState({
    this.status = NeonSyncStatus.idle,
    this.lastSyncTime,
    this.syncedCount = 0,
    this.errorMessage,
    this.deviceId,
    this.userLabel,
    this.deviceModel,
  });

  String get formattedTime {
    if (lastSyncTime == null) return '';
    final h = lastSyncTime!.hour.toString().padLeft(2, '0');
    final m = lastSyncTime!.minute.toString().padLeft(2, '0');
    final s = lastSyncTime!.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

/// Service gérant la synchronisation automatique en arrière-plan avec Neon PostgreSQL.
/// Gère l'attribution atomique de "User 1", "User 2" et le modèle matériel du terminal.
class NeonSyncService {
  SharedPreferencesAsync? _prefs;
  final String host;
  final String database;
  final String user;
  final String password;
  final int port;
  final ValueNotifier<NeonSyncState> stateNotifier =
      ValueNotifier(const NeonSyncState());

  static const MethodChannel _nativeChannel =
      MethodChannel('com.example.apk_list/native_details');

  NeonSyncService({
    SharedPreferencesAsync? prefs,
    String? connectionUrl,
    String? host,
    String? database,
    String? user,
    String? password,
    int? port,
  })  : _prefs = prefs,
        host = _resolveHost(connectionUrl, host),
        database = _resolveDatabase(connectionUrl, database),
        user = _resolveUser(connectionUrl, user),
        password = _resolvePassword(connectionUrl, password),
        port = _resolvePort(connectionUrl, port);

  static const String _envUrl = String.fromEnvironment('NEON_DATABASE_URL');
  static const String _envHost = String.fromEnvironment('NEON_HOST');
  static const String _envDatabase = String.fromEnvironment('NEON_DATABASE', defaultValue: 'neondb');
  static const String _envUser = String.fromEnvironment('NEON_USER');
  static const String _envPassword = String.fromEnvironment('NEON_PASSWORD');
  static const int _envPort = int.fromEnvironment('NEON_PORT', defaultValue: 5432);

  static String _resolveHost(String? url, String? explicitHost) {
    if (explicitHost != null && explicitHost.trim().isNotEmpty) return explicitHost.trim();
    final effectiveUrl = (url != null && url.trim().isNotEmpty) ? url.trim() : _envUrl;
    if (effectiveUrl.isNotEmpty) {
      final parsed = _parseUrl(effectiveUrl);
      if (parsed != null && parsed.$1.isNotEmpty) return parsed.$1;
    }
    return _envHost.trim();
  }

  static String _resolveDatabase(String? url, String? explicitDb) {
    if (explicitDb != null && explicitDb.trim().isNotEmpty) return explicitDb.trim();
    final effectiveUrl = (url != null && url.trim().isNotEmpty) ? url.trim() : _envUrl;
    if (effectiveUrl.isNotEmpty) {
      final parsed = _parseUrl(effectiveUrl);
      if (parsed != null && parsed.$2.isNotEmpty) return parsed.$2;
    }
    return _envDatabase.trim();
  }

  static String _resolveUser(String? url, String? explicitUser) {
    if (explicitUser != null && explicitUser.trim().isNotEmpty) return explicitUser.trim();
    final effectiveUrl = (url != null && url.trim().isNotEmpty) ? url.trim() : _envUrl;
    if (effectiveUrl.isNotEmpty) {
      final parsed = _parseUrl(effectiveUrl);
      if (parsed != null && parsed.$3.isNotEmpty) return parsed.$3;
    }
    return _envUser.trim();
  }

  static String _resolvePassword(String? url, String? explicitPass) {
    if (explicitPass != null && explicitPass.isNotEmpty) return explicitPass;
    final effectiveUrl = (url != null && url.trim().isNotEmpty) ? url.trim() : _envUrl;
    if (effectiveUrl.isNotEmpty) {
      final parsed = _parseUrl(effectiveUrl);
      if (parsed != null && parsed.$4.isNotEmpty) return parsed.$4;
    }
    return _envPassword;
  }

  static int _resolvePort(String? url, int? explicitPort) {
    if (explicitPort != null && explicitPort > 0) return explicitPort;
    final effectiveUrl = (url != null && url.trim().isNotEmpty) ? url.trim() : _envUrl;
    if (effectiveUrl.isNotEmpty) {
      final parsed = _parseUrl(effectiveUrl);
      if (parsed != null && parsed.$5 > 0) return parsed.$5;
    }
    return _envPort;
  }

  static (String, String, String, String, int)? _parseUrl(String rawUrl) {
    try {
      final uri = Uri.parse(rawUrl);
      final userInfo = uri.userInfo;
      final user = userInfo.contains(':')
          ? userInfo.substring(0, userInfo.indexOf(':'))
          : userInfo;
      final pass = userInfo.contains(':')
          ? userInfo.substring(userInfo.indexOf(':') + 1)
          : '';
      final db = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'neondb';
      final port = uri.hasPort && uri.port != 0 ? uri.port : 5432;
      return (uri.host, db, user, pass, port);
    } on FormatException {
      return null;
    }
  }

  SharedPreferencesAsync get _effectivePrefs => _prefs ??= SharedPreferencesAsync();

  /// Indique si les identifiants requis sont présents.
  bool get isConfigured =>
      host.trim().isNotEmpty && user.trim().isNotEmpty && password.trim().isNotEmpty;

  /// Récupère les métadonnées matérielles de l'appareil (Marque/Modèle et version OS).
  Future<(String deviceModel, String osVersion)> getDeviceHardwareInfo() async {
    if (kIsWeb || !Platform.isAndroid) {
      return ('Linux Desktop (Dev)', 'Linux');
    }
    try {
      final info = await _nativeChannel.invokeMapMethod<String, String>('getDeviceInfo');
      final model = info?['fullName'] ?? 'Android Device';
      final os = info?['osVersion'] ?? 'Android';
      return (model, os);
    } catch (_) {
      return ('Android Device', 'Android');
    }
  }

  /// Récupère ou génère un identifiant unique anonyme (UUID v4) pour ce terminal.
  Future<String> getOrCreateDeviceId() async {
    const deviceIdKey = 'anonymous_device_uuid';
    final existingId = await _effectivePrefs.getString(deviceIdKey);
    if (existingId != null && existingId.trim().isNotEmpty) {
      return existingId.trim();
    }

    final newId = _generateUuidV4();
    await _effectivePrefs.setString(deviceIdKey, newId);
    return newId;
  }

  /// Synchronise automatiquement la liste des applications sans bloquer l'UI.
  Future<void> autoSyncApps(List<ApkModel> apps) async {
    if (!isConfigured) {
      stateNotifier.value = const NeonSyncState(
        status: NeonSyncStatus.idle,
        errorMessage: 'Neon non configuré (.env manquant)',
      );
      return;
    }

    if (apps.isEmpty) {
      return;
    }

    try {
      final count = await syncApps(apps);
      debugPrint('[NeonSync] $count applications synchronisées avec succès.');
    } on Object catch (e) {
      debugPrint('[NeonSync] Échec de synchronisation en arrière-plan: $e');
    }
  }

  /// Synchronise la liste des applications dans la base Neon avec attribution atomique de User X.
  Future<int> syncApps(List<ApkModel> apps) async {
    if (!isConfigured) {
      stateNotifier.value = const NeonSyncState(
        status: NeonSyncStatus.error,
        errorMessage: 'Configuration Neon manquante (.env).',
      );
      throw const NeonSyncException(
        'Configuration Neon manquante. Renseignez .env (NEON_DATABASE_URL ou NEON_HOST/NEON_USER/NEON_PASSWORD).',
      );
    }

    if (apps.isEmpty) {
      return 0;
    }

    stateNotifier.value = NeonSyncState(
      status: NeonSyncStatus.syncing,
      lastSyncTime: stateNotifier.value.lastSyncTime,
      syncedCount: stateNotifier.value.syncedCount,
      deviceId: stateNotifier.value.deviceId,
      userLabel: stateNotifier.value.userLabel,
      deviceModel: stateNotifier.value.deviceModel,
    );

    final deviceId = await getOrCreateDeviceId();
    final (hardwareModel, osVersion) = await getDeviceHardwareInfo();
    Connection? conn;

    try {
      final endpoint = Endpoint(
        host: host.trim(),
        database: database.trim(),
        username: user.trim(),
        password: password.trim(),
        port: port,
      );

      conn = await Connection.open(
        endpoint,
        settings: ConnectionSettings(
          sslMode: SslMode.require,
          connectTimeout: const Duration(seconds: 15),
          queryTimeout: const Duration(seconds: 45),
        ),
      );

      // Table des terminaux enregistrés pour attribution atomique et incrémentale de User 1, User 2...
      await conn.execute('''
        CREATE TABLE IF NOT EXISTS registered_devices (
            id SERIAL PRIMARY KEY,
            device_uuid TEXT UNIQUE NOT NULL,
            device_model TEXT NOT NULL,
            os_version TEXT NOT NULL,
            first_seen_at TIMESTAMPTZ DEFAULT NOW(),
            last_seen_at TIMESTAMPTZ DEFAULT NOW()
        );
      ''');

      // Insertion ou mise à jour atomique du terminal
      final deviceResult = await conn.execute(
        '''
        INSERT INTO registered_devices (device_uuid, device_model, os_version, first_seen_at, last_seen_at)
        VALUES (\$1, \$2, \$3, NOW(), NOW())
        ON CONFLICT (device_uuid) DO UPDATE SET
            device_model = EXCLUDED.device_model,
            os_version = EXCLUDED.os_version,
            last_seen_at = NOW()
        RETURNING id;
        ''',
        parameters: [deviceId, hardwareModel, osVersion],
      );

      final int userSeqId = deviceResult.first[0] as int;
      final String userLabel = 'User $userSeqId';

      // Table principale avec colonnes user_label et device_model
      await conn.execute('''
        CREATE TABLE IF NOT EXISTS device_inventory (
            id BIGSERIAL PRIMARY KEY,
            device_id TEXT NOT NULL,
            user_label TEXT,
            device_model TEXT,
            package_name TEXT NOT NULL,
            app_name TEXT NOT NULL,
            version_name TEXT NOT NULL,
            version_code INT NOT NULL,
            size_in_bytes BIGINT NOT NULL,
            target_sdk_version INT NOT NULL,
            installed_at TIMESTAMPTZ,
            last_updated_at TIMESTAMPTZ,
            synced_at TIMESTAMPTZ DEFAULT NOW(),
            CONSTRAINT unique_device_package UNIQUE (device_id, package_name)
        );
      ''');

      // Migration non-bloquante si la table existait déjà sans ces colonnes
      await conn.execute('ALTER TABLE device_inventory ADD COLUMN IF NOT EXISTS user_label TEXT;');
      await conn.execute('ALTER TABLE device_inventory ADD COLUMN IF NOT EXISTS device_model TEXT;');

      const upsertSql = '''
        INSERT INTO device_inventory (
            device_id, user_label, device_model, package_name, app_name, version_name, version_code,
            size_in_bytes, target_sdk_version, installed_at, last_updated_at, synced_at
        ) VALUES (
            \$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11, NOW()
        )
        ON CONFLICT (device_id, package_name) DO UPDATE SET
            user_label = EXCLUDED.user_label,
            device_model = EXCLUDED.device_model,
            app_name = EXCLUDED.app_name,
            version_name = EXCLUDED.version_name,
            version_code = EXCLUDED.version_code,
            size_in_bytes = EXCLUDED.size_in_bytes,
            target_sdk_version = EXCLUDED.target_sdk_version,
            last_updated_at = EXCLUDED.last_updated_at,
            synced_at = NOW();
      ''';

      await conn.runTx((session) async {
        for (final app in apps) {
          await session.execute(
            upsertSql,
            parameters: [
              deviceId,
              userLabel,
              hardwareModel,
              app.packageName,
              app.name,
              app.versionName,
              app.versionCode,
              app.sizeInBytes,
              app.targetSdkVersion,
              app.installDate.toUtc(),
              app.lastUpdateDate?.toUtc(),
            ],
          );
        }
      });

      stateNotifier.value = NeonSyncState(
        status: NeonSyncStatus.success,
        syncedCount: apps.length,
        lastSyncTime: DateTime.now(),
        deviceId: deviceId,
        userLabel: userLabel,
        deviceModel: hardwareModel,
      );

      return apps.length;
    } on ServerException catch (e) {
      stateNotifier.value = NeonSyncState(
        status: NeonSyncStatus.error,
        errorMessage: 'Erreur SQL serveur: ${e.message}',
        deviceId: deviceId,
        deviceModel: hardwareModel,
      );
      debugPrint('[NeonSync] Erreur SQL Neon: ${e.message}');
      throw NeonSyncException('Erreur SQL serveur Neon: ${e.message}', e);
    } on Object catch (e) {
      stateNotifier.value = NeonSyncState(
        status: NeonSyncStatus.error,
        errorMessage: 'Échec de synchronisation réseau Neon',
        deviceId: deviceId,
        deviceModel: hardwareModel,
      );
      debugPrint('[NeonSync] Échec de la connexion/synchronisation Neon: $e');
      throw NeonSyncException('Impossible de synchroniser avec Neon.', e);
    } finally {
      try {
        await conn?.close();
      } on Object catch (e) {
        debugPrint('[NeonSync] Fermeture connexion Neon échouée: $e');
      }
    }
  }

  /// Générateur cryptographique d'UUID v4 standard (RFC 4122).
  static String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // Version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variant RFC 4122
    final hexChars =
        bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hexChars.substring(0, 8)}-${hexChars.substring(8, 12)}-${hexChars.substring(12, 16)}-${hexChars.substring(16, 20)}-${hexChars.substring(20)}';
  }
}
