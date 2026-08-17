# Guidelines conformance audit and fixes

**Status:** completed

This plan records a full check of the project against the shared guidelines in
`docs/guidelines/`, and the fixes proposed for the gaps found.

Guidelines checked:

- `docs/guidelines/guideline.md` (folder structure, About config, keystore)
- `docs/guidelines/flutter_project_engineering_standard.md` (the master rulebook)
- `docs/guidelines/DOCS_FOLDER_GUIDELINE.md` (the `docs/` folder)
- `docs/guidelines/CLAUDE_MD_GUIDELINE.md` and `docs/guidelines/AGENTS_MD_GUIDELINE.md`

Profile in force: `Core Baseline` + `Production App Extension` + `Sensitive Data Extension`.

---

## 1. What already passes

No action needed for any of these.

| Check | Result |
|---|---|
| `flutter analyze` | 0 issues |
| `flutter test` | passes |
| `dart format lib test` | 506 files, 0 changed |
| About config pattern (`guideline.md` §1) | `assets/config/app_config.json`, `lib/core/config/app_config.dart` (`fallback` + `fromJson`), `lib/core/config/config_service.dart` (`assetPath`, `load()`, `loadAndVerify()`, injectable loader) — all exactly as required |
| About screen is data driven | `about_section.dart` loops `c.details.entries` |
| `app_config.json` version vs `pubspec.yaml` | both `1.9.0` / `21` — in sync |
| `l10n.yaml` + `lib/l10n/app_en.arb` + `app_ml.arb` | present |
| Root `CLAUDE.md` and `AGENTS.md` | present, Thin profile, section order matches the guideline, workflow + simple-English rules inline |
| Baseline `docs/` set (DOCS_FOLDER_GUIDELINE §6) | all 8 documents present |
| `docs/` cross-links | every document referenced by `CLAUDE.md` exists |
| Keystore rules (`guideline.md` §2) | `android/key.properties` and `*.jks` are git-ignored; nothing secret is tracked |
| Never-commit rules (standard §20.2) | no `build/`, `coverage/`, `.dart_tool/`, `*.iml`, keystore or `key.properties` tracked |
| `test/` mirrors `lib/` (standard §3.2) | yes, folder for folder |
| Structure tier | Tier 2 feature-first, consistent; `core/config/` at the fixed path |
| CI | `.github/workflows/ci.yml` present |

---

## 2. Issues found

### Issue 1 — Hard-coded user-visible text (MUST violation)

`guideline.md` §3 and standard §8.2 / §22.2 say **all** user-visible text must come from
`AppLocalizations`. About 48 raw strings are still written straight into widgets.

| File | Raw `Text('...')` count |
|---|---|
| `lib/sync/ui/sync_client_screen.dart` | 8 |
| `lib/sync/ui/live_diff_screen.dart` | 7 |
| `lib/core/vault/ui/vault_lock_dialog.dart` | 5 |
| `lib/sync/ui/widgets/text_diff_view.dart` | 3 |
| `lib/sync/ui/p2p_live_diff_tab.dart` | 3 |
| `lib/sync/ui/p2p_file_transfer_tab.dart` | 3 |
| `lib/sync/ui/widgets/csv_diff_view.dart` | 2 |
| `lib/sync/diff/diff_dialog_helper.dart` | 2 |
| `lib/formats/txt/txt_toolbar.dart` | 2 |
| `lib/formats/markdown/md_toolbar.dart` | 2 |
| `lib/formats/csv/csv_toolbar.dart` | 1 |
| `lib/formats/json/json_toolbar.dart` | 1 |
| `lib/formats/xml/xml_toolbar.dart` | 1 |
| `lib/shell/settings/sections/about_section.dart` | 1 |

Plus 7 raw `tooltip:` / `hintText:` / `labelText:` values in
`lib/core/editor/column_selection_sheet.dart`, `lib/formats/csv/csv_formula_sheet.dart`
and `lib/sync/ui/live_diff_screen.dart`.

**Fix:** add the missing keys (with `@key` descriptions) to `lib/l10n/app_en.arb` and
`lib/l10n/app_ml.arb`, regenerate, and replace every raw string with the localized
lookup. Strings that are pure data (`'=A*B'` as a formula example) stay as they are.

### Issue 2 — Local machine paths in `plans/` and `change_log/` (MUST violation)

Standard §21.1.1 forbids absolute local paths in these folders. Six files carry
`file:///` links that reveal the drive letter and folder of the machine they were
written on.

Files to fix:

- `plans/20260716_073000_add-guidelines-submodule.md`
- `plans/20260716_073540_vertical-pinch.md`
- `plans/20260716_074435_fix-pinch-scroll.md`
- `plans/20260813_183000_update_feature_analysis_roadmap.md`
- `change_log/20260716_073100_add-guidelines-submodule.md`
- `change_log/20260813_183000_update_feature_analysis_roadmap.md`

