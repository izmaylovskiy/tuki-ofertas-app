import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.tuki.ofertas"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
        }
    }

    defaultConfig {
        applicationId = "com.tuki.ofertas"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
    	create("release") {
            val storeFileName = keystoreProperties["storeFile"]?.toString()
            ?: throw GradleException("storeFile missing in key.properties")

            storeFile = rootProject.file(storeFileName)

            storePassword = keystoreProperties["storePassword"]?.toString()
            ?: throw GradleException("storePassword missing in key.properties")

            keyAlias = keystoreProperties["keyAlias"]?.toString()
            ?: throw GradleException("keyAlias missing in key.properties")

            keyPassword = keystoreProperties["keyPassword"]?.toString()
            ?: throw GradleException("keyPassword missing in key.properties")
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}
