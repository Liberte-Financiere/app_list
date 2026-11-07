# apk_list

Application Flutter moderne pour répertorier, filtrer et lancer les applications installées sur l'appareil Android, avec architecture modulaire orientée services et design Material 3 soigné.

## Prérequis

- **Flutter SDK** : `^3.41.0` (Dart `^3.11.0`)
- **JDK** : OpenJDK 21 (17 <= Java < 25 pour compatibilité Gradle 8.14)
- **Android SDK** : Plateforme Android 36 / Build-tools 36.1.0

## Permissions & Réglementations Android

### 1. Déclaration Manifeste (`AndroidManifest.xml`)
Pour accéder à la liste complète des paquets sur Android 11+ (API 30+), la permission suivante est déclarée dans [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml) :
```xml
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" tools:ignore="QueryAllPackagesPermission" />
```

> [!NOTE]
> **Cas d'usage conforme Google Play :**
> L'inventaire, l'inspection et la gestion locale des applications installées par l'utilisateur constituent un cas d'usage valide et autorisé par Google pour la permission `QUERY_ALL_PACKAGES` (catégorie *App Management / Device Search*).

### 2. Consentement utilisateur (Prominent Disclosure)
La permission `QUERY_ALL_PACKAGES` étant déclarative au niveau de l'installation, un écran explicite de consentement ("Prominent Disclosure") a été implémenté conformément aux exigences RGPD / Google Play :
- L'utilisateur doit accepter explicitement l'accès avant tout scan des paquets.
- Le choix est persisté localement via `SharedPreferencesAsync`.
- L'autorisation peut être révoquée à tout moment depuis le menu du tableau de bord.

## Architecture Modulaire & Design System

```
lib/
├── constants/
│   ├── app_colors.dart          # Palette chromatique sémantique et thématique (clair/sombre)
│   ├── app_typography.dart      # Typographie hiérarchisée et standardisée
│   ├── app_strings.dart         # Centralisation des chaînes de caractères (i18n-ready)
│   ├── app_theme.dart           # Configuration globale Material 3
│   └── app_constants.dart       # Exporteur et constantes de routage
├── models/
│   └── apk_model.dart           # Modèle métier immuable avec validation stricte
├── services/
│   ├── apk_service.dart         # Contrat d'interface du service
│   └── apk_service_impl.dart    # Implémentation de production (I/O & cache)
├── dashboard/
│   ├── widgets/
│   │   ├── app_list_item.dart   # Carte d'application moderne avec badges et actions
│   │   ├── consent_view.dart    # Vue de consentement utilisateur structurée
│   │   ├── search_filter_bar.dart # Barre de recherche et filtres de paquets
│   │   └── status_view.dart     # Gestion unifiée des états (chargement, erreur, vide)
│   └── dashboard_screen.dart    # Orchestrateur du tableau de bord
└── main.dart                    # Point d'entrée avec injection et thèmes configurés
```

## Démarrage rapide

### Installation des dépendances
```bash
flutter pub get
```

### Analyse statique du code
```bash
flutter analyze
```

### Lancement des tests
```bash
flutter test
```

### Exécution de l'application
```bash
flutter run
```