**Fix:** rewrite each link to a relative repository path (for example
`[CLAUDE.md](../CLAUDE.md)`). Only the link targets change; the wording stays.

Note: the IP-like strings in the two privacy-shield files
(`plans/20260815_123500_offline_privacy_shield_pii_scrubber.md`,
`change_log/20260815_143100_offline_privacy_shield_pii_scrubber.md`) are made-up
examples of scrubber output, not real addresses. No change needed.

### Issue 3 — No logging service (standard §14)

The standard asks for one named logger with a fixed level set (`trace` … `fatal`) and a
written sensitive-data policy. The project has none: there is no `lib/core/logging/`,
and no `AppLogger`. The only `debugPrint` is the one from the reference `ConfigService`,
which is allowed.

This is the largest piece of work in the plan and it touches security-sensitive code
(the rule "never log secrets" must be honoured).

**Fix:** add `lib/core/logging/app_logger.dart` with the level set from §14.1, output
gated on the build flavor, no file output for now (so no rotation work and no new
dependency beyond `logger`), and a short "what must never be logged" comment. Wire
`AppLogger.init()` into the `main()` sequence. Document it as a new section in
`docs/architecture.md`. **No existing code is rewritten to use it in this change** —
that would be a large, risky sweep; it is called out as follow-up work.

### Issue 4 — README does not match how the app is built (standard §21.3)

`README.md` shows `flutter run` and `flutter build apk --release`. This project defines
flavors, so both commands **fail**. `CLAUDE.md` §5 already says so. The README also
misses two items §21.3 requires.

**Fix in `README.md`:**

- use `flutter run --flavor dev` and the real flavored release commands
- add a prerequisites line (Flutter 3.44.8+, Dart 3.12.2+, Android SDK, minSdk 26)
- say that the project uses no code generation (`build_runner`), so that item is closed
- add a short "adding a database migration" pointer to `docs/architecture.md`
- add `docs/project_structure.md`, `docs/dependencies.md` and `docs/workflow-rules.md`
  to the project-docs list

### Issue 5 — Stale version numbers in the rule files

`CLAUDE.md` §5 and `AGENTS.md` both show
`--split-debug-info=build/symbols/android-prod-1.6.8/` while `pubspec.yaml` is at
`1.9.0+21`. Both files also tell the reader to keep that folder in step with
`pubspec.yaml`, so they contradict themselves. `docs/features.md` line 304 still says
"TextData v1.6.8+15".

**Fix:** update all four places to `1.9.0` / `1.9.0+21`.

### Issue 6 — `analysis_options.yaml` and `.gitignore` are missing a few entries

- `analysis_options.yaml` follows standard §16.1 but leaves out two rules from the
  recommended baseline: `avoid_print` and `avoid_redundant_argument_values`.
- `.gitignore` misses `*.symbols/` (§20.2 — debug symbol archives) and
  `.flutter-plugins` (§20.4).

**Fix:** add the two lints and the two ignore lines. `avoid_redundant_argument_values`
may report existing issues; if it does, they will be fixed in the same change so
`flutter analyze` stays at zero.

### Issue 7 — `docs/` naming and doc catalog (DOCS_FOLDER_GUIDELINE §3, §7)

- `docs/TextData-Idea.md` is neither `snake_case` nor the catalog name. The catalog
  name for this type is `<app>_idea.md` → `textdata_idea.md`.
- `docs/features.md` and `docs/feature_analysis_and_roadmap.md` are not recognized
  types. §8 says feature material belongs as sections in existing docs.

**Fix:** rename `docs/TextData-Idea.md` to `docs/textdata_idea.md` with `git mv`, and
update the links in `CLAUDE.md`, `AGENTS.md`, `README.md` and any doc that points at
it. Leave `features.md` and `feature_analysis_and_roadmap.md` where they are, but add a
one-line note in each saying which living document owns the topic — merging them is a
bigger editorial job and is listed as follow-up.

The kebab-case names already in `docs/` (`security-rules.md`, `release-signing.md`,
`workflow-rules.md`, `implementation-plan.md`, `implementation-progress.md`,
`security-audit-phase13.md`) are **left alone** — §3 says older kebab names are
tolerated and must not be renamed for style alone.

### Issue 8 — `fonts/` sits at the repository root

Standard §3.3 puts fonts at `assets/fonts/`. The project has a top-level `fonts/`
folder.

**Fix:** none in this change. Moving it touches `pubspec.yaml` font paths and the
bundled licence files for no functional gain. Recorded here as a known, accepted
deviation and noted in `docs/project_structure.md`.

