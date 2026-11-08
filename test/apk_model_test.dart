import 'package:flutter_test/flutter_test.dart';
import 'package:apk_list/models/apk_model.dart';

void main() {
  group('ApkModel', () {
    test('Validation stricte et sérialisation JSON', () {
      final now = DateTime(2026, 11, 8, 10, 0, 0);
      final model = ApkModel(
        id: 'com.example.test',
        name: 'Test App',
        packageName: 'com.example.test',
        versionName: '2.0.1',
        versionCode: 42,
        sizeInBytes: 15728640, // 15 Mo
        filePath: '/data/app/test.apk',
        installDate: now,
        lastUpdateDate: now.add(const Duration(days: 1)),
        targetSdkVersion: 34,
        isSystemApp: false,
        installerPackageName: 'com.android.vending',
        grantedPermissions: const ['android.permission.INTERNET'],
        declaredPermissions: const ['android.permission.INTERNET', 'android.permission.CAMERA'],
      );

      final json = model.toJson();
      final fromJson = ApkModel.fromJson(json);

      expect(fromJson.id, 'com.example.test');
      expect(fromJson.name, 'Test App');
      expect(fromJson.packageName, 'com.example.test');
      expect(fromJson.versionName, '2.0.1');
      expect(fromJson.versionCode, 42);
      expect(fromJson.sizeInBytes, 15728640);
      expect(fromJson.formattedSize, '15.0 Mo');
      expect(fromJson.filePath, '/data/app/test.apk');
      expect(fromJson.targetSdkVersion, 34);
      expect(fromJson.installDate, now);
      expect(fromJson.lastUpdateDate, now.add(const Duration(days: 1)));
      expect(fromJson.isSystemApp, false);
      expect(fromJson.installerPackageName, 'com.android.vending');
      expect(fromJson.installerDisplayName, 'Google Play Store');
      expect(fromJson.grantedPermissions, ['android.permission.INTERNET']);
      expect(fromJson.declaredPermissions, ['android.permission.INTERNET', 'android.permission.CAMERA']);
    });

    test('Résolution du nom du magasin d\'installation', () {
      final now = DateTime.now();
      expect(
        ApkModel(
          id: '1',
          name: 'A',
          packageName: 'p',
          versionName: '1',
          versionCode: 1,
          sizeInBytes: 0,
          filePath: '',
          installDate: now,
          installerPackageName: 'com.android.vending',
        ).installerDisplayName,
        'Google Play Store',
      );

      expect(
        ApkModel(
          id: '2',
          name: 'B',
          packageName: 'p',
          versionName: '1',
          versionCode: 1,
          sizeInBytes: 0,
          filePath: '',
          installDate: now,
          installerPackageName: 'com.transsion.phoenix',
        ).installerDisplayName,
        'Navigateur Phoenix',
      );

      expect(
        ApkModel(
          id: '3',
          name: 'C',
          packageName: 'p',
          versionName: '1',
          versionCode: 1,
          sizeInBytes: 0,
          filePath: '',
          installDate: now,
          installerPackageName: '',
        ).installerDisplayName,
        'Inconnu / APK direct',
      );
    });

    test('Levée d\'exception sur JSON invalide', () {
      expect(() => ApkModel.fromJson({'id': ''}), throwsA(isA<FormatException>()));
      expect(
        () => ApkModel.fromJson({
          'id': '1',
          'name': 'App',
          'packageName': 'com.test',
          'versionName': '1.0',
          'versionCode': -1,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('Formatage des tailles', () {
      expect(
        ApkModel(
          id: '1',
          name: 'A',
          packageName: 'p',
          versionName: '1',
          versionCode: 1,
          sizeInBytes: 0,
          filePath: '',
          installDate: DateTime.now(),
        ).formattedSize,
        'Taille non dispo',
      );

      expect(
        ApkModel(
          id: '1',
          name: 'A',
          packageName: 'p',
          versionName: '1',
          versionCode: 1,
          sizeInBytes: 500,
          filePath: '',
          installDate: DateTime.now(),
        ).formattedSize,
        '500 o',
      );

      expect(
        ApkModel(
          id: '1',
          name: 'A',
          packageName: 'p',
          versionName: '1',
          versionCode: 1,
          sizeInBytes: 1048576,
          filePath: '',
          installDate: DateTime.now(),
        ).formattedSize,
        '1.0 Mo',
      );
    });
  });
}
