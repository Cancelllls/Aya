import java.util.Properties
import java.net.URI
import java.nio.file.FileSystems
import java.nio.file.Files
import java.nio.file.FileSystem
import java.nio.file.Path

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android Gradle plugin.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties for release signing
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.quran.aya"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }


    defaultConfig {
        applicationId = "com.quran.aya"
        minSdk = flutter.minSdkVersion // Android 5.0
        targetSdk = 36 // Android 16
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "distribution"
    productFlavors {
        create("fdroid") {
            dimension = "distribution"
            applicationId = "com.quran.aya"
        }
        create("play") {
            dimension = "distribution"
            applicationId = "com.quran.aya"
        }
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = if (keystorePropertiesFile.exists())
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
        }
    }

    dependenciesInfo {
        includeInApk = false
        includeInBundle = false
    }

    configurations.configureEach {
        if (name.contains("fdroid", ignoreCase = true)) {
            exclude(group = "com.google.android.gms")
            exclude(group = "com.google.android.play")
            exclude(group = "com.google.android.play.core")
        }
    }
}

tasks.matching { it.name.contains("dex", ignoreCase = true) || it.name.contains("assemble", ignoreCase = true) || it.name.contains("minify", ignoreCase = true) || it.name.contains("compile", ignoreCase = true) }.configureEach {
    doFirst {
        fileTree(File(System.getProperty("user.home"), ".gradle/caches")) {
            include("**/*flutter_embedding*.jar")
        }.forEach { jarFile: File ->
            try {
                val uri = URI.create("jar:" + jarFile.toURI().toString())
                val env = mutableMapOf<String, String>()
                val zipFs = FileSystems.newFileSystem(uri, env)
                try {
                    listOf(
                        "/io/flutter/embedding/android/FlutterPlayStoreSplitApplication.class",
                        "/io/flutter/embedding/engine/deferredcomponents/PlayStoreDeferredComponentManager.class",
                        "/io/flutter/embedding/engine/deferredcomponents/PlayStoreDeferredComponentManager\$FeatureInstallStateUpdatedListener.class",
                        "/io/flutter/embedding/engine/deferredcomponents/PlayStoreDeferredComponentManager\$1.class"
                    ).forEach { pathStr ->
                        val p = zipFs.getPath(pathStr)
                        if (Files.exists(p)) {
                            Files.delete(p)
                        }
                    }
                } finally {
                    zipFs.close()
                }
            } catch (e: Exception) {}
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.media:media:1.7.0")
}
