import 'package:flutter/foundation.dart';

/// Modèle métier immuable représentant une application avec ses métadonnées techniques.
@immutable
class ApkModel {
  final String id;
  final String name;
  final String packageName;
  final String versionName;
  final int versionCode;
  final int sizeInBytes;
  final String filePath;
  final DateTime installDate;
  final DateTime? lastUpdateDate;
  final int targetSdkVersion;
  final Uint8List? iconBytes;
  final bool isSystemApp;

  const ApkModel({
    required this.id,
    required this.name,
    required this.packageName,
    required this.versionName,
    required this.versionCode,
    required this.sizeInBytes,
    required this.filePath,
    required this.installDate,
    this.lastUpdateDate,
    this.targetSdkVersion = 0,
    this.iconBytes,
    this.isSystemApp = false,
  });

  /// Factory avec validation stricte des données d'entrée.
  factory ApkModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.trim().isEmpty) {
      throw const FormatException('Champ "id" invalide ou absent.');
    }

    final name = json['name'];
    if (name is! String || name.trim().isEmpty) {
      throw const FormatException('Champ "name" invalide ou absent.');
    }

    final packageName = json['packageName'];
    if (packageName is! String || packageName.trim().isEmpty) {
      throw const FormatException('Champ "packageName" invalide ou absent.');
    }

    final versionName = json['versionName'];
    if (versionName is! String) {
      throw const FormatException('Champ "versionName" invalide.');
    }

    final versionCode = json['versionCode'];
    if (versionCode is! int || versionCode < 0) {
      throw const FormatException('Champ "versionCode" invalide ou négatif.');
    }

    final sizeInBytes = json['sizeInBytes'];
    if (sizeInBytes is! int || sizeInBytes < 0) {
      throw const FormatException('Champ "sizeInBytes" invalide ou négatif.');
    }

    final filePath = json['filePath'];
    if (filePath is! String) {
      throw const FormatException('Champ "filePath" invalide.');
    }

    final installDateRaw = json['installDate'];
    final DateTime installDate;
    if (installDateRaw is String) {
      final parsed = DateTime.tryParse(installDateRaw);
      if (parsed == null) {
        throw const FormatException('Format de date "installDate" invalide.');
      }
      installDate = parsed;
    } else {
      throw const FormatException('Champ "installDate" invalide ou absent.');
    }

    DateTime? lastUpdateDate;
    if (json['lastUpdateDate'] is String) {
      lastUpdateDate = DateTime.tryParse(json['lastUpdateDate'] as String);
    }

    return ApkModel(
      id: id.trim(),
      name: name.trim(),
      packageName: packageName.trim(),
      versionName: versionName.trim().isEmpty ? 'Inconnue' : versionName.trim(),
      versionCode: versionCode,
      sizeInBytes: sizeInBytes,
      filePath: filePath.trim(),
      installDate: installDate,
      lastUpdateDate: lastUpdateDate,
      targetSdkVersion: json['targetSdkVersion'] is int ? json['targetSdkVersion'] as int : 0,
      isSystemApp: json['isSystemApp'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'packageName': packageName,
        'versionName': versionName,
        'versionCode': versionCode,
        'sizeInBytes': sizeInBytes,
        'filePath': filePath,
        'installDate': installDate.toIso8601String(),
        'lastUpdateDate': lastUpdateDate?.toIso8601String(),
        'targetSdkVersion': targetSdkVersion,
        'isSystemApp': isSystemApp,
      };

  /// Retourne la taille formatée lisiblement (ex: 24.5 Mo).
  String get formattedSize {
    if (sizeInBytes <= 0) return 'Taille non dispo';
    if (sizeInBytes < 1024) return '$sizeInBytes o';
    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} Ko';
    }
    if (sizeInBytes < 1024 * 1024 * 1024) {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
    }
    return '${(sizeInBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} Go';
  }

  ApkModel copyWith({
    String? id,
    String? name,
    String? packageName,
    String? versionName,
    int? versionCode,
    int? sizeInBytes,
    String? filePath,
    DateTime? installDate,
    DateTime? lastUpdateDate,
    int? targetSdkVersion,
    Uint8List? iconBytes,
    bool? isSystemApp,
  }) {
    return ApkModel(
      id: id ?? this.id,
      name: name ?? this.name,
      packageName: packageName ?? this.packageName,
      versionName: versionName ?? this.versionName,
      versionCode: versionCode ?? this.versionCode,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
      filePath: filePath ?? this.filePath,
      installDate: installDate ?? this.installDate,
      lastUpdateDate: lastUpdateDate ?? this.lastUpdateDate,
      targetSdkVersion: targetSdkVersion ?? this.targetSdkVersion,
      iconBytes: iconBytes ?? this.iconBytes,
      isSystemApp: isSystemApp ?? this.isSystemApp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApkModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          packageName == other.packageName;

  @override
  int get hashCode => id.hashCode ^ packageName.hashCode;

  @override
  String toString() =>
      'ApkModel(id: $id, name: $name, packageName: $packageName, version: $versionName, size: $formattedSize)';
}
