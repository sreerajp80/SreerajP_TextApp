# Guidelines conformance — align project structure and coding standards

**Status:** partial_completion

Groups 1, 2, and 3 are done. Group 4 (the constants folder) was optional in this plan and
was not implemented. Change log: `change_log/20260813_193929_guidelines-conformance.md`.

This plan lists the gaps found when checking the project against the shared guidelines in
`docs/guidelines/` (the Git submodule), and how to close them.

Documents checked:

- `docs/guidelines/guideline.md` (folder structure, About config, keystore)
- `docs/guidelines/flutter_project_engineering_standard.md` (§3 structure, §16 coding, §19 CI, §20 git)
- `docs/guidelines/CLAUDE_MD_GUIDELINE.md`
- `docs/guidelines/AGENTS_MD_GUIDELINE.md`
- `docs/guidelines/DOCS_FOLDER_GUIDELINE.md`

---

## 1. What already passes (no work needed)

| Check | Result |
| --- | --- |
| `lib/core/config/app_config.dart` — `AppConfig` with `fromJson` + `fallback` | Pass |
| `lib/core/config/config_service.dart` — `ConfigService` with `assetPath`, `load()`, `loadAndVerify()`, injectable loader | Pass |
| `assets/config/app_config.json` has `appName`, `description`, `version`, `build`, `details` | Pass |
| `version`/`build` in the JSON match `pubspec.yaml` (1.6.8 + 15) | Pass |
| `assets/config/` registered under `flutter: assets:` | Pass |
| About screen loops `config.details.entries`, no hard-coded field names | Pass |
| Keystore at `android/textapp-keystore.jks`, `android/key.properties` present | Pass |
| `.gitignore` covers `*.jks`, `*.keystore`, `**/key.properties` | Pass |
| `flutter analyze` — 0 issues | Pass |
| `dart format` — 0 files changed | Pass |
| `main.dart` is thin (19 lines) | Pass |
| `test/` mirrors `lib/` (114 test files) | Pass |
| No `print(`, no stray `TODO` in `lib/` | Pass |
| Android flavors `dev` / `prod` defined | Pass |
| `pubspec.lock` committed; `flutter_lints` major pinned (`^6.0.0`) | Pass |
| `docs/GUIDELINES_MANIFEST.md` + `docs/guidelines/` submodule wired | Pass |

---

## 2. Gaps found

### Gap A — `AGENTS.md` is missing (MUST)

`AGENTS_MD_GUIDELINE.md` §3 and `guideline.md` §3 both say every Flutter project MUST have a
root `AGENTS.md`. The project has none. The empty folders `.agents/` and `.codex/` exist but
hold no file.

### Gap B — `CLAUDE.md` is missing required sections (MUST)

`CLAUDE_MD_GUIDELINE.md` §3 marks these sections "Always". The current `CLAUDE.md` does not
have them, and its section order does not match §2.

Missing:

1. Project identity table (app name, platform, minSdk 26 / targetSdk, package id
   `in.sreerajp.TextAPP`, Flutter/Dart SDK, state management Riverpod, navigation, database
   sqflite, orientation, connectivity stance).
2. "Read these docs before working" table (Thin profile requirement). The present §5 is a
   folder listing, not a doc-reference table.
3. Build & run commands.
4. Build flavors table (the app has `dev` and `prod`, so a bare `flutter run` fails).
5. Signing / keystore section.
6. Architecture rules section (layers, boundaries, dependency direction).
7. Code style / naming section.
8. Dependency constraints (block list for an offline app).
9. Dos & Don'ts.
10. The workflow section does not carry the "relative repository paths only, no sensitive
    data" clause that both guidelines require inline.

### Gap C — Imports are all relative (coding standard)

`lib/` has 887 relative imports and 0 `package:text_data/...` imports. Both
`CLAUDE_MD_GUIDELINE.md` §4 ("Use `package:` imports, not relative") and the engineering
standard §16.1 (`always_use_package_imports: true`) require package imports.

### Gap D — `analysis_options.yaml` has no stricter rules

The engineering standard §16.1 gives a recommended baseline list to add on top of
`flutter_lints`. None of it is present. The most useful missing rules for this project:
`always_use_package_imports`, `prefer_single_quotes`, `prefer_const_constructors`,
`prefer_const_declarations`, `prefer_final_locals`, `cancel_subscriptions`, `close_sinks`,
`use_key_in_widget_constructors`, `sort_child_properties_last`.

### Gap E — `docs/` baseline set is incomplete

`DOCS_FOLDER_GUIDELINE.md` §6 lists 8 baseline documents. Two are missing:

- `dependencies.md` — approved packages and the prohibited-dependency list.
- `project_structure.md` — the project file tree and folder responsibilities.

