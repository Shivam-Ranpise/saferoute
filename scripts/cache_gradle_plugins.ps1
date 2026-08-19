$ErrorActionPreference = "Stop"

function Cache-GradleArtifact {
    param(
        [string]$group,
        [string]$name,
        [string]$version,
        [string]$filename,
        [string]$url
    )

    $groupPath = $group.Replace('.', '\')
    $baseCache = "$env:USERPROFILE\.gradle\caches\modules-2\files-2.1\$groupPath\$name\$version"
    $tempFile = "$env:TEMP\$filename"

    Write-Host "Downloading $filename from Maven Central..."
    Invoke-WebRequest -Uri $url -OutFile $tempFile -UseBasicParsing

    $sha1 = (Get-FileHash -Path $tempFile -Algorithm SHA1).Hash.ToLower()
    $destDir = "$baseCache\$sha1"
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    $destFile = "$destDir\$filename"
    Copy-Item -Path $tempFile -Destination $destFile -Force
    Write-Host "  ✅ Cached at: $destFile (SHA1: $sha1)"
}

$artifacts = @(
    @{
        group = "org.jetbrains.kotlin"
        name = "kotlin-gradle-plugin"
        version = "2.2.20"
        filename = "kotlin-gradle-plugin-2.2.20-gradle88.jar"
        url = "https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-gradle-plugin/2.2.20/kotlin-gradle-plugin-2.2.20-gradle88.jar"
    },
    @{
        group = "org.jetbrains.kotlin"
        name = "kotlin-gradle-plugin-api"
        version = "2.2.20"
        filename = "kotlin-gradle-plugin-api-2.2.20.jar"
        url = "https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-gradle-plugin-api/2.2.20/kotlin-gradle-plugin-api-2.2.20.jar"
    },
    @{
        group = "org.jetbrains.kotlin"
        name = "kotlin-gradle-plugin-idea-proto"
        version = "2.2.20"
        filename = "kotlin-gradle-plugin-idea-proto-2.2.20.jar"
        url = "https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-gradle-plugin-idea-proto/2.2.20/kotlin-gradle-plugin-idea-proto-2.2.20.jar"
    },
    @{
        group = "org.jetbrains.kotlin"
        name = "kotlin-native-utils"
        version = "2.2.20"
        filename = "kotlin-native-utils-2.2.20.jar"
        url = "https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-native-utils/2.2.20/kotlin-native-utils-2.2.20.jar"
    },
    @{
        group = "org.jetbrains.kotlinx"
        name = "kotlinx-coroutines-core-jvm"
        version = "1.8.0"
        filename = "kotlinx-coroutines-core-jvm-1.8.0.jar"
        url = "https://repo1.maven.org/maven2/org/jetbrains/kotlinx/kotlinx-coroutines-core-jvm/1.8.0/kotlinx-coroutines-core-jvm-1.8.0.jar"
    },
    @{
        group = "org.jetbrains.kotlin"
        name = "fus-statistics-gradle-plugin"
        version = "2.2.20"
        filename = "fus-statistics-gradle-plugin-2.2.20-gradle88.jar"
        url = "https://repo1.maven.org/maven2/org/jetbrains/kotlin/fus-statistics-gradle-plugin/2.2.20/fus-statistics-gradle-plugin-2.2.20-gradle88.jar"
    },
    @{
        group = "org.jetbrains.kotlin"
        name = "kotlin-util-klib"
        version = "2.2.20"
        filename = "kotlin-util-klib-2.2.20.jar"
        url = "https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-util-klib/2.2.20/kotlin-util-klib-2.2.20.jar"
    },
    @{
        group = "com.google.code.gson"
        name = "gson"
        version = "2.11.0"
        filename = "gson-2.11.0.jar"
        url = "https://repo1.maven.org/maven2/com/google/code/gson/gson/2.11.0/gson-2.11.0.jar"
    }
)

foreach ($item in $artifacts) {
    Cache-GradleArtifact -group $item.group -name $item.name -version $item.version -filename $item.filename -url $item.url
}
Write-Host "🎉 All Gradle plugin artifacts pre-cached successfully!"
