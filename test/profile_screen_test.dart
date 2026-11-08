import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:apk_list/models/apk_model.dart';
import 'package:apk_list/profile/profile_screen.dart';
import 'package:apk_list/services/apk_service.dart';
import 'package:apk_list/services/neon_sync_service.dart';

class TestApkService implements ApkService {
  bool consent = true;
  String? userName = 'Adama';

  @override
  Future<bool> hasUserConsent() async => consent;

  @override
  Future<void> setUserConsent(bool granted) async {
    consent = granted;
  }

  @override
  Future<String?> getUserName() async => userName;

  @override
  Future<void> setUserName(String name) async {
    userName = name.trim();
  }

  @override
  Future<List<ApkModel>> fetchInstalledApps({bool includeSystemApps = false}) async => [];

  @override
  Future<bool> launchApp(String packageName) async => true;

  @override
  Future<void> openAppSettings(String packageName) async {}

  @override
  Stream<String> get onPackageChanged => const Stream.empty();
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('Affiche les informations du profil et du terminal', (WidgetTester tester) async {
    final apkService = TestApkService();
    final neonSync = NeonSyncService();

    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          apkService: apkService,
          neonSyncService: neonSync,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Profil & Appareil'), findsOneWidget);
    expect(find.text('Adama'), findsOneWidget);
    expect(find.text('Profil actif'), findsOneWidget);
    expect(find.text('Caractéristiques du terminal'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('Confidentialité & Données'), findsOneWidget);
  });

  testWidgets('Modification du nom d\'utilisateur depuis le profil', (WidgetTester tester) async {
    final apkService = TestApkService();
    final neonSync = NeonSyncService();

    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          apkService: apkService,
          neonSyncService: neonSync,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Clic sur le bouton d'édition
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Modifier le nom'), findsOneWidget);

    // Saisie du nouveau nom
    await tester.enterText(find.byType(TextFormField), 'NouveauPseudo');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('NouveauPseudo'), findsOneWidget);
    expect(apkService.userName, 'NouveauPseudo');
  });
}
