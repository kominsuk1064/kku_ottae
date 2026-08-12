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
val releaseSigningEnvironmentVariables = mapOf(
    "storeFile" to "ANDROID_RELEASE_STORE_FILE",
    "storePassword" to "ANDROID_RELEASE_STORE_PASSWORD",
    "keyAlias" to "ANDROID_RELEASE_KEY_ALIAS",
    "keyPassword" to "ANDROID_RELEASE_KEY_PASSWORD",
)
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
val releaseSigningValues = requiredReleaseSigningProperties.associateWith { propertyName ->
    System.getenv(releaseSigningEnvironmentVariables.getValue(propertyName))
        ?.takeIf { it.isNotBlank() }
        ?: releaseSigningProperties.getProperty(propertyName)?.takeIf { it.isNotBlank() }
}
val missingReleaseSigningProperties = requiredReleaseSigningProperties.filter { propertyName ->
    releaseSigningValues[propertyName] == null
}
val placeholderReleaseSigningProperties = requiredReleaseSigningProperties.filter { propertyName ->
    releaseSigningValues[propertyName] == "CHANGE_ME"
}
val releaseStoreFile = releaseSigningValues["storeFile"]?.let { rootProject.file(it) }
val hasReleaseSigningConfig =
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
        missingReleaseSigningProperties.isNotEmpty() -> androidConfigurationErrors +=
            "Release signing is missing: ${missingReleaseSigningProperties.joinToString()}. " +
            "Configure android/key.properties or ANDROID_RELEASE_* environment variables."
        placeholderReleaseSigningProperties.isNotEmpty() -> androidConfigurationErrors +=
            "Release signing still contains placeholders: " +
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
                keyAlias = releaseSigningValues["keyAlias"]
                keyPassword = releaseSigningValues["keyPassword"]
                storeFile = checkNotNull(releaseStoreFile)
                storePassword = releaseSigningValues["storePassword"]
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
