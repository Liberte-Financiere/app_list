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
  final String installerPackageName;
  final String installerDisplayName;
  final String filePath;
  final bool isSystemApp;
  final List<String> declaredPermissions;
  final List<String> grantedPermissions;
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
    this.installerPackageName = '',
    this.installerDisplayName = '',
    this.filePath = '',
    this.isSystemApp = false,
    this.declaredPermissions = const [],
    this.grantedPermissions = const [],
    required this.installedAt,
    this.lastUpdatedAt,
    this.syncedAt,
  });

  int get declaredPermissionsCount => declaredPermissions.length;
  int get grantedPermissionsCount => grantedPermissions.length;
  int get deniedPermissionsCount =>
      (declaredPermissions.length - grantedPermissions.length).clamp(0, declaredPermissions.length);

  /// Structure JSON complète détaillée des permissions pour la table Neon.
  Map<String, dynamic> get permissionsPayload => {
        'total_declared': declaredPermissionsCount,
        'total_granted': grantedPermissionsCount,
        'total_denied': deniedPermissionsCount,
        'declared': declaredPermissions,
        'granted': grantedPermissions,
        'denied': declaredPermissions.where((p) => !grantedPermissions.contains(p)).toList(),
      };

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
      installerPackageName: apk.installerPackageName,
      installerDisplayName: apk.installerDisplayName,
      filePath: apk.filePath,
      isSystemApp: apk.isSystemApp,
      declaredPermissions: apk.declaredPermissions,
      grantedPermissions: apk.grantedPermissions,
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

    final declaredRaw = json['declaredPermissions'] ?? json['declared_permissions'];
    final declared = declaredRaw is List
        ? declaredRaw.whereType<String>().map((e) => e.trim()).toList()
        : const <String>[];

    final grantedRaw = json['grantedPermissions'] ?? json['granted_permissions'];
    final granted = grantedRaw is List
        ? grantedRaw.whereType<String>().map((e) => e.trim()).toList()
        : const <String>[];

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
      installerPackageName: (json['installerPackageName'] ?? json['installer_package_name'] ?? '').toString(),
      installerDisplayName: (json['installerDisplayName'] ?? json['installer_display_name'] ?? '').toString(),
      filePath: (json['filePath'] ?? json['file_path'] ?? '').toString(),
      isSystemApp: json['isSystemApp'] == true || json['is_system_app'] == true,
      declaredPermissions: declared,
      grantedPermissions: granted,
      installedAt: installedAt,
      lastUpdatedAt: lastUpdate,
      syncedAt: synced,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'device_id': deviceId,
        'user_label': userLabel,
        'device_model': deviceModel,
        'package_name': packageName,
        'app_name': appName,
        'version_name': versionName,
        'version_code': versionCode,
        'size_in_bytes': sizeInBytes,
        'target_sdk_version': targetSdkVersion,
        'installer_package_name': installerPackageName,
        'installer_display_name': installerDisplayName,
        'file_path': filePath,
        'is_system_app': isSystemApp,
        'declared_permissions': declaredPermissions,
        'granted_permissions': grantedPermissions,
        'permissions_payload': permissionsPayload,
        'permissions_count': declaredPermissionsCount,
        'granted_permissions_count': grantedPermissionsCount,
        'installed_at': installedAt.toIso8601String(),
        'last_updated_at': lastUpdatedAt?.toIso8601String(),
        'synced_at': syncedAt?.toIso8601String(),
      };
}
