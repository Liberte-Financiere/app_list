# apk_list

Application Flutter pour la gestion et l'affichage des fichiers APK, structurée selon une architecture orientée services (SOA / Service-Oriented Architecture).

## Prérequis

- **Flutter SDK** : `^3.41.0` (Dart `^3.11.0`)
- **JDK** : OpenJDK 21 (17 <= Java < 25 pour compatibilité Gradle 8.14)
- **Android SDK** : Plateforme Android 36 / Build-tools 36.1.0

## Architecture du projet

Le code source sous `lib/` est segmenté en couches indépendantes :

```
lib/
├── constants/             # Constantes globales et configuration applicative
│   └── app_constants.dart
├── models/                # Modèles métiers immuables avec validation stricte
│   └── apk_model.dart
├── services/              # Contrats abstraits et implémentations de services
│   ├── apk_service.dart
│   └── apk_service_impl.dart
├── dashboard/             # Couche présentation (Dashboard)
│   └── dashboard_screen.dart
└── main.dart              # Point d'entrée et injection des dépendances
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
