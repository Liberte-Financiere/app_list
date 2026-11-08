import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:postgres/postgres.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/device_model.dart';

/// Service dédié à la gestion des terminaux et de la table `registered_devices`.
class DeviceService {
  SharedPreferencesAsync? _prefs;

  DeviceService({SharedPreferencesAsync? prefs}) : _prefs = prefs;

  SharedPreferencesAsync get _effectivePrefs => _prefs ??= SharedPreferencesAsync();

  static const MethodChannel _nativeChannel =
      MethodChannel('com.example.apk_list/native_details');

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

  /// Assure la présence de la table `registered_devices` dans Neon.
  Future<void> ensureTableExists(Connection conn) async {
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
  }

  /// Enregistre ou met à jour le terminal et retourne le `DeviceModel` complet avec son numéro séquentiel.
  Future<DeviceModel> registerOrUpdateDevice(
    Connection conn, {
    required String deviceUuid,
    required String deviceModel,
    required String osVersion,
  }) async {
    await ensureTableExists(conn);

    final result = await conn.execute(
      '''
      INSERT INTO registered_devices (device_uuid, device_model, os_version, first_seen_at, last_seen_at)
      VALUES (\$1, \$2, \$3, NOW(), NOW())
      ON CONFLICT (device_uuid) DO UPDATE SET
          device_model = EXCLUDED.device_model,
          os_version = EXCLUDED.os_version,
          last_seen_at = NOW()
      RETURNING id, first_seen_at, last_seen_at;
      ''',
      parameters: [deviceUuid, deviceModel, osVersion],
    );

    final row = result.first;
    final int seqId = row[0] as int;
    final DateTime firstSeen = row[1] as DateTime;
    final DateTime lastSeen = row[2] as DateTime;

    return DeviceModel(
      id: seqId,
      deviceUuid: deviceUuid,
      deviceModel: deviceModel,
      osVersion: osVersion,
      firstSeenAt: firstSeen,
      lastSeenAt: lastSeen,
    );
  }

  static String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hexChars =
        bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hexChars.substring(0, 8)}-${hexChars.substring(8, 12)}-${hexChars.substring(12, 16)}-${hexChars.substring(16, 20)}-${hexChars.substring(20)}';
  }
}
