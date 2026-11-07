import '../models/apk_model.dart';

/// Exception levée lors d'une défaillance du service de gestion des applications.
class ApkServiceException implements Exception {
  final String message;
  final Object? cause;

  const ApkServiceException(this.message, [this.cause]);

  @override
  String toString() => 'ApkServiceException: $message';
}

/// Contrat abstrait pour le service d'accès aux applications du système.
abstract class ApkService {
  /// Vérifie si l'utilisateur a consenti à l'analyse des applications.
  Future<bool> hasUserConsent();

  /// Enregistre le choix de consentement de l'utilisateur.
  Future<void> setUserConsent(bool granted);

  /// Récupère la liste des applications installées sur l'appareil.
  Future<List<ApkModel>> fetchInstalledApps({bool includeSystemApps = false});

  /// Lance l'application correspondant au nom de package donné.
  Future<bool> launchApp(String packageName);

  /// Ouvre la page des paramètres système de l'application ciblée.
  Future<void> openAppSettings(String packageName);
}
