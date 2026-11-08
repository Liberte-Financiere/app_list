import 'package:flutter_test/flutter_test.dart';
import 'package:apk_list/models/device_model.dart';

void main() {
  group('DeviceModel', () {
    test('Validation stricte et sérialisation JSON', () {
      final now = DateTime(2026, 11, 8, 12, 0, 0);
      final device = DeviceModel(
        id: 1,
        deviceUuid: '550e8400-e29b-41d4-a716-446655440000',
        deviceModel: 'Samsung Galaxy S23',
        osVersion: 'Android 14',
        firstSeenAt: now,
        lastSeenAt: now,
      );

      expect(device.userLabel, 'User 1');

      final json = device.toJson();
      final fromJson = DeviceModel.fromJson(json);

      expect(fromJson.id, 1);
      expect(fromJson.deviceUuid, '550e8400-e29b-41d4-a716-446655440000');
      expect(fromJson.deviceModel, 'Samsung Galaxy S23');
      expect(fromJson.osVersion, 'Android 14');
      expect(fromJson.userLabel, 'User 1');
    });

    test('Levée d\'exception sur JSON invalide', () {
      expect(() => DeviceModel.fromJson({'deviceUuid': ''}), throwsA(isA<FormatException>()));
      expect(
        () => DeviceModel.fromJson({'deviceUuid': 'uuid', 'deviceModel': ''}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
