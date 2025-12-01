import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("keystore.properties")
val localPropertiesFile = rootProject.file("local.properties")

// Initialize a new Properties() object called keystoreProperties.
val keystoreProperties = Properties()
val localProperties = Properties()

// Load your keystore.properties file into the keystoreProperties object.
keystoreProperties.load(FileInputStream(keystorePropertiesFile))
// Load local.properties file into the localProperties object.
localProperties.load(FileInputStream(localPropertiesFile))

android {
    namespace = "com.hosle.woodlandscheckpoint"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.hosle.woodlandscheckpoint"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Inject AdMob App ID from local.properties
        manifestPlaceholders["admobAppId"] = localProperties.getProperty("admob.appId") ?: ""
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("release")
        }

        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // Customize output file names to include version name
    applicationVariants.all {
        val variantName = name
        val versionNameValue = defaultConfig.versionName
        
        outputs.all {
            val output = this as com.android.build.gradle.internal.api.BaseVariantOutputImpl
            // This renames APK files
            output.outputFileName = if (buildType.name == "release") {
                "app-release-${versionNameValue}.apk"
            } else {
                "app-${buildType.name}-${versionNameValue}.apk"
            }
        }
        
        // Rename AAB files after bundle task completes
        tasks.named("bundle${variantName.capitalize()}").configure {
            doLast {
                val bundleFile = File("${buildDir}/outputs/bundle/${variantName}/app-${variantName}.aab")
                val newBundleFile = File("${buildDir}/outputs/bundle/${variantName}/app-${variantName}-${versionNameValue}.aab")
                if (bundleFile.exists() && !newBundleFile.exists()) {
                    bundleFile.renameTo(newBundleFile)
                    println("Renamed AAB to: ${newBundleFile.name}")
                }
            }
        }
    }
}

flutter {
    source = "../.."
}
