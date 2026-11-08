# apk_list

Application Flutter moderne pour répertorier, filtrer et inspecter les applications installées sur l'appareil Android (taille du package APK, dates d'installation et mise à jour, niveau SDK, chemin binaire), avec architecture modulaire orientée services et design Material 3 soigné.

## Fonctionnalités Clés

- **Inventaire complet des applications** : Détection des applications tierces et système.
- **Métadonnées techniques étendues** :
  - Taille réelle du binaire APK sur le stockage (`sizeInBytes` formaté en Ko/Mo/Go).
  - Date d'installation initiale (`firstInstallTime`) et date de dernière mise à jour (`lastUpdateTime`).
  - Niveau de SDK Android cible (`targetSdkVersion`) et chemin absolu du fichier APK (`sourceDir`).
  - Source d'installation identifiée (`installerPackageName` / `installerDisplayName`) : Google Play Store, Navigateur Phoenix, Sideload APK direct, Amazon Appstore, etc.
  - Audit des permissions du manifest : distinction précise entre permissions déclarées et permissions effectivement accordées (`grantedPermissions`).
- **Canal natif Android optimisé** : Extraction multithreadée via `MethodChannel` (`Executors.newFixedThreadPool`) pour éviter tout blocage du thread principal UI.
- **Récepteur d'événements système (`BroadcastReceiver`)** : Écoute passive et silencieuse de `PACKAGE_ADDED`, `PACKAGE_REMOVED` et `PACKAGE_REPLACED` avec rafraîchissement automatique en temps réel de l'inventaire sans surconsommation de batterie.
- **Page dédiée d'inspection détaillée (`AppDetailsScreen`)** : Vue plein écran ergonomique remplaçant les pop-ups/modales pour une lisibilité maximale de toutes les informations techniques (package avec copie en 1 clic, version, build, SDK Android cible, source du magasin, chemin binaire APK copiable, dates d'installation et de mise à jour, taille exacte en octets) ainsi qu'un audit interactif des permissions système avec filtrage réactif (Toutes / Accordées / Refusées), recherche textuelle et accès direct aux paramètres Android.
- **Attribution atomique des utilisateurs & Modèles d'appareils** :
  - Identification automatique de chaque terminal connecté (`User 1`, `User 2`, etc.) via séquence PostgreSQL `SERIAL` dans `registered_devices`.
  - Détection native du fabricant et modèle (`Build.MANUFACTURER`, `Build.MODEL`, `Build.VERSION.RELEASE`).
- **Consentement utilisateur & Personnalisation du profil** :
  - Parcours d'onboarding immersif en 2 étapes : consentement RGPD / Google Play puis saisie d'un pseudonyme / nom d'utilisateur personnalisé.
  - Persistance locale dans `SharedPreferences` : dès la validation initiale, les lancements ultérieurs ouvrent directement le tableau de bord sans ré-afficher l'onboarding.
  - Attribution personnalisée sur la base Neon (`user_label`).
- **Navigation Material 3 épurée & Dock flottant** :
  - Barre de navigation inférieure flottante moderne avec ombre douce, bordure subtile et retours haptiques séparant l'onglet **Accueil** (inventaire, recherche, filtres) et l'onglet **Profil** (caractéristiques de l'appareil, synchronisation Neon, gestion de la confidentialité).
  - Préservation d'état fluide (`IndexedStack`) entre les onglets.
  - En-tête (`AppBar`) à couleur constante sans altération de teinte lors du défilement (`surfaceTintColor: transparent`).

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
│   ├── apk_model.dart           # Modèle métier des applications scannées
│   ├── device_model.dart        # Modèle représentant la table Neon 'registered_devices'
│   └── inventory_item_model.dart # Modèle représentant la table Neon 'device_inventory'
├── services/
│   ├── apk_service.dart         # Contrat d'interface du service d'applications
│   ├── apk_service_impl.dart    # Implémentation Android native (I/O & cache)
│   ├── neon_connection_manager.dart # Gestionnaire de connexion TLS/SSL Neon
│   ├── device_service.dart      # Service dédié à la table 'registered_devices' (User X)
│   ├── inventory_service.dart   # Service dédié à la table 'device_inventory' (UPSERT batch)
│   └── neon_sync_service.dart   # Orchestrateur de synchronisation Neon
├── dashboard/
│   ├── widgets/
│   │   ├── app_list_item.dart   # Carte d'application moderne avec badges et actions
│   │   ├── onboarding_view.dart # Parcours d'accueil animé (Consentement & Profil utilisateur)
│   │   ├── neon_status_banner.dart # Bannière réactive de confirmation backend (preuve d'envoi)
│   │   ├── search_filter_bar.dart # Barre de recherche et filtres de paquets
│   │   └── status_view.dart     # Gestion unifiée des états (chargement, erreur, vide)
│   ├── app_details_screen.dart  # Écran dédié pleine page des détails et permissions de l'application
│   └── dashboard_screen.dart    # Orchestrateur du tableau de bord épuré
├── profile/
│   └── profile_screen.dart      # Écran dédié au profil, informations terminal et confidentialité
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
4. La synchronisation vers la table `device_inventory` de Neon s'effectue automatiquement en arrière-plan à chaque ouverture ou actualisation de l'inventaire, sans aucun bouton manuel ni blocage de l'interface.

### Génération & Installation de l'APK (Release avec .env)

#### 1. Compiler le package APK
```bash
flutter build apk --dart-define-from-file=.env
```
Le fichier binaire généré est situé dans :
`build/app/outputs/flutter-apk/app-release.apk`

#### 2. Installer directement sur smartphone Android (via USB / ADB)
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```
