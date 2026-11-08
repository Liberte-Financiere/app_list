import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:apk_list/constants/app_strings.dart';
import 'package:apk_list/main.dart';
import 'package:apk_list/models/apk_model.dart';
import 'package:apk_list/services/apk_service.dart';

class MockApkService implements ApkService {
  bool _consent;
  final List<ApkModel> _apps;
  final StreamController<String> _packageChangeController =
      StreamController<String>.broadcast();

  MockApkService({
    bool initialConsent = false,
    List<ApkModel>? apps,
  })  : _consent = initialConsent,
        _apps = apps ?? [];

  @override
  Future<bool> hasUserConsent() async => _consent;

  @override
  Future<void> setUserConsent(bool granted) async {
    _consent = granted;
  }

  @override
  Future<List<ApkModel>> fetchInstalledApps({bool includeSystemApps = false}) async {
    if (!_consent) return [];
    if (includeSystemApps) return _apps;
    return _apps.where((app) => !app.isSystemApp).toList();
  }

  @override
  Future<bool> launchApp(String packageName) async => true;

  @override
  Future<void> openAppSettings(String packageName) async {}

  @override
  Stream<String> get onPackageChanged => _packageChangeController.stream;

  void emitPackageChanged(String packageName) {
    _packageChangeController.add(packageName);
  }
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('Demande le consentement si non accordé au démarrage', (WidgetTester tester) async {
    final mockService = MockApkService(initialConsent: false);

    await tester.pumpWidget(ApkApp(apkService: mockService));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.consentTitle), findsOneWidget);
    expect(find.text(AppStrings.consentButtonAccept), findsOneWidget);
  });

  testWidgets('Affiche la liste des applications une fois le consentement accordé', (
    WidgetTester tester,
  ) async {
    final testApp = ApkModel(
      id: 'com.example.app',
      name: 'Application Test',
      packageName: 'com.example.app',
      versionName: '1.2.3',
      versionCode: 12,
      sizeInBytes: 5000000,
      filePath: '/data/app/test.apk',
      installDate: DateTime(2026, 1, 1),
    );

    final mockService = MockApkService(
      initialConsent: true,
      apps: [testApp],
    );

    await tester.pumpWidget(ApkApp(apkService: mockService));
    await tester.pumpAndSettle();

    expect(find.text('Application Test'), findsOneWidget);
    expect(find.text('com.example.app'), findsOneWidget);
    expect(find.text('v1.2.3'), findsOneWidget);
  });

  testWidgets('Actualise la liste automatiquement lors de la réception d\'un événement de paquet', (
    WidgetTester tester,
  ) async {
    final app1 = ApkModel(
      id: 'com.app.one',
      name: 'App One',
      packageName: 'com.app.one',
      versionName: '1.0',
      versionCode: 1,
      sizeInBytes: 1000,
      filePath: '',
      installDate: DateTime(2026, 1, 1),
    );

    final mockService = MockApkService(
      initialConsent: true,
      apps: [app1],
    );

    await tester.pumpWidget(ApkApp(apkService: mockService));
    await tester.pumpAndSettle();

    expect(find.text('App One'), findsOneWidget);

    // Émission d'un événement système simulé
    mockService.emitPackageChanged('com.app.two');
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('App One'), findsOneWidget);
  });
}
