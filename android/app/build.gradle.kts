import java.io.StringReader
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firma de release: los datos del keystore viven en android/key.properties (fuera de git).
// Se quita un posible BOM porque con él la primera clave no se encuentra y la firma falla
// con un NullPointerException poco claro.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    val text = keystorePropertiesFile.readText(Charsets.UTF_8).removePrefix("﻿")
    keystoreProperties.load(StringReader(text))
}

fun keystoreProperty(name: String): String =
    keystoreProperties.getProperty(name)?.trim()?.takeIf { it.isNotEmpty() }
        ?: throw GradleException("android/key.properties: falta el valor '$name'.")

android {
    namespace = "com.videcreaciones.laundry_manager"
    compileSdk = flutter.compileSdkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.videcreaciones.laundry_manager"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                val keystoreFile = file(keystoreProperty("storeFile"))
                if (!keystoreFile.exists()) {
                    throw GradleException("No se encuentra el keystore: ${keystoreFile.path}")
                }
                storeFile = keystoreFile
                storePassword = keystoreProperty("storePassword")
                keyAlias = keystoreProperty("keyAlias")
                keyPassword = keystoreProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Nunca se firma el release con la clave de debug: Play lo rechazaría.
            signingConfig = signingConfigs.findByName("release")
        }
    }
}

// Sin key.properties el release saldría sin firmar; mejor fallar con un mensaje claro.
gradle.taskGraph.whenReady {
    val buildsRelease = allTasks.any { it.project == project && it.name.contains("Release") }
    if (buildsRelease && !keystorePropertiesFile.exists()) {
        throw GradleException(
            "Falta android/key.properties: el build de release necesita el keystore para firmarse."
        )
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
