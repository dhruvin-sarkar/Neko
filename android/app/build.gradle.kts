plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.neko"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.neko"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // live_activities' RemoteViews notifications need API 24+; never drop
        // below whatever Flutter/other plugins already require.
        minSdk = maxOf(24, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Intentionally debug-signed: the hackathon build is side-loaded by
            // judges, not distributed through Play, so nothing trusts this
            // signature for anything privileged. A production release would wire
            // in a dedicated upload keystore here (and register its SHA-1 in the
            // Firebase console for Google Sign-In).
            signingConfig = signingConfigs.getByName("debug")
            // R8: shrink + obfuscate release code so the shipped APK doesn't
            // carry readable symbols (SonarQube security finding).
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

// Single source of truth for every native dependency version in this file.
val firebaseMessagingVersion = "23.4.1"
val kotlinStdlibVersion = "2.2.20"
val playServicesAuthVersion = "21.0.0"
val coroutinesPlayServicesVersion = "1.7.3"

// live_activities pins firebase-messaging:24.0.0, which drags firebase-common up
// to 21.0.0 and duplicates com.google.firebase.Timestamp against this project's
// firebase-firestore 24.11.0 (Firebase BoM 32.8.0). Pin messaging back to the
// BoM's 23.4.1 so firebase-common stays 20.4.3 and the Firebase set stays aligned.
configurations.all {
    resolutionStrategy {
        force("com.google.firebase:firebase-messaging:$firebaseMessagingVersion")
        // SCA (Aikido): older plugin toolchains can drag in a 1.x kotlin-stdlib
        // with known deserialization CVEs. Force the app-wide stdlib to the
        // project's own Kotlin version so no vulnerable stdlib ships.
        force("org.jetbrains.kotlin:kotlin-stdlib:$kotlinStdlibVersion")
    }
}

dependencies {
    // Google Sign-In (not managed by Flutter plugins)
    implementation("com.google.android.gms:play-services-auth:$playServicesAuthVersion")

    // Kotlin Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:$coroutinesPlayServicesVersion")
}

flutter {
    source = "../.."
}
