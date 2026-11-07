import '../models/apk_model.dart';

/// Exception levée lors d'une défaillance du service APK.
class ApkServiceException implements Exception {
  final String message;
  final Object? cause;

  const ApkServiceException(this.message, [this.cause]);

  @override
  String toString() => 'ApkServiceException: $message';
}

/// Contrat abstrait pour le service de gestion des APKs.
abstract class ApkService {
  /// Récupère la liste de tous les APKs scannés ou disponibles.
  Future<List<ApkModel>> fetchApkList();

  /// Récupère un APK par son identifiant unique.
  Future<ApkModel?> getApkById(String id);
}
