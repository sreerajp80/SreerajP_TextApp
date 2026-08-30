$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $repoRoot

$localPropertiesPath = Join-Path $repoRoot 'android\local.properties'
$flutterSdkPath = $null

if (Test-Path $localPropertiesPath) {
    $flutterSdkLine = Select-String -Path $localPropertiesPath -Pattern '^flutter\.sdk=(.+)$' | Select-Object -First 1
    if ($flutterSdkLine) {
        $flutterSdkPath = $flutterSdkLine.Matches[0].Groups[1].Value.Trim() -replace '\\\\', '\'
    }
}

if (-not $flutterSdkPath) {
    $flutterSdkPath = $env:FLUTTER_ROOT
}

$dartCommand = 'dart'
if ($flutterSdkPath) {
    $dartCommand = Join-Path $flutterSdkPath 'bin\dart.bat'
    if (-not (Test-Path $dartCommand)) {
        throw "Could not find Dart executable at $dartCommand. Check android\local.properties or FLUTTER_ROOT."
    }
}

& $dartCommand run tool\generate_app_version.dart
& $dartCommand run tool\generate_build_date.dart