### Issue 9 — File size (standard §16.2, `CLAUDE.md` §9)

Fifteen files in `lib/` are over 500 lines; the rule is "split it or justify the size in
the change log". Largest: `lib/formats/csv/csv_document_session.dart` (1012),
`lib/core/editor/column_selection_sheet.dart` (936),
`lib/formats/json/json_document_session.dart` (817).

**Fix:** none in this change — splitting them is a refactor with real regression risk
and is out of scope for a conformance pass. The change log will record the full list as
a justified, tracked deviation.

### Issue 10 — `docs/guidelines` submodule pointer is uncommitted

`git submodule status` shows `+2b381be`: the checked-out guidelines commit is newer than
the one recorded in the parent repository. The submodule working tree itself is clean,
so nothing inside it was edited from this project.

**Fix:** none by me — this only needs the pointer committed. Flagged for you to commit.

---

## 3. Files to be changed

| File | Change |
|---|---|
| `lib/l10n/app_en.arb` | add ~48 new keys + `@key` descriptions |
| `lib/l10n/app_ml.arb` | add the same keys, Malayalam text |
| `lib/sync/ui/sync_client_screen.dart` | use `AppLocalizations` |
| `lib/sync/ui/live_diff_screen.dart` | use `AppLocalizations` (incl. tooltips) |
| `lib/sync/ui/p2p_file_transfer_tab.dart` | use `AppLocalizations` |
| `lib/sync/ui/p2p_live_diff_tab.dart` | use `AppLocalizations` |
| `lib/sync/ui/widgets/text_diff_view.dart` | use `AppLocalizations` |
| `lib/sync/ui/widgets/csv_diff_view.dart` | use `AppLocalizations` |
| `lib/sync/diff/diff_dialog_helper.dart` | use `AppLocalizations` |
| `lib/core/vault/ui/vault_lock_dialog.dart` | use `AppLocalizations` |
| `lib/core/editor/column_selection_sheet.dart` | localize label + hint |
| `lib/formats/csv/csv_toolbar.dart` | use `AppLocalizations` |
| `lib/formats/json/json_toolbar.dart` | use `AppLocalizations` |
| `lib/formats/markdown/md_toolbar.dart` | use `AppLocalizations` |
| `lib/formats/txt/txt_toolbar.dart` | use `AppLocalizations` |
| `lib/formats/xml/xml_toolbar.dart` | use `AppLocalizations` |
| `lib/shell/settings/sections/about_section.dart` | use `AppLocalizations` |
| `lib/core/logging/app_logger.dart` | **new** — logger service |
| `lib/main.dart` | call `AppLogger.init()` in the startup sequence |
| `pubspec.yaml` | add `logger` dependency |
| `analysis_options.yaml` | add `avoid_print`, `avoid_redundant_argument_values` |
| `.gitignore` | add `*.symbols/`, `.flutter-plugins` |
| `README.md` | flavored commands, prerequisites, tests, migrations, doc links |
| `CLAUDE.md` | version `1.6.8` → `1.9.0`; idea-doc link rename |
| `AGENTS.md` | same two edits |
| `docs/features.md` | version line; owning-document note |
| `docs/feature_analysis_and_roadmap.md` | owning-document note |
| `docs/TextData-Idea.md` → `docs/textdata_idea.md` | `git mv` rename |
| `docs/architecture.md` | new section: logging service and startup order |
| `docs/project_structure.md` | note the accepted `fonts/` deviation; rename link |
| `plans/…` ×4, `change_log/…` ×2 | replace `file:///` links with relative paths |
| `test/core/logging/app_logger_test.dart` | **new** — level and no-secret checks |
| `test/l10n/…` | extend the existing ARB parity test if one exists |

## 4. Order of work

1. Privacy fix in `plans/` and `change_log/` (fastest, pure text).
2. Version and link fixes in `CLAUDE.md`, `AGENTS.md`, `README.md`, `docs/features.md`.
3. Doc rename + `docs/` notes.
4. `.gitignore` and `analysis_options.yaml`, then fix any new analyzer findings.
5. Localization sweep (largest step) + regenerate `AppLocalizations`.
6. Logging service + `main.dart` wiring + `docs/architecture.md` section + test.
7. Run `dart format lib test`, `flutter analyze`, `flutter test`.
8. Write the change log.

## 5. Follow-up work not in this plan

- Move existing diagnostics onto `AppLogger` across `lib/`.
- Split the 15 files over 500 lines.
- Fold `features.md` and `feature_analysis_and_roadmap.md` into the living documents.
- Move `fonts/` under `assets/fonts/`.
- Commit the `docs/guidelines` submodule pointer.

---

**Do you approve this plan?**
