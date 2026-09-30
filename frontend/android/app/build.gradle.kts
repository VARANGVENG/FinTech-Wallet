import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Loaded from android/key.properties (gitignored) if present. Falls back to
// debug signing below when it's absent, so `flutter run --release` and CI
// keep working without a local keystore (NOV-25).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.fintech.wallet"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications requires this (it uses java.time APIs
        // not natively available below API 26).
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.fintech.wallet"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Deliberately 24, not flutter.minSdkVersion (NOV-35) - this happens
        // to be Flutter's own current default too, but hardcoding it means a
        // future Flutter upgrade can't silently lower this app's real floor.
        // 24 is a hard requirement of local_auth_android and
        // flutter_local_notifications (both declare minSdkVersion 24 in
        // their own build.gradle) - going lower would fail to build once
        // either plugin's native code is actually compiled in, not just at
        // Dart-analysis time. Google Play has no minSdkVersion policy floor
        // of its own to satisfy here - its review requirement is about
        // targetSdk, which already tracks "latest stable" via
        // flutter.targetSdkVersion below.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
