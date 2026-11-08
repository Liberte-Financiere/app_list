import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:apk_list/dashboard/widgets/neon_status_banner.dart';
import 'package:apk_list/services/neon_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('Affiche le statut de synchronisation et la preuve d\'envoi', (
    WidgetTester tester,
  ) async {
    final service = NeonSyncService(
      connectionUrl:
          'postgresql://test:pwd@ep-test.neon.tech/neondb?sslmode=require',
    );

    service.stateNotifier.value = NeonSyncState(
      status: NeonSyncStatus.success,
      syncedCount: 15,
      lastSyncTime: DateTime(2026, 11, 8, 14, 30, 0),
      deviceId: 'test-device-uuid-1234',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NeonStatusBanner(neonSyncService: service),
        ),
      ),
    );

    expect(find.textContaining('Données enregistrées dans Neon'), findsOneWidget);
    expect(find.textContaining('15 apps'), findsOneWidget);

    // Clic sur la bannière pour ouvrir la preuve d'envoi
    await tester.tap(find.byType(NeonStatusBanner));
    await tester.pumpAndSettle();

    expect(find.text('Preuve d\'envoi Backend'), findsOneWidget);
    expect(find.text('device_inventory'), findsOneWidget);
    expect(find.text('test-device-uuid-1234'), findsOneWidget);
  });
}
