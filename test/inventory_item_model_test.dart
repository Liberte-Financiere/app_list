import 'package:flutter_test/flutter_test.dart';
import 'package:apk_list/models/apk_model.dart';
import 'package:apk_list/models/inventory_item_model.dart';

void main() {
  group('InventoryItemModel', () {
    test('Conversion depuis ApkModel et sérialisation', () {
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

      final json = item.toJson();
      final fromJson = InventoryItemModel.fromJson(json);

      expect(fromJson.deviceId, 'uuid-1234');
      expect(fromJson.userLabel, 'User 2');
      expect(fromJson.deviceModel, 'Google Pixel 8');
      expect(fromJson.packageName, 'com.spotify.music');
    });

    test('Levée d\'exception sur JSON incomplet', () {
      expect(
        () => InventoryItemModel.fromJson({'deviceId': ''}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
