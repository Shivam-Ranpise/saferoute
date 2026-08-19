$ErrorActionPreference = "SilentlyContinue"

$cacheBase = "$env:USERPROFILE\.gradle\caches\modules-2\files-2.1\org.jetbrains.kotlin"

$artifacts = @(
    @{
        Group = "org.jetbrains.kotlin"
        Name = "kotlin-gradle-plugin"
        Version = "2.2.20"
        Classifier = "-gradle88"
        Ext = "jar"
        Url = "https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-gradle-plugin/2.2.20/kotlin-gradle-plugin-2.2.20-gradle88.jar"
    },
    @{
        Group = "org.jetbrains.kotlin"
        Name = "kotlin-gradle-plugin-api"
        Version = "2.2.20"
        Ext = "jar"
        Url = "https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-gradle-plugin-api/2.2.20/kotlin-gradle-plugin-api-2.2.20.jar"
    },
    @{
        Group = "org.jetbrains.kotlin"
        Name = "kotlin-gradle-plugin-idea-proto"
        Version = "2.2.20"
        Ext = "jar"
        Url = "https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-gradle-plugin-idea-proto/2.2.20/kotlin-gradle-plugin-idea-proto-2.2.20.jar"
    },
    @{
        Group = "org.jetbrains.kotlin"
        Name = "kotlin-native-utils"
        Version = "2.2.20"
        Ext = "jar"
        Url = "https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-native-utils/2.2.20/kotlin-native-utils-2.2.20.jar"
    },
    @{
        Group = "org.jetbrains.kotlinx"
        Name = "kotlinx-coroutines-core-jvm"
        Version = "1.8.0"
        Ext = "jar"
        Url = "https://repo1.maven.org/maven2/org/jetbrains/kotlinx/kotlinx-coroutines-core-jvm/1.8.0/kotlinx-coroutines-core-jvm-1.8.0.jar"
    }
)

Write-Host "Pre-fetching Gradle dependencies via Maven Central CDN..."
foreach ($art in $artifacts) {
    Write-Host "Downloading $($art.Name)-$($art.Version)..."
    $dest = "$env:TEMP\$($art.Name)-$($art.Version)$($art.Classifier).$($art.Ext)"
    Invoke-WebRequest -Uri $art.Url -OutFile $dest -UseBasicParsing
    Write-Host "  -> Saved: $dest"
}
Write-Host "Completed pre-fetch!"
