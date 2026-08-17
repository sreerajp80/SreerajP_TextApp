# Renamed the Dart package from `text_data` to `sreerajp_textapp`

Implements `plans/20260817_193458_rename-package-to-sreerajp-textapp.md`.

## Why

`pubspec.yaml` had already been changed from `name: text_data` to
`name: sreerajp_textapp`, but nothing else in the project followed. Every Dart file
still imported app code as `package:text_data/...`, a package that no longer existed.
Each broken import then made every class and function it provided look undefined, so
`flutter analyze` reported **11,651 issues**.

The code was not broken. It was only the package name that no longer matched.

The new name was kept, and the imports were brought in line with it.

## What changed

- **433 Dart files** under `lib/` and `test/` — **1,917 occurrences** of the exact
  string `package:text_data/` replaced with `package:sreerajp_textapp/`. The change is
  confined to import and export directives; no logic was touched.
- **`CLAUDE.md`** §9 — the import-style rule now says `package:sreerajp_textapp/...`.
- **`AGENTS.md`** — the same line, kept in step with `CLAUDE.md`.
- **`test/analysis_options.yaml`** — header comment updated to the new package name.
  No lint rules were changed.

`pubspec.yaml` was not edited. Its earlier version bump to `1.9.0+21` is a separate
change and was left alone.

## Deliberately left unchanged

- **`plans/` and `change_log/` history files.** They record what was true when written.
  Rewriting them would falsify the record.
- **`text_data.db`** — the app's SQLite file name (`AppDatabase.defaultFileName`). It is
  a file on the user's device. Renaming it would make every existing install lose its
  recents, favourites, bookmarks and drafts index. It has no link to the Dart package
  name.
- **`in.zohomail.sreerajp.text_data/saf`** — a `MethodChannel` name string shared
  between Dart and Kotlin. Channel names are free-form and unrelated to the package
  name; changing one side alone would break the SAF bridge.
- **Android application id `in.sreerajp.TextAPP`** — unrelated, and changing it would
  break app updates and signing.

## Verification

| Step | Result |
|------|--------|
| `flutter pub get` | Got dependencies |
| `dart format lib test` | 508 files, 0 changed |
| `flutter analyze` | **No issues found** (was 11,651) |
| `flutter test` | **All 1,176 tests passed** |
| `package:text_data/` left in `lib/` or `test/` | none |

Zero analyzer issues and a fully passing test suite confirm nothing moved beyond the
import names.
