pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") version("4.3.15") apply false
    // END: FlutterFire Configuration
    // NOTE: Kept on explicit KGP (NOT migrated to Flutter's Built-in
    // Kotlin). Built-in Kotlin currently ships a Kotlin version that the
    // app's plugins (package_info_plus 9.0.0, etc.) can't compile against
    // — removing this line makes those plugins fail with "Unresolved
    // reference 'HashMap'/'put'". Re-attempt the migration only after
    // those plugins ship Built-in-Kotlin-compatible releases.
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
