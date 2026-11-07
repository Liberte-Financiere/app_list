/// Constantes globales de l'application
abstract final class AppConstants {
  static const String appName = 'Applications Installées';
  static const String appVersion = '1.0.0';

  // Préférences
  static const String prefUserConsentKey = 'has_accepted_app_scan_consent';

  // Routes
  static const String dashboardRoute = '/';

  // Messages d'état
  static const String genericErrorMessage =
      'Une erreur inattendue est survenue lors de la récupération des applications.';
  static const String emptyListMessage = 'Aucune application trouvée sur l\'appareil.';
  static const String permissionRefusedMessage =
      'L\'autorisation d\'analyser les applications a été refusée. Veuillez accepter pour afficher les applications.';

  // Informations de consentement (Prominent Disclosure)
  static const String consentTitle = 'Autorisation d\'accès aux applications';
  static const String consentDescription =
      'Cette application nécessite l\'accès à la liste des applications installées sur votre appareil afin de les répertorier et les afficher dans votre tableau de bord. Aucune information personnelle ou sensible n\'est transmise à des tiers sans votre accord explicite.';
}
