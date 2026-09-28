import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Google identifies an Android app by its package name *plus the SHA-1 of the
// certificate it was signed with*, so social sign-in only works for signing
// keys that are registered in the Firebase console. Signing releases with the
// debug key would make that fingerprint differ on every build machine, so the
// release key is read from `android/key.properties` (git-ignored):
//
//   storeFile=vyzi-release.jks   # relative to android/, or an absolute path
//   storePassword=...
//   keyAlias=...
//   keyPassword=...
//
// Without that file the release build falls back to the debug key so that
// `flutter run --release` keeps working locally.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.vyzi"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.vyzi"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // R8 strips unreachable JVM bytecode and unused Android resources.
            // It never opens libapp.so, so no Dart code is affected -- the
            // exposure is third-party SDKs that resolve classes reflectively.
            // Those keep rules live in proguard-rules.pro; read the header
            // there before changing anything here.
            //
            // Measured on the arm64 --split-per-abi release, clean builds of
            // identical source:
            //
            //           APK bytes    dex bytes   dex classes
            //   R8 on  36,629,945   14,356,756        14,643
            //   R8 off 41,757,362   28,328,692        25,985
            //
            // Compare clean builds only. An incremental build after flipping
            // these flags reports a dex far smaller than it really is, which
            // is easy to mistake for R8 having made things worse. Always
            // `flutter clean` before trusting a number from here.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )

            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                // Fallback: the debug key. `flutter run --release` works, but
                // Google Sign-In only does if that debug SHA-1 is registered.
                logger.warn(
                    "android/key.properties not found — signing the release " +
                        "build with the debug key. Google Sign-In will fail " +
                        "unless the debug SHA-1 is registered in Firebase.",
                )
                signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
