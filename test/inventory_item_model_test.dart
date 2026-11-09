import 'package:flutter_test/flutter_test.dart';
import 'package:apk_list/models/apk_model.dart';
import 'package:apk_list/models/inventory_item_model.dart';

void main() {
  group('InventoryItemModel', () {
    test('Conversion depuis ApkModel et sérialisation avec permissions et métadonnées complètes', () {
      final now = DateTime(2026, 11, 8, 12, 0, 0);
      final apk = ApkModel(
        id: 'com.spotify.music',
        name: 'Spotify',
        packageName: 'com.spotify.music',
        versionName: '8.8.50',
        versionCode: 885000,
        sizeInBytes: 65000000,
        filePath: '/data/app/spotify.apk',
        installDate: now,
        lastUpdateDate: now.add(const Duration(days: 1)),
        targetSdkVersion: 34,
        isSystemApp: false,
        installerPackageName: 'com.transsion.phoenix',
        declaredPermissions: const [
          'android.permission.INTERNET',
          'android.permission.RECORD_AUDIO',
        ],
        grantedPermissions: const [
          'android.permission.INTERNET',
        ],
      );

      final item = InventoryItemModel.fromApkModel(
        apk,
        deviceId: 'uuid-1234',
        userLabel: 'User 2',
        deviceModel: 'Google Pixel 8',
      );

      expect(item.deviceId, 'uuid-1234');
      expect(item.userLabel, 'User 2');
      expect(item.deviceModel, 'Google Pixel 8');
      expect(item.packageName, 'com.spotify.music');
      expect(item.appName, 'Spotify');
      expect(item.versionName, '8.8.50');
      expect(item.versionCode, 885000);
      expect(item.sizeInBytes, 65000000);
      expect(item.targetSdkVersion, 34);
      expect(item.installerPackageName, 'com.transsion.phoenix');
      expect(item.installerDisplayName, 'Navigateur Phoenix');
      expect(item.filePath, '/data/app/spotify.apk');
      expect(item.isSystemApp, isFalse);
      expect(item.declaredPermissionsCount, 2);
      expect(item.grantedPermissionsCount, 1);
      expect(item.deniedPermissionsCount, 1);

      final payload = item.permissionsPayload;
      expect(payload['total_declared'], 2);
      expect(payload['total_granted'], 1);
      expect(payload['total_denied'], 1);
      expect(payload['declared'], ['android.permission.INTERNET', 'android.permission.RECORD_AUDIO']);
      expect(payload['granted'], ['android.permission.INTERNET']);
      expect(payload['denied'], ['android.permission.RECORD_AUDIO']);

      final json = item.toJson();
      expect(json['installer_display_name'], 'Navigateur Phoenix');
      expect(json['file_path'], '/data/app/spotify.apk');
      expect(json['is_system_app'], isFalse);
      expect(json['permissions_count'], 2);
      expect(json['granted_permissions_count'], 1);

      final fromJson = InventoryItemModel.fromJson(json);

      expect(fromJson.deviceId, 'uuid-1234');
      expect(fromJson.userLabel, 'User 2');
      expect(fromJson.deviceModel, 'Google Pixel 8');
      expect(fromJson.packageName, 'com.spotify.music');
      expect(fromJson.installerPackageName, 'com.transsion.phoenix');
      expect(fromJson.installerDisplayName, 'Navigateur Phoenix');
      expect(fromJson.filePath, '/data/app/spotify.apk');
      expect(fromJson.isSystemApp, isFalse);
      expect(fromJson.declaredPermissions, ['android.permission.INTERNET', 'android.permission.RECORD_AUDIO']);
      expect(fromJson.grantedPermissions, ['android.permission.INTERNET']);
    });

    test('Levée d\'exception sur JSON incomplet', () {
      expect(
        () => InventoryItemModel.fromJson({'deviceId': ''}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
