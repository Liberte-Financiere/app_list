/// Centralisation exhaustive des chaînes de caractères de l'application.
abstract final class AppStrings {
  // Informations générales
  static const String appName = 'APK Manager Pro';
  static const String appTagline = 'Inventaire des applications installées';

  // Préférences & Clés de stockage
  static const String prefConsentKey = 'has_accepted_app_scan_consent';

  // Écran de consentement
  static const String consentTitle = 'Autorisation d\'accès aux applications';
  static const String consentSubtitle =
      'Pour afficher la liste complète de vos applications, une autorisation locale est requise.';
  static const String consentBody =
      'Conformément aux directives de sécurité Android et à la protection des données, '
      'cette application analyse uniquement les métadonnées locales (nom, version, icône). '
      'Aucune donnée personnelle n\'est collectée ni envoyée vers des serveurs distants.';
  static const String consentButtonAccept = 'Autoriser et scanner l\'appareil';
  static const String consentButtonRefuse = 'Plus tard';

  // Tableau de bord & Recherche
  static const String searchPlaceholder = 'Rechercher par nom ou package...';
  static const String filterSystemLabel = 'Apps système';
  static const String appsCountSingular = 'application trouvée';
  static const String appsCountPlural = 'applications trouvées';

  // Actions sur les cartes
  static const String actionLaunch = 'Lancer';
  static const String actionDetails = 'Paramètres';
  static const String actionRefresh = 'Actualiser';
  static const String actionRevokeConsent = 'Révoquer l\'autorisation';

  // Badges & Types
  static const String badgeSystem = 'SYSTÈME';
  static const String badgeUser = 'UTILISATEUR';
  static const String versionPrefix = 'v';
  static const String unknownVersion = 'Version inconnue';

  // Retours d'état & Erreurs
  static const String loadingMessage = 'Analyse de votre appareil en cours...';
  static const String emptyListTitle = 'Aucune application trouvée';
  static const String emptyListSubtitle =
      'Aucune application ne correspond à vos critères de recherche.';
  static const String errorTitle = 'Une erreur est survenue';
  static const String errorGeneric =
      'Impossible de récupérer la liste des applications. Veuillez réessayer.';
  static const String actionRetry = 'Réessayer';
  static const String appLaunchFailed = 'Impossible d\'ouvrir cette application.';
}
