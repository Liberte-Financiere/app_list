plugins {
    id("com.android.application")
    id("kotlin-android")
    // Le plugin Gradle Flutter doit être appliqué après les plugins Android et Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.apk_list"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Spécifier un identifiant d'application unique (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.apk_list"
        // Valeurs configurables selon les besoins du projet.
        // Voir documentation : https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Ajouter la configuration de signature pour la version de production.
            // Signature avec les clés de debug par défaut pour permettre le fonctionnement de `flutter run --release`.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
