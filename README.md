# apk_list

Application Flutter moderne pour répertorier, filtrer et inspecter les applications installées sur l'appareil Android (taille du package APK, dates d'installation et mise à jour, niveau SDK, chemin binaire), avec architecture modulaire orientée services et design Material 3 soigné.

## Fonctionnalités Clés

- **Inventaire complet des applications** : Détection des applications tierces et système.
- **Métadonnées techniques étendues** :
  - Taille réelle du binaire APK sur le stockage (`sizeInBytes` formaté en Ko/Mo/Go).
  - Date d'installation initiale (`firstInstallTime`) et date de dernière mise à jour (`lastUpdateTime`).
  - Niveau de SDK Android cible (`targetSdkVersion`) et chemin absolu du fichier APK (`sourceDir`).
- **Canal natif Android optimisé** : Extraction multithreadée via `MethodChannel` (`Executors.newFixedThreadPool`) pour éviter tout blocage du thread principal UI.
- **Fiche modale d'inspection** : Affichage détaillé par application avec actions rapides (lancement, accès aux paramètres système).
- **Consentement utilisateur (Prominent Disclosure)** : Gestion conforme aux règles Google Play et RGPD pour `QUERY_ALL_PACKAGES`.

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
│   ├── apk_service_impl.dart    # Implémentation de production (I/O & cache)
│   └── neon_sync_service.dart   # Synchronisation sécurisée Neon PostgreSQL (TLS/SSL)
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

#### Mode standard
```bash
flutter run
```

#### Mode synchronisation Neon (Usage personnel)
1. Dupliquez [.env.example](.env.example) en `.env` :
   ```bash
   cp .env.example .env
   ```
2. Renseignez vos identifiants Neon dans `.env` (hôte, utilisateur, mot de passe). Le fichier `.env` est strictement ignoré par Git.
3. Lancez l'application avec injection sécurisée des variables d'environnement :
   ```bash
   flutter run --dart-define-from-file=.env
   ```
4. Cliquez sur l'icône de synchronisation nuage dans la barre supérieure de l'application pour synchroniser la liste d'applications vers la table `device_inventory` de Neon.
