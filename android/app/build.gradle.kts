plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val googleServicesFile = file("google-services.json")
val requestedAndroidBuildTasks = gradle.startParameter.taskNames.filter { taskName ->
    taskName.contains("assemble", ignoreCase = true) ||
        taskName.contains("bundle", ignoreCase = true)
}
val requiresFirebaseConfig = requestedAndroidBuildTasks.any { taskName ->
    !taskName.contains("debug", ignoreCase = true)
}

when {
    googleServicesFile.isFile -> apply(plugin = "com.google.gms.google-services")
    requiresFirebaseConfig -> throw GradleException(
        "android/app/google-services.json is required for non-debug Android builds.",
    )
    else -> logger.lifecycle(
        "google-services.json is missing; Firebase resources are skipped for this debug build.",
    )
}

android {
    namespace = "com.example.ottae_fixed"
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
        applicationId = "com.example.ottae_fixed"
        minSdk = flutter.minSdkVersion.toInt()
        targetSdk = flutter.targetSdkVersion.toInt()
        versionCode = flutter.versionCode?.toInt() ?: 1
        versionName = flutter.versionName
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

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:32.3.1"))
    implementation("com.google.firebase:firebase-auth")
}
