import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:apk_list/constants/app_strings.dart';
import 'package:apk_list/dashboard/app_permissions_screen.dart';
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

  testWidgets('Affiche le récapitulatif des permissions et permet de filtrer', (
    WidgetTester tester,
  ) async {
    bool settingsOpened = false;

    await tester.pumpWidget(
      MaterialApp(
        home: AppPermissionsScreen(
          app: testApp,
          onSettings: () => settingsOpened = true,
        ),
      ),
    );

    // Titre et métriques
    expect(find.text(AppStrings.permissionsTitle), findsOneWidget);
    expect(find.text('Super Application'), findsOneWidget);
    expect(find.text('com.example.superapp'), findsOneWidget);
    expect(find.text('3'), findsOneWidget); // Déclarées
    expect(find.text('2'), findsOneWidget); // Accordées
    expect(find.text('1'), findsOneWidget); // Refusées

    // Liste initiale (Toutes)
    expect(find.text('INTERNET'), findsOneWidget);
    expect(find.text('CAMERA'), findsOneWidget);
    expect(find.text('RECORD_AUDIO'), findsOneWidget);
    expect(find.text(AppStrings.grantedPermissions), findsNWidgets(3)); // 1 métrique + 2 badges
    expect(find.text(AppStrings.deniedPermissions), findsNWidgets(2)); // 1 métrique + 1 badge

    // Filtrer par Refusées
    await tester.tap(find.text('${AppStrings.deniedPermissions} (1)'));
    await tester.pumpAndSettle();

    expect(find.text('RECORD_AUDIO'), findsOneWidget);
    expect(find.text('CAMERA'), findsNothing);
    expect(find.text('INTERNET'), findsNothing);

    // Filtrer par Accordées
    await tester.tap(find.text('${AppStrings.grantedPermissions} (2)'));
    await tester.pumpAndSettle();

    expect(find.text('INTERNET'), findsOneWidget);
    expect(find.text('CAMERA'), findsOneWidget);
    expect(find.text('RECORD_AUDIO'), findsNothing);

    // Clic sur gérer dans les paramètres
    await tester.tap(find.widgetWithText(OutlinedButton, AppStrings.managePermissionsInSettings));
    expect(settingsOpened, isTrue);
  });

  testWidgets('Filtre par recherche textuelle sur les permissions', (
    WidgetTester tester,
  ) async {
    final manyPermissionsApp = ApkModel(
      id: 'com.example.bigapp',
      name: 'Big App',
      packageName: 'com.example.bigapp',
      versionName: '1.0',
      versionCode: 1,
      sizeInBytes: 1000,
      filePath: '',
      installDate: DateTime(2026, 1, 1),
      declaredPermissions: const [
        'android.permission.INTERNET',
        'android.permission.CAMERA',
        'android.permission.RECORD_AUDIO',
        'android.permission.ACCESS_FINE_LOCATION',
        'android.permission.VIBRATE',
      ],
      grantedPermissions: const [
        'android.permission.INTERNET',
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppPermissionsScreen(
          app: manyPermissionsApp,
          onSettings: () {},
        ),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'vibr');
    await tester.pumpAndSettle();

    expect(find.text('VIBRATE'), findsOneWidget);
    expect(find.text('INTERNET'), findsNothing);
    expect(find.text('CAMERA'), findsNothing);
  });

  testWidgets('Affiche un état vide lorsque aucune permission n\'est déclarée', (
    WidgetTester tester,
  ) async {
    final emptyPermApp = ApkModel(
      id: 'com.example.empty',
      name: 'Empty App',
      packageName: 'com.example.empty',
      versionName: '1.0',
      versionCode: 1,
      sizeInBytes: 1000,
      filePath: '',
      installDate: DateTime(2026, 1, 1),
      declaredPermissions: const [],
      grantedPermissions: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppPermissionsScreen(
          app: emptyPermApp,
          onSettings: () {},
        ),
      ),
    );

    expect(find.text(AppStrings.noPermissionsDeclared), findsOneWidget);
  });
}
