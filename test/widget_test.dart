import 'package:flutter_test/flutter_test.dart';
import 'package:apk_list/main.dart';
import 'package:apk_list/models/apk_model.dart';
import 'package:apk_list/services/apk_service.dart';

class TestApkService implements ApkService {
  final List<ApkModel> _data;

  TestApkService(this._data);

  @override
  Future<List<ApkModel>> fetchApkList() async => _data;

  @override
  Future<ApkModel?> getApkById(String id) async =>
      _data.cast<ApkModel?>().firstWhere((e) => e?.id == id, orElse: () => null);
}

void main() {
  testWidgets('Affiche la liste des APKs dans le Dashboard', (WidgetTester tester) async {
    final testApks = [
      ApkModel(
        id: 'test-1',
        name: 'App Test',
        packageName: 'com.test.app',
        versionName: '1.0.0',
        versionCode: 1,
        sizeInBytes: 1048576,
        filePath: '/test/app.apk',
        installDate: DateTime(2026, 1, 1),
      ),
    ];

    final service = TestApkService(testApks);

    await tester.pumpWidget(ApkApp(apkService: service));
    await tester.pumpAndSettle();

    expect(find.text('APK Manager'), findsOneWidget);
    expect(find.text('App Test'), findsOneWidget);
    expect(find.text('com.test.app'), findsOneWidget);
  });
}
