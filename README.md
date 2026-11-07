# apk_list

Application Flutter pour la gestion et l'affichage des fichiers APK.

## Prérequis

- **Flutter SDK** : `^3.41.0` (Dart `^3.11.0`)
- **JDK** : OpenJDK 21 (ou version 17 <= Java < 25 pour compatibilité Gradle 8.14)
- **Android SDK** : Plateforme Android 36 / Build-tools 36.1.0

## Configuration de l'environnement

Pour éviter les conflits d'incompatibilité entre Gradle 8.14 et le JDK 25 intégré par Android Studio :

```bash
flutter config --jdk-dir=/usr/lib/jvm/java-21-openjdk-amd64
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

## Structure du projet

- [lib/main.dart](lib/main.dart) : Point d'entrée de l'application.
- [test/widget_test.dart](test/widget_test.dart) : Tests unitaires et d'interface.
- [android/](android/) : Configuration et code natif Android.
