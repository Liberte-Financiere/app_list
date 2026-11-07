# apk_list

Application Flutter pour répertorier, filtrer et lancer les applications installées sur l'appareil Android, avec gestion du consentement utilisateur et architecture orientée services.

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

## Architecture

```
lib/
├── constants/
│   └── app_constants.dart       # Titres, clés de persistance et textes de consentement
├── models/
│   └── apk_model.dart           # Modèle immuable (icône, package, version, date d'installation)
├── services/
│   ├── apk_service.dart         # Contrat abstrait (consentement, listing, lancement)
│   └── apk_service_impl.dart    # Implémentation via 'installed_apps' et 'shared_preferences'
├── dashboard/
│   └── dashboard_screen.dart    # Vue de consentement, recherche, filtrage système et liste
└── main.dart                    # Point d'entrée avec injection du service
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
