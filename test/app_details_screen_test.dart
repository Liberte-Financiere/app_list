import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:apk_list/constants/app_strings.dart';
import 'package:apk_list/dashboard/app_details_screen.dart';
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

    // Vérifie la présence de l'élément dans la liste
    expect(find.text('Super Application'), findsOneWidget);

    // Clic sur le bouton d'information "Voir les détails"
    await tester.tap(find.byIcon(Icons.info_outline_rounded));
    await tester.pumpAndSettle();

    // Vérifie que l'écran AppDetailsScreen est ouvert (pas un AlertDialog ou SimpleDialog)
    expect(find.byType(AppDetailsScreen), findsOneWidget);
    expect(find.text(AppStrings.detailsScreenTitle), findsOneWidget);
    expect(find.text('Super Application'), findsWidgets);
    expect(find.text('com.example.superapp'), findsWidgets);

    // Test des actions depuis la page de détails
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.actionLaunch));
    expect(launched, isTrue);

    await tester.tap(find.widgetWithText(OutlinedButton, AppStrings.actionDetails));
    expect(settingsOpened, isTrue);
  });

  testWidgets('Affiche correctement toutes les métadonnées techniques et permissions', (
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

    // Section permissions
    expect(find.text(AppStrings.permissionsTitle), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('INTERNET'), findsOneWidget);
    expect(find.text('CAMERA'), findsOneWidget);
    expect(find.text('RECORD_AUDIO'), findsOneWidget);
    expect(find.text('Accordée'), findsNWidgets(2));
    expect(find.text('Refusée'), findsOneWidget);

    // Filtrage par permission refusée
    await tester.ensureVisible(find.text('Refusées (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Refusées (1)'));
    await tester.pumpAndSettle();

    expect(find.text('RECORD_AUDIO'), findsOneWidget);
    expect(find.text('CAMERA'), findsNothing);
    expect(find.text('INTERNET'), findsNothing);

    // Filtrage par permission accordée
    await tester.ensureVisible(find.text('Accordées (2)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accordées (2)'));
    await tester.pumpAndSettle();

    expect(find.text('INTERNET'), findsOneWidget);
    expect(find.text('CAMERA'), findsOneWidget);
    expect(find.text('RECORD_AUDIO'), findsNothing);
  });

  testWidgets('Affiche un message adéquat lorsque l\'application n\'a pas de permissions', (
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

    expect(find.text('Cette application ne demande aucune permission spécifique.'), findsOneWidget);
  });
}
