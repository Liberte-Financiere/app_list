import 'package:flutter/foundation.dart';

/// Modèle représentant un terminal enregistré dans la table Neon `registered_devices`.
@immutable
class DeviceModel {
  final int? id;
  final String deviceUuid;
  final String deviceModel;
  final String osVersion;
  final DateTime? firstSeenAt;
  final DateTime? lastSeenAt;

  const DeviceModel({
    this.id,
    required this.deviceUuid,
    required this.deviceModel,
    required this.osVersion,
    this.firstSeenAt,
    this.lastSeenAt,
  });

  /// Libellé utilisateur incrémental (ex: User 1, User 2).
  String get userLabel => id != null ? 'User $id' : 'User (Inconnu)';

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    final uuid = json['deviceUuid'] ?? json['device_uuid'];
    if (uuid is! String || uuid.trim().isEmpty) {
      throw const FormatException('Champ "deviceUuid" manquant ou invalide.');
    }

    final model = json['deviceModel'] ?? json['device_model'];
    if (model is! String || model.trim().isEmpty) {
      throw const FormatException('Champ "deviceModel" manquant ou invalide.');
    }

    final os = json['osVersion'] ?? json['os_version'];
    if (os is! String || os.trim().isEmpty) {
      throw const FormatException('Champ "osVersion" manquant ou invalide.');
    }

    final id = json['id'];
    DateTime? firstSeen;
    DateTime? lastSeen;

    if (json['first_seen_at'] is String) {
      firstSeen = DateTime.tryParse(json['first_seen_at'] as String);
    }
    if (json['last_seen_at'] is String) {
      lastSeen = DateTime.tryParse(json['last_seen_at'] as String);
    }

    return DeviceModel(
      id: id is int ? id : null,
      deviceUuid: uuid.trim(),
      deviceModel: model.trim(),
      osVersion: os.trim(),
      firstSeenAt: firstSeen,
      lastSeenAt: lastSeen,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'device_uuid': deviceUuid,
        'device_model': deviceModel,
        'os_version': osVersion,
        'first_seen_at': firstSeenAt?.toIso8601String(),
        'last_seen_at': lastSeenAt?.toIso8601String(),
      };

  DeviceModel copyWith({
    int? id,
    String? deviceUuid,
    String? deviceModel,
    String? osVersion,
    DateTime? firstSeenAt,
    DateTime? lastSeenAt,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      deviceUuid: deviceUuid ?? this.deviceUuid,
      deviceModel: deviceModel ?? this.deviceModel,
      osVersion: osVersion ?? this.osVersion,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceModel &&
          runtimeType == other.runtimeType &&
          deviceUuid == other.deviceUuid;

  @override
  int get hashCode => deviceUuid.hashCode;

  @override
  String toString() =>
      'DeviceModel(id: $id, label: $userLabel, model: $deviceModel, os: $osVersion)';
}
