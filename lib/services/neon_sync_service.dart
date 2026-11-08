import 'dart:math';
import 'package:flutter/foundation.dart';
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

/// Service gérant la synchronisation directe entre l'application et Neon PostgreSQL.
/// Conçu pour un usage personnel avec sécurisation des identifiants via variables d'environnement.
class NeonSyncService {
  SharedPreferencesAsync? _prefs;
  final String host;
  final String database;
  final String user;
  final String password;
  final int port;

  NeonSyncService({
    SharedPreferencesAsync? prefs,
    String? host,
    String? database,
    String? user,
    String? password,
    int? port,
  })  : _prefs = prefs,
        host = host ?? const String.fromEnvironment('NEON_HOST'),
        database = database ??
            const String.fromEnvironment('NEON_DATABASE', defaultValue: 'neondb'),
        user = user ?? const String.fromEnvironment('NEON_USER'),
        password = password ?? const String.fromEnvironment('NEON_PASSWORD'),
        port = port ??
            const int.fromEnvironment('NEON_PORT', defaultValue: 5432);

  SharedPreferencesAsync get _effectivePrefs => _prefs ??= SharedPreferencesAsync();

  /// Indique si les identifiants requis sont présents.
  bool get isConfigured =>
      host.trim().isNotEmpty && user.trim().isNotEmpty && password.trim().isNotEmpty;

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

  /// Synchronise la liste des applications dans la base Neon.
  /// Retourne le nombre d'applications synchronisées.
  Future<int> syncApps(List<ApkModel> apps) async {
    if (!isConfigured) {
      throw const NeonSyncException(
        'Configuration Neon manquante. Renseignez le fichier .env (NEON_HOST, NEON_USER, NEON_PASSWORD).',
      );
    }

    if (apps.isEmpty) {
      return 0;
    }

    final deviceId = await getOrCreateDeviceId();
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

      // Initialisation de la table si inexistante
      await conn.execute('''
        CREATE TABLE IF NOT EXISTS device_inventory (
            id BIGSERIAL PRIMARY KEY,
            device_id TEXT NOT NULL,
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

      const upsertSql = '''
        INSERT INTO device_inventory (
            device_id, package_name, app_name, version_name, version_code,
            size_in_bytes, target_sdk_version, installed_at, last_updated_at, synced_at
        ) VALUES (
            \$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, NOW()
        )
        ON CONFLICT (device_id, package_name) DO UPDATE SET
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

      return apps.length;
    } on ServerException catch (e) {
      debugPrint('Erreur SQL Neon: ${e.message}');
      throw NeonSyncException('Erreur SQL renvoyée par le serveur Neon: ${e.message}', e);
    } on Object catch (e) {
      debugPrint('Échec de la connexion/synchronisation Neon: $e');
      throw NeonSyncException('Impossible de synchroniser avec Neon.', e);
    } finally {
      try {
        await conn?.close();
      } on Object catch (e) {
        debugPrint('Fermeture de connexion Neon échouée: $e');
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
