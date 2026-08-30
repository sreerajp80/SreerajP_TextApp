# Change Log: Dynamic Build Metadata Generation & About Screen Build Date

**Plan:** [plans/20260829_050800_dynamic_build_metadata.md](plans/20260829_050800_dynamic_build_metadata.md)

## Summary of Changes

### 1. Build Metadata Generator Scripts
- **`tool/generate_app_version.dart`**: Reads the version from `pubspec.yaml`, writes `lib/core/constants/app_version.g.dart` (`kAppVersion`), and prints `app_version.g.dart updated → <version>`.
- **`tool/generate_build_date.dart`**: Gets the current date in ISO-8601 format (`YYYY-MM-DD`), writes `lib/core/constants/build_date.g.dart` (`kBuildDate`), and prints `build_date.g.dart updated → <date>`.
- **`tool/refresh_build_metadata.ps1`**: Helper script to manually run both generators.

### 2. Gradle Integration
- **`android/app/build.gradle.kts`**: Added the `generateBuildMetadata` Gradle task that executes the generator scripts. Connected this task to `preBuild` and `compileFlutterBuild*` so that running `flutter build apk`, `flutter build appbundle`, or `flutter run` automatically runs the generators and outputs the updated version and build date.

### 3. Localization & About Screen
- **`lib/l10n/app_en.arb`**: Added `aboutBuildDateLabel` ("Build date").
- **`lib/l10n/app_ml.arb`**: Added `aboutBuildDateLabel` ("ബിൽഡ് തീയതി").
- **`lib/shell/settings/sections/about_section.dart`**: Added a `ListTile` showing `l10n.aboutBuildDateLabel` with `kBuildDate`.

### 4. Tests
- **`test/shell/settings/about_section_test.dart`**: Updated test to assert that `kBuildDate` is displayed.

## Verification
- Ran generator scripts (`tool/generate_app_version.dart`, `tool/generate_build_date.dart`).
- Ran `flutter gen-l10n`.
- Ran Gradle task `generateBuildMetadata` (`BUILD SUCCESSFUL`).
- Ran `dart format lib test tool`.
- Ran `flutter analyze` (0 issues found).
- Ran `flutter test` (all 1177 tests passed).
