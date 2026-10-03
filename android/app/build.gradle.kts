import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load upload-key passwords from `android/key.properties` (which is
// gitignored). When the file is missing — e.g. on a fresh clone or
// CI without the secret — release builds gracefully fall back to the
// debug keys (see `signingConfigs.release` branch below). That keeps
// `flutter run --release` working locally for any teammate without
// the keystore, while a real Play upload only happens when the file
// is present.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
val hasReleaseSigningConfig = keystorePropertiesFile.exists()

// Load Flutter / SDK paths AND the Google Maps API key from
// `android/local.properties` (gitignored — never committed). The Maps
// key was previously hardcoded in AndroidManifest.xml; rotating it
// from git history is impossible, so the key in this file is the
// CURRENT production key that must be ROTATED in GCP and restricted
// to com.beestar.dlliny + the release SHA-1 fingerprint. After
// rotation, every dev machine + CI updates its local.properties.
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}
// "MISSING_MAPS_API_KEY" is a deliberate sentinel that makes
// map-tile requests fail with a recognisable error rather than
// silently using an empty key (which Google rejects opaquely).
val mapsApiKey = localProperties.getProperty("mapsApiKey", "MISSING_MAPS_API_KEY")

android {
    namespace = "com.example.hangout"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // `flutter_local_notifications` (and a handful of other
        // plugins that target newer Android APIs) require Java 8+
        // language features to be available on older runtimes via
        // core library desugaring. The dependencies block below
        // pulls in the desugar JDK shim that satisfies it.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.beestar.dlliny"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Inject the Maps API key into AndroidManifest's ${mapsApiKey}
        // placeholder. See the local.properties loader at the top of
        // this file for rotation details.
        manifestPlaceholders["mapsApiKey"] = mapsApiKey
    }

    signingConfigs {
        if (hasReleaseSigningConfig) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            // When the upload keystore is wired (CI / release machine
            // with `key.properties` present) we use it; otherwise fall
            // back to debug keys so `flutter run --release` stays
            // usable for teammates without the secret. Play will only
            // accept the real signing-config path — never upload an
            // AAB built without `key.properties`.
            signingConfig = if (hasReleaseSigningConfig) {
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
    // Pairs with `isCoreLibraryDesugaringEnabled = true` above —
    // ships a back-port of `java.time` and related APIs so
    // `flutter_local_notifications` can target newer Java features
    // on devices running older Android. Version pinned to the
    // current desugar release; bump alongside Android Gradle Plugin
    // upgrades.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
