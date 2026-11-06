# Builds the release APK on Windows and copies it to dist\PocketHangar-<version>.apk.
#
#   .\scripts\build_apk.ps1                  APK without an EVE client ID (sign-in shows a hint)
#   .\scripts\build_apk.ps1 -ClientId <id>   with the client ID of your developers.eveonline.com app
#
# Uses the JDK configured for Flutter (Android Studio's jbr). When a local proxy listens on port
# 7897, Gradle sends Maven traffic through it and reaches Google's repository directly.
# Release signing: android\key.properties (see README); without it the debug key is used.
param(
    [string]$ClientId = $env:EVE_CLIENT_ID,
    [string]$Flutter = $(if (Get-Command flutter -ErrorAction SilentlyContinue) { 'flutter' } else { "$env:USERPROFILE\tools\flutter\bin\flutter.bat" })
)

$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'

if (Get-NetTCPConnection -LocalPort 7897 -State Listen -ErrorAction SilentlyContinue) {
    $env:GRADLE_OPTS = '-Dhttps.proxyHost=127.0.0.1 -Dhttps.proxyPort=7897 -Dhttp.proxyHost=127.0.0.1 ' +
        '-Dhttp.proxyPort=7897 -Dhttp.nonProxyHosts=*.google.com ' +
        '-Dorg.gradle.internal.repository.max.retries=10 -Dorg.gradle.internal.repository.initial.backoff=1000'
    Write-Host 'Gradle uses the proxy on 127.0.0.1:7897 (Google repository direct).'
}

$buildArgs = @('build', 'apk', '--release')
if ($ClientId) { $buildArgs += "--dart-define=EVE_CLIENT_ID=$ClientId" }
# Flutter and Gradle print warnings on stderr. Under 'Stop', PowerShell 5.1 turns the first one
# into a terminating error when output is redirected, so judge the build by its exit code.
$ErrorActionPreference = 'Continue'
& $Flutter @buildArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$version = ((Select-String -Path 'pubspec.yaml' -Pattern '^version:\s*([^+\s]+)').Matches[0].Groups[1].Value)
New-Item -ItemType Directory -Force 'dist' | Out-Null
$out = "dist\PocketHangar-$version.apk"
Copy-Item 'build\app\outputs\flutter-apk\app-release.apk' $out -Force
Write-Host "APK -> $out"
