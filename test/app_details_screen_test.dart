import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:apk_list/constants/app_strings.dart';
import 'package:apk_list/dashboard/app_details_screen.dart';
import 'package:apk_list/dashboard/app_permissions_screen.dart';
import 'package:apk_list/dashboard/widgets/app_list_item.dart';
import 'package:apk_list/models/apk_model.dart';

void main() {
  final testApp = ApkModel(
    id: 'com.example.superapp',
    name: 'Super Application',
    packageName: 'com.example.superapp',
    versionName: '2.4.0',
    versionCode: 48,
    sizeInBytes: 15400000,
    filePath: '/data/app/~~xyz==/com.example.superapp.apk',
    installDate: DateTime(2026, 2, 10, 14, 30),
    lastUpdateDate: DateTime(2026, 3, 1, 9, 15),
    targetSdkVersion: 34,
    isSystemApp: false,
    installerPackageName: 'com.android.vending',
    declaredPermissions: const [
      'android.permission.INTERNET',
      'android.permission.CAMERA',
      'android.permission.RECORD_AUDIO',
    ],
    grantedPermissions: const [
      'android.permission.INTERNET',
      'android.permission.CAMERA',
    ],
  );

  testWidgets('Ouvre AppDetailsScreen lors du clic sur la carte ou le bouton détails', (
    WidgetTester tester,
  ) async {
    bool launched = false;
    bool settingsOpened = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppListItem(
            app: testApp,
            onLaunch: () => launched = true,
            onSettings: () => settingsOpened = true,
          ),
        ),
      ),
    );

    expect(find.text('Super Application'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.info_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(AppDetailsScreen), findsOneWidget);
    expect(find.text(AppStrings.detailsScreenTitle), findsOneWidget);
    expect(find.text('Super Application'), findsWidgets);
    expect(find.text('com.example.superapp'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, AppStrings.actionLaunch));
    expect(launched, isTrue);

    await tester.tap(find.widgetWithText(OutlinedButton, AppStrings.actionDetails));
    expect(settingsOpened, isTrue);
  });

  testWidgets('Affiche les informations techniques et permet d\'ouvrir la page des permissions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppDetailsScreen(
          app: testApp,
          onLaunch: () {},
          onSettings: () {},
        ),
      ),
    );

    // En-tête et badges
    expect(find.text('Super Application'), findsWidgets);
    expect(find.text('v2.4.0 (48)'), findsOneWidget);
    expect(find.text('Google Play Store'), findsWidgets);
    expect(find.text('UTILISATEUR'), findsOneWidget);

    // Section technique
    expect(find.text(AppStrings.technicalInfoTitle), findsOneWidget);
    expect(find.text('API 34 (Android 14)'), findsOneWidget);
    expect(find.text('/data/app/~~xyz==/com.example.superapp.apk'), findsOneWidget);
    expect(find.text('10/02/2026 à 14:30'), findsOneWidget);
    expect(find.text('01/03/2026 à 09:15'), findsOneWidget);

    // Ligne des permissions intégrée au cadre technique
    expect(find.text('Permissions système'), findsOneWidget);
    expect(find.text('2 accordée(s) sur 3 déclarée(s)'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, AppStrings.actionViewPermissions), findsOneWidget);

    // Clic sur "Voir les permissions" ouvre la page dédiée AppPermissionsScreen
    await tester.ensureVisible(find.widgetWithText(FilledButton, AppStrings.actionViewPermissions));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.actionViewPermissions));
    await tester.pumpAndSettle();

    expect(find.byType(AppPermissionsScreen), findsOneWidget);
    expect(find.text(AppStrings.permissionsTitle), findsOneWidget);
  });

  testWidgets('Affiche un libellé adéquat lorsque l\'application n\'a pas de permissions déclarées', (
    WidgetTester tester,
  ) async {
    final minimalApp = ApkModel(
      id: 'com.simple.app',
      name: 'Simple App',
      packageName: 'com.simple.app',
      versionName: '1.0',
      versionCode: 1,
      sizeInBytes: 1024,
      filePath: '',
      installDate: DateTime(2026, 1, 1),
      declaredPermissions: const [],
      grantedPermissions: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppDetailsScreen(
          app: minimalApp,
          onLaunch: () {},
          onSettings: () {},
        ),
      ),
    );

    expect(find.text('Aucune permission demandée'), findsOneWidget);
  });
}
