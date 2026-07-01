import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val admobAppId = providers.gradleProperty("ADMOB_APP_ID").orNull
    ?: System.getenv("ADMOB_APP_ID")
    ?: "ca-app-pub-3940256099942544~3347511713"

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
} else {
    logger.warn("Release signing is not configured. Falling back to debug signing.")
}

android {
    namespace = "com.lingufranca.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Zoom Meeting SDK is built with newer bytecode; using Java 17 avoids desugaring edge-cases on AGP/D8.
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.lingufranca.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Zoom Meeting SDK (in-app video) requires Android API 26+ (v6.5.x).
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["admobAppId"] = admobAppId
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }

    packaging {
        jniLibs {
            pickFirsts += "**/libc++_shared.so"
        }
    }
}

gradle.taskGraph.whenReady {
    val releaseRequested = allTasks.any { it.name.contains("release", ignoreCase = true) }
    if (releaseRequested && !hasReleaseSigning) {
        throw GradleException("Release build requires mobile/android/key.properties and a release keystore.")
    }
    if (releaseRequested && admobAppId == "ca-app-pub-3940256099942544~3347511713") {
        throw GradleException("Release build requires ADMOB_APP_ID Gradle property or environment variable.")
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.browser:browser:1.7.0")
    // Zoom Meeting SDK (native in-app Zoom UI)
    implementation("us.zoom.meetingsdk:zoomsdk:6.5.10")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
