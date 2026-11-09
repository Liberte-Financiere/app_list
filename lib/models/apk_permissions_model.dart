import 'package:flutter/foundation.dart';

/// Modèle découplé représentant les permissions d'une application.
/// Isolé pour la maintenance et l'extensibilité sans alourdir le modèle principal ApkModel ni le scan en masse.
@immutable
class ApkPermissionsModel {
  final String packageName;
  final List<String> declaredPermissions;
  final List<String> grantedPermissions;

  const ApkPermissionsModel({
    required this.packageName,
    this.declaredPermissions = const [],
    this.grantedPermissions = const [],
  });

  /// Instance vide par défaut.
  factory ApkPermissionsModel.empty(String packageName) => ApkPermissionsModel(
        packageName: packageName,
        declaredPermissions: const [],
        grantedPermissions: const [],
      );

  factory ApkPermissionsModel.fromJson(Map<String, dynamic> json) {
    final pkg = json['packageName'] ?? json['package_name'];
    if (pkg is! String || pkg.trim().isEmpty) {
      throw const FormatException('Champ "packageName" manquant ou invalide.');
    }

    final declared = json['declaredPermissions'] ?? json['declared_permissions'];
    final granted = json['grantedPermissions'] ?? json['granted_permissions'];

    return ApkPermissionsModel(
      packageName: pkg.trim(),
      declaredPermissions: declared is List
          ? declared.whereType<String>().map((e) => e.trim()).toList()
          : const [],
      grantedPermissions: granted is List
          ? granted.whereType<String>().map((e) => e.trim()).toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'declaredPermissions': declaredPermissions,
        'grantedPermissions': grantedPermissions,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApkPermissionsModel &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName &&
          listEquals(declaredPermissions, other.declaredPermissions) &&
          listEquals(grantedPermissions, other.grantedPermissions);

  @override
  int get hashCode =>
      packageName.hashCode ^
      Object.hashAll(declaredPermissions) ^
      Object.hashAll(grantedPermissions);
}
