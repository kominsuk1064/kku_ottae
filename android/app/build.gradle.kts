import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val googleServicesFile = file("google-services.json")
val releaseSigningPropertiesFile = rootProject.file("key.properties")
val releaseSigningProperties = Properties().apply {
    if (releaseSigningPropertiesFile.isFile) {
        releaseSigningPropertiesFile.inputStream().use { load(it) }
    }
}
val requestedAndroidBuildTasks = gradle.startParameter.taskNames.filter { taskName ->
    taskName.contains("assemble", ignoreCase = true) ||
        taskName.contains("bundle", ignoreCase = true)
}
val requiresFirebaseConfig = requestedAndroidBuildTasks.any { taskName ->
    !taskName.contains("debug", ignoreCase = true)
}
val requiresReleaseSigning = requestedAndroidBuildTasks.any { taskName ->
    taskName.contains("release", ignoreCase = true)
}
val requiredReleaseSigningProperties = listOf(
    "storeFile",
    "storePassword",
    "keyAlias",
    "keyPassword",
)
val missingReleaseSigningProperties = if (releaseSigningPropertiesFile.isFile) {
    requiredReleaseSigningProperties.filter { propertyName ->
        releaseSigningProperties.getProperty(propertyName).isNullOrBlank()
    }
} else {
    requiredReleaseSigningProperties
}
val placeholderReleaseSigningProperties = requiredReleaseSigningProperties.filter { propertyName ->
    releaseSigningProperties.getProperty(propertyName) == "CHANGE_ME"
}
val releaseStoreFile = releaseSigningProperties.getProperty("storeFile")
    ?.takeIf { it.isNotBlank() }
    ?.let { rootProject.file(it) }
val hasReleaseSigningConfig =
    releaseSigningPropertiesFile.isFile &&
        missingReleaseSigningProperties.isEmpty() &&
        placeholderReleaseSigningProperties.isEmpty() &&
        releaseStoreFile?.isFile == true
val androidConfigurationErrors = mutableListOf<String>()

if (requiresFirebaseConfig && !googleServicesFile.isFile) {
    androidConfigurationErrors +=
        "android/app/google-services.json is required for profile and release builds."
}
if (requiresReleaseSigning) {
    when {
        !releaseSigningPropertiesFile.isFile -> androidConfigurationErrors +=
            "android/key.properties is required for release signing."
        missingReleaseSigningProperties.isNotEmpty() -> androidConfigurationErrors +=
            "android/key.properties is missing: ${missingReleaseSigningProperties.joinToString()}."
        placeholderReleaseSigningProperties.isNotEmpty() -> androidConfigurationErrors +=
            "android/key.properties still contains placeholders: " +
            "${placeholderReleaseSigningProperties.joinToString()}."
        releaseStoreFile?.isFile != true -> androidConfigurationErrors +=
            "The release keystore configured by storeFile does not exist."
    }
}

if (androidConfigurationErrors.isNotEmpty()) {
    throw GradleException(
        "Android build configuration is incomplete:\n" +
            androidConfigurationErrors.joinToString(separator = "\n") { "- $it" },
    )
}

if (googleServicesFile.isFile) {
    apply(plugin = "com.google.gms.google-services")
} else {
    logger.lifecycle(
        "google-services.json is missing; Firebase resources are skipped for this debug build.",
    )
}

android {
    namespace = "com.kominsuk1064.kkuottae"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.kominsuk1064.kkuottae"
        minSdk = flutter.minSdkVersion.toInt()
        targetSdk = flutter.targetSdkVersion.toInt()
        versionCode = flutter.versionCode?.toInt() ?: 1
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigningConfig) {
            create("release") {
                keyAlias = releaseSigningProperties.getProperty("keyAlias")
                keyPassword = releaseSigningProperties.getProperty("keyPassword")
                storeFile = checkNotNull(releaseStoreFile)
                storePassword = releaseSigningProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:32.3.1"))
    implementation("com.google.firebase:firebase-auth")
}
