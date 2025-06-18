plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    // id("com.google.gms.google-services") // Comentado para configuración futura de Firebase
}

android {
    namespace = "com.example.invoice_d"
    compileSdk = 35

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    sourceSets {
        getByName("main") {
            java {
                srcDirs("src\\main\\kotlin")
            }
        }
    }

    defaultConfig {
        applicationId = "com.example.invoice_d"
        minSdk = 23
        targetSdk = 34
        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName
        ndkVersion = "27.0.12077973" // Added NDK version here
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