The other six exist under older kebab-case names (`security-rules.md`, `release-signing.md`,
`workflow-rules.md`, `implementation-plan.md`, `implementation-progress.md`) plus
`architecture.md`. §3 says kebab-case legacy names are tolerated and MUST NOT be renamed just
for style, so **no renaming is planned**. New files use `snake_case`.

### Gap F — No CI workflow

The engineering standard §19.1 says active app repositories SHOULD have CI running
`flutter pub get`, `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test`.
There is no `.github/workflows/` folder.

### Gap G — No `lib/core/constants/`

`guideline.md` §1 (closing note) says technical constants (preference keys, thresholds,
channel IDs) belong in a plain Dart file such as `lib/core/constants/app_constants.dart`.
That folder does not exist; such values are spread across feature files.

### Gap H — Six source files are over 500 lines

Engineering standard §16.2 says "around 500 lines: split or justify". Generated l10n files are
excluded. The files are:

| File | Lines |
| --- | --- |
| `lib/formats/csv/csv_document_session.dart` | 956 |
| `lib/formats/json/json_document_session.dart` | 764 |
| `lib/formats/json/json_parser.dart` | 661 |
| `lib/formats/markdown/md_document_session.dart` | 631 |
| `lib/formats/xml/xml_document_session.dart` | 623 |
| `lib/formats/txt/txt_document_session.dart` | 510 |

This is guidance, not a hard failure.

---

## 3. Plan for the fix

Work is grouped so each group can be approved or dropped on its own.

### Group 1 — Documentation (no code risk)

Files to create:

- `AGENTS.md` (project root) — Thin profile, following the `AGENTS_MD_GUIDELINE.md` template,
  with all "Always" sections and the inline workflow + simple-English rules.
- `docs/dependencies.md` — current packages grouped by concern, plus the blocked list
  (HTTP clients, cloud/BaaS, analytics, crash reporting, ads, commercial SDKs such as
  Syncfusion).
- `docs/project_structure.md` — the `lib/` and root file tree with one line per folder.

Files to change:

- `CLAUDE.md` — rewrite in the canonical §2 section order, adding the nine missing sections
  from Gap B. Keep the existing hard rules, security link, and workflow/communication text;
  do not duplicate `docs/` content (Thin profile). `AGENTS.md` will mirror it exactly.
- `docs/GUIDELINES_MANIFEST.md` — refresh from the submodule copy so it matches the current
  master (the local copy is an older, shorter version).

### Group 2 — Lint rules and package imports (mechanical code change)

Files to change:

- `analysis_options.yaml` — add the §16.1 baseline rule list.
- All 259 files under `lib/` and 114 under `test/` — convert relative imports to
  `package:text_data/...`. This is a mechanical rewrite driven by a throwaway script, then
  verified with `dart format .`, `flutter analyze` (must stay at 0 issues), and `flutter test`.

Order: enable the lint rules first, let the analyzer list every offending import, fix, then
re-run analyze until clean. If any newly enabled rule produces a large amount of unrelated
noise, that single rule is dropped and the reason is recorded in the change log.

### Group 3 — CI

Files to create:

- `.github/workflows/ci.yml` — pub get, format check, analyze, test on push and pull request.

### Group 4 — Constants folder (optional, ask before doing)

Files to create:

- `lib/core/constants/app_constants.dart` — values only, no logic.

This means moving existing scattered constants, which touches working code. It is listed last
and is **not** included unless explicitly approved.

### Not planned

- **No renaming** of the existing kebab-case `docs/` files — the guideline forbids renaming
  for style alone.
- **No splitting** of the six large files (Gap H). These are format session classes with a
  single clear responsibility. Splitting them is a separate, risk-bearing refactor and should
  be its own plan if wanted.

---

## 4. How the result is verified

- `dart format --output=none --set-exit-if-changed .` passes.
- `flutter analyze` reports 0 issues.
- `flutter test` passes (all 114 test files).
- Re-check each row of the checklists in `guideline.md` §4,
  `CLAUDE_MD_GUIDELINE.md` §8, `AGENTS_MD_GUIDELINE.md` §9, and
  `DOCS_FOLDER_GUIDELINE.md` §10.

---

## 5. Files touched (summary)

Create:

- `AGENTS.md`
- `docs/dependencies.md`
- `docs/project_structure.md`
- `.github/workflows/ci.yml`
- `lib/core/constants/app_constants.dart` (Group 4 only, if approved)

Change:

- `CLAUDE.md`
- `docs/GUIDELINES_MANIFEST.md`
- `analysis_options.yaml`
- every `.dart` file under `lib/` and `test/` (import lines only)
