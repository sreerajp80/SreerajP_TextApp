import java.io.File
import java.io.FileInputStream
import java.time.LocalDate
import java.util.Properties
import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing config, loaded from a gitignored android/key.properties.
// The file (and the keystore it points to) are secrets and are NEVER committed.
// If the file is absent (a normal dev machine or CI without the secret), we fall
// back to debug signing so the project still builds. See docs/release-signing.md.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    FileInputStream(localPropertiesFile).use(localProperties::load)
}

val flutterSdkPath = localProperties.getProperty("flutter.sdk")
    ?: System.getenv("FLUTTER_ROOT")
    ?: throw GradleException(
        "Flutter SDK path not found. Set flutter.sdk in android\\local.properties or FLUTTER_ROOT."
    )

val isWindowsHost = System.getProperty("os.name").startsWith("Windows", ignoreCase = true)
val dartExecutable = File(
    flutterSdkPath,
    if (isWindowsHost) "bin\\dart.bat" else "bin/dart",
)
val projectRootDir = rootProject.projectDir.parentFile

val generateBuildMetadata = tasks.register("generateBuildMetadata") {
    group = "build setup"
    description = "Generates About-screen build metadata before Android builds."

    inputs.file(projectRootDir.resolve("pubspec.yaml"))
    inputs.file(projectRootDir.resolve("tool/generate_app_version.dart"))
    inputs.file(projectRootDir.resolve("tool/generate_build_date.dart"))
    inputs.property("metadataBuildDate", LocalDate.now().toString())
    outputs.file(projectRootDir.resolve("lib/core/constants/app_version.g.dart"))
    outputs.file(projectRootDir.resolve("lib/core/constants/build_date.g.dart"))

    doLast {
        if (!dartExecutable.exists()) {
            throw GradleException(
                "Could not find Dart executable at ${dartExecutable.absolutePath}. " +
                    "Check android\\local.properties flutter.sdk or FLUTTER_ROOT."
            )
        }

        project.exec {
            workingDir = projectRootDir
            commandLine(dartExecutable.absolutePath, "run", "tool/generate_app_version.dart")
        }
        project.exec {
            workingDir = projectRootDir
            commandLine(dartExecutable.absolutePath, "run", "tool/generate_build_date.dart")
        }
    }
}

tasks.named("preBuild") {
    dependsOn(generateBuildMetadata)
}

tasks.matching { task ->
    task.name.startsWith("compileFlutterBuild")
}.configureEach {
    dependsOn(generateBuildMetadata)
}

android {
    namespace = "in.sreerajp.textapp"
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
        // Published application ID. Independent of `namespace` above (which drives
        // the generated R/BuildConfig package and the Kotlin source package).
        applicationId = "in.sreerajp.TextAPP"
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // minSdk 26 (Android 8.0) — project requirement (CLAUDE.md §2).
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "environment"
    productFlavors {
        create("prod") {
            dimension = "environment"
            // Keep the published production application ID from defaultConfig.
        }
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }
    }

    signingConfigs {
        // Only define the release signing config when the secret properties file
        // is present. `storeFile` is resolved relative to the android/ folder.
        if (hasReleaseSigning) {
            create("release") {
                storeFile = keystoreProperties["storeFile"]?.let { rootProject.file(it) }
                storePassword = keystoreProperties["storePassword"] as String?
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            // Use the real release key when key.properties is present, otherwise
            // fall back to debug signing so the project still builds without the
            // secret. See docs/release-signing.md.
            signingConfig = if (hasReleaseSigning) {
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
