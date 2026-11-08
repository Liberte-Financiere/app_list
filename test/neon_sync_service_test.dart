import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:apk_list/models/apk_model.dart';
import 'package:apk_list/services/neon_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NeonSyncService', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    test('isConfigured renvoie faux si un champ obligatoire manque', () {
      final service1 = NeonSyncService(
        host: '',
        database: 'neondb',
        user: 'user',
        password: 'pwd',
      );
      expect(service1.isConfigured, isFalse);

      final service2 = NeonSyncService(
        host: 'ep-test.neon.tech',
        database: 'neondb',
        user: 'user',
        password: '',
      );
      expect(service2.isConfigured, isFalse);

      final service3 = NeonSyncService(
        host: 'ep-test.neon.tech',
        database: 'neondb',
        user: 'user',
        password: 'pwd',
      );
      expect(service3.isConfigured, isTrue);
    });

    test('getOrCreateDeviceId génère un UUID valide et le persiste', () async {
      final service = NeonSyncService();

      final id1 = await service.getOrCreateDeviceId();
      expect(id1, isNotEmpty);
      expect(
        RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')
            .hasMatch(id1),
        isTrue,
      );

      final id2 = await service.getOrCreateDeviceId();
      expect(id2, equals(id1));
    });

    test('syncApps lève NeonSyncException si non configuré', () async {
      final service = NeonSyncService(
        host: '',
        user: '',
        password: '',
      );

      final app = ApkModel(
        id: 'com.test',
        name: 'Test',
        packageName: 'com.test',
        versionName: '1.0',
        versionCode: 1,
        sizeInBytes: 100,
        filePath: '',
        installDate: DateTime.now(),
      );

      expect(() => service.syncApps([app]), throwsA(isA<NeonSyncException>()));
    });
  });
}
