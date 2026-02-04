import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")

if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

android {
    namespace = "com.alphalabs.connectify"
    compileSdk = project.property("flutter.compileSdkVersion").toString().toInt()
    ndkVersion = project.property("flutter.ndkVersion").toString()

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.alphalabs.connectify"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = project.property("flutter.minSdkVersion").toString().toInt()
        targetSdk = project.property("flutter.targetSdkVersion").toString().toInt()
        versionCode = project.property("flutter.versionCode").toString().toInt()
        versionName = project.property("flutter.versionName").toString()
        manifestPlaceholders.putAll(
            mapOf(
                "KAKAO_APP_KEY_TEST" to
                    (keyProperties["KAKAO_APP_KEY_TEST"] as String? ?: ""),
                "KAKAO_APP_KEY" to
                    (keyProperties["KAKAO_APP_KEY"] as String? ?: "")
            )
        )
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
