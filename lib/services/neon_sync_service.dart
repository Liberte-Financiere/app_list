import 'package:flutter/foundation.dart';
import 'package:postgres/postgres.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/apk_model.dart';
import '../models/inventory_item_model.dart';
import 'device_service.dart';
import 'inventory_service.dart';
import 'neon_connection_manager.dart';

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

/// Orchestrateur principal de synchronisation coordonnant `DeviceService` et `InventoryService`.
class NeonSyncService {
  final NeonConnectionManager _connectionManager;
  final DeviceService _deviceService;
  final InventoryService _inventoryService;

  final ValueNotifier<NeonSyncState> stateNotifier =
      ValueNotifier(const NeonSyncState());

  NeonSyncService({
    NeonConnectionManager? connectionManager,
    DeviceService? deviceService,
    InventoryService? inventoryService,
    SharedPreferencesAsync? prefs,
    String? connectionUrl,
    String? host,
    String? database,
    String? user,
    String? password,
    int? port,
  })  : _connectionManager = connectionManager ??
            NeonConnectionManager(
              connectionUrl: connectionUrl,
              host: host,
              database: database,
              user: user,
              password: password,
              port: port,
            ),
        _deviceService = deviceService ?? DeviceService(prefs: prefs),
        _inventoryService = inventoryService ?? InventoryService();

  String get host => _connectionManager.host;
  String get database => _connectionManager.database;
  String get user => _connectionManager.user;
  String get password => _connectionManager.password;
  int get port => _connectionManager.port;

  bool get isConfigured => _connectionManager.isConfigured;

  Future<String> getOrCreateDeviceId() => _deviceService.getOrCreateDeviceId();

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

  /// Synchronise les terminaux et les applications via leurs services respectifs.
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

    final deviceId = await _deviceService.getOrCreateDeviceId();
    final (hardwareModel, osVersion) = await _deviceService.getDeviceHardwareInfo();
    Connection? conn;

    try {
      conn = await _connectionManager.openConnection();

      // 1. Délégation à DeviceService pour l'enregistrement du terminal et obtention de User X
      final registeredDevice = await _deviceService.registerOrUpdateDevice(
        conn,
        deviceUuid: deviceId,
        deviceModel: hardwareModel,
        osVersion: osVersion,
      );

      final customUserName = await _deviceService.getUserName();
      final userLabel = (customUserName != null && customUserName.isNotEmpty)
          ? customUserName
          : registeredDevice.userLabel;

      // 2. Conversion des ApkModel en InventoryItemModel pour InventoryService
      final inventoryItems = apps.map((apk) {
        return InventoryItemModel.fromApkModel(
          apk,
          deviceId: deviceId,
          userLabel: userLabel,
          deviceModel: hardwareModel,
        );
      }).toList();

      // 3. Délégation à InventoryService pour l'insertion de l'inventaire
      final syncedCount = await _inventoryService.syncInventoryItems(conn, inventoryItems);

      stateNotifier.value = NeonSyncState(
        status: NeonSyncStatus.success,
        syncedCount: syncedCount,
        lastSyncTime: DateTime.now(),
        deviceId: deviceId,
        userLabel: userLabel,
        deviceModel: hardwareModel,
      );

      return syncedCount;
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
}
