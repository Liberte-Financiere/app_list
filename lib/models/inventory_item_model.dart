import 'package:flutter/foundation.dart';
import 'apk_model.dart';

/// Modèle représentant une entrée d'inventaire applicatif dans la table Neon `device_inventory`.
@immutable
class InventoryItemModel {
  final int? id;
  final String deviceId;
  final String userLabel;
  final String deviceModel;
  final String packageName;
  final String appName;
  final String versionName;
  final int versionCode;
  final int sizeInBytes;
  final int targetSdkVersion;
  final DateTime installedAt;
  final DateTime? lastUpdatedAt;
  final DateTime? syncedAt;

  const InventoryItemModel({
    this.id,
    required this.deviceId,
    required this.userLabel,
    required this.deviceModel,
    required this.packageName,
    required this.appName,
    required this.versionName,
    required this.versionCode,
    required this.sizeInBytes,
    required this.targetSdkVersion,
    required this.installedAt,
    this.lastUpdatedAt,
    this.syncedAt,
  });

  /// Factory construisant un élément d'inventaire à partir d'un `ApkModel`.
  factory InventoryItemModel.fromApkModel(
    ApkModel apk, {
    required String deviceId,
    required String userLabel,
    required String deviceModel,
  }) {
    return InventoryItemModel(
      deviceId: deviceId,
      userLabel: userLabel,
      deviceModel: deviceModel,
      packageName: apk.packageName,
      appName: apk.name,
      versionName: apk.versionName,
      versionCode: apk.versionCode,
      sizeInBytes: apk.sizeInBytes,
      targetSdkVersion: apk.targetSdkVersion,
      installedAt: apk.installDate,
      lastUpdatedAt: apk.lastUpdateDate,
      syncedAt: DateTime.now(),
    );
  }

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    final deviceId = json['deviceId'] ?? json['device_id'];
    if (deviceId is! String || deviceId.trim().isEmpty) {
      throw const FormatException('Champ "deviceId" manquant.');
    }

    final packageName = json['packageName'] ?? json['package_name'];
    if (packageName is! String || packageName.trim().isEmpty) {
      throw const FormatException('Champ "packageName" manquant.');
    }

    final appName = json['appName'] ?? json['app_name'];
    if (appName is! String || appName.trim().isEmpty) {
      throw const FormatException('Champ "appName" manquant.');
    }

    final installedAtRaw = json['installedAt'] ?? json['installed_at'];
    final DateTime installedAt;
    if (installedAtRaw is String) {
      final parsed = DateTime.tryParse(installedAtRaw);
      if (parsed == null) {
        throw const FormatException('Format de date "installedAt" invalide.');
      }
      installedAt = parsed;
    } else {
      throw const FormatException('Champ "installedAt" manquant.');
    }

    DateTime? lastUpdate;
    final lastUpdateRaw = json['lastUpdatedAt'] ?? json['last_updated_at'];
    if (lastUpdateRaw is String) {
      lastUpdate = DateTime.tryParse(lastUpdateRaw);
    }

    DateTime? synced;
    final syncedRaw = json['syncedAt'] ?? json['synced_at'];
    if (syncedRaw is String) {
      synced = DateTime.tryParse(syncedRaw);
    }

    return InventoryItemModel(
      id: json['id'] is int ? json['id'] as int : null,
      deviceId: deviceId.trim(),
      userLabel: (json['userLabel'] ?? json['user_label'] ?? 'User ?').toString(),
      deviceModel: (json['deviceModel'] ?? json['device_model'] ?? 'Unknown').toString(),
      packageName: packageName.trim(),
      appName: appName.trim(),
      versionName: (json['versionName'] ?? json['version_name'] ?? 'Inconnue').toString(),
      versionCode: json['versionCode'] ?? json['version_code'] ?? 0,
      sizeInBytes: json['sizeInBytes'] ?? json['size_in_bytes'] ?? 0,
      targetSdkVersion: json['targetSdkVersion'] ?? json['target_sdk_version'] ?? 0,
      installedAt: installedAt,
      lastUpdatedAt: lastUpdate,
      syncedAt: synced,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'device_id': deviceId,
        'user_label': userLabel,
        'device_model': deviceModel,
        'package_name': packageName,
        'app_name': appName,
        'version_name': versionName,
        'version_code': versionCode,
        'size_in_bytes': sizeInBytes,
        'target_sdk_version': targetSdkVersion,
        'installed_at': installedAt.toIso8601String(),
        'last_updated_at': lastUpdatedAt?.toIso8601String(),
        'synced_at': syncedAt?.toIso8601String(),
      };
}
