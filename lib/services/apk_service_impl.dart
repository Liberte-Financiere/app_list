import 'apk_service.dart';
import '../models/apk_model.dart';

/// Implémentation du service APK avec gestion rigoureuse des erreurs.
class ApkServiceImpl implements ApkService {
  final List<ApkModel> _cachedApks;

  ApkServiceImpl({List<ApkModel>? initialApks})
      : _cachedApks = initialApks ?? _generateInitialData();

  static List<ApkModel> _generateInitialData() {
    return [
      ApkModel(
        id: 'apk-1',
        name: 'Caméra Pro',
        packageName: 'com.example.camera.pro',
        versionName: '2.4.1',
        versionCode: 241,
        sizeInBytes: 34500000,
        filePath: '/storage/emulated/0/Download/camera_pro.apk',
        installDate: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ApkModel(
        id: 'apk-2',
        name: 'Lecteur Audio Hi-Fi',
        packageName: 'com.example.audio.player',
        versionName: '1.0.8',
        versionCode: 108,
        sizeInBytes: 15200000,
        filePath: '/storage/emulated/0/Download/audio_player.apk',
        installDate: DateTime.now().subtract(const Duration(days: 5)),
      ),
      ApkModel(
        id: 'apk-3',
        name: 'Explorateur Fichiers',
        packageName: 'com.example.file.explorer',
        versionName: '3.1.0',
        versionCode: 310,
        sizeInBytes: 8900000,
        filePath: '/storage/emulated/0/Download/file_explorer.apk',
        installDate: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];
  }

  @override
  Future<List<ApkModel>> fetchApkList() async {
    try {
      // Simulation d'une latence d'I/O ou d'appel asynchrone sécurisé
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return List.unmodifiable(_cachedApks);
    } on Object catch (e) {
      throw ApkServiceException(
        'Échec lors de la récupération de la liste des APKs.',
        e,
      );
    }
  }

  @override
  Future<ApkModel?> getApkById(String id) async {
    if (id.trim().isEmpty) {
      throw const ApkServiceException('Identifiant invalide fourni.');
    }

    try {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return _cachedApks.cast<ApkModel?>().firstWhere(
            (apk) => apk?.id == id.trim(),
            orElse: () => null,
          );
    } on Object catch (e) {
      throw ApkServiceException(
        'Échec lors de la recherche de l\'APK avec l\'identifiant $id.',
        e,
      );
    }
  }
}
