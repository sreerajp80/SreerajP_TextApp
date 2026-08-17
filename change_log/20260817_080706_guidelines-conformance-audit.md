# Guidelines conformance audit and fixes

**Plan:** [plans/20260817_074458_guidelines-conformance-audit.md](../plans/20260817_074458_guidelines-conformance-audit.md)

Checked the whole project against the shared guidelines in `docs/guidelines/` and fixed
the gaps found. Ten issues were recorded in the plan; seven are now fixed, three were
deliberately recorded as accepted deviations instead.

---

## 1. Verification after the change

| Check | Result |
|---|---|
| `flutter analyze` | 0 issues |
| `flutter test` | 1176 tests, all pass (was 1169 — 7 new logger tests) |
| `dart format lib test` | clean |
| ARB parity | 1035 keys in `app_en.arb` and `app_ml.arb`, every English key has an `@description` |

---

## 2. Localization — hard-coded text removed (MUST fix)

The rule is that every user-visible string comes from `AppLocalizations`. About 48 raw
strings were still written into widgets.

- Added **37 new keys** to `lib/l10n/app_en.arb` and `lib/l10n/app_ml.arb`, each with an
  `@description`, and regenerated `AppLocalizations`.
- Ten of the strings already had ARB keys that were never wired up
  (`liveDiffAction`, `vaultLockAction`, `liveDiffAcceptMine`, and similar) — those now use
  the existing key rather than a new one.

Files rewired:

`lib/core/vault/ui/vault_lock_dialog.dart` · `lib/shell/settings/sections/about_section.dart` ·
`lib/core/editor/column_selection_sheet.dart` · `lib/sync/diff/diff_dialog_helper.dart` ·
`lib/sync/ui/live_diff_screen.dart` · `lib/sync/ui/p2p_file_transfer_tab.dart` ·
`lib/sync/ui/p2p_live_diff_tab.dart` · `lib/sync/ui/sync_client_screen.dart` ·
`lib/sync/ui/widgets/csv_diff_view.dart` · `lib/sync/ui/widgets/text_diff_view.dart` ·
`lib/formats/csv/csv_toolbar.dart` · `lib/formats/json/json_toolbar.dart` ·
`lib/formats/markdown/md_toolbar.dart` · `lib/formats/txt/txt_toolbar.dart` ·
`lib/formats/xml/xml_toolbar.dart`

The biometric prompt reason in the vault dialog was localized too — it is shown to the
user by the system, so it counts as user-visible text.

Left as literals on purpose: the MIME type shown as data on the live-diff tab, and the
CSV formula example `=A*B`. Both are data, not UI copy.

## 3. Privacy rule for `plans/` and `change_log/` (MUST fix)

Standard §21.1.1 forbids local machine paths in these folders because the files are
committed and may become public. **Eleven** absolute paths were found across nine files
and all are now relative or reworded:

- `file:///...` links → relative paths (`../CLAUDE.md`, `../lib/...`) in
  `plans/20260716_073000_add-guidelines-submodule.md`,
  `plans/20260716_073540_vertical-pinch.md`,
  `plans/20260716_074435_fix-pinch-scroll.md`,
  `plans/20260813_183000_update_feature_analysis_roadmap.md`,
  `change_log/20260716_073100_add-guidelines-submodule.md`,
  `change_log/20260813_183000_update_feature_analysis_roadmap.md`.
- Drive-letter paths → repository-relative paths in
  `plans/20260709_134541_split-claude-md-rules.md` and
  `plans/20260709_135151_phased-implementation-docs.md`.
- Paths pointing outside this repository → reworded, with no path, in
  `plans/20260718_203210_fix-pinch-zoom-listener.md`,
  `plans/20260813_183000_update_feature_analysis_roadmap.md` and
  `change_log/20260813_183000_update_feature_analysis_roadmap.md`.

The IP-like strings in the privacy-shield plan and log were checked and left alone — they
are invented examples of scrubber output, not real addresses.

## 4. Logging service (new)

`lib/core/logging/app_logger.dart` — the app had no logger at all, which standard §14
requires.

- Levels `trace` · `debug` · `info` · `warning` · `error` · `fatal`, exactly the set in §14.1.
- `AppLogger.init()` is called from `main()` before `runApp`. The `dev` flavor logs from
  `trace` up; every other build logs from `info` up, so `trace` and `debug` are silent in
  production. If `init()` is never called the logger stays at `info`, so a missed call
  cannot switch on verbose logging in a release.
- The "what must never be logged" rule is written on the class itself and in
  `docs/architecture.md` §16.
- New test `test/core/logging/app_logger_test.dart` (7 tests) covers the level gate per
  flavor, the safe default before `init`, and that a suppressed line produces no output.
- `test/security/logging_audit_test.dart` — the existing whole-app guard that fails on any
  unreviewed logging call — now has a reviewed allow-list entry for the logger's own
  `developer.log` line, with the reason written next to it.

**Not done on purpose:** existing code was not moved onto `AppLogger`. That sweep touches
security-sensitive files and is listed as follow-up. `docs/architecture.md` §16.4 says so
plainly rather than implying the codebase already uses it.

## 5. README (standard §21.3)

`README.md` told the reader to run `flutter run` and `flutter build apk --release`. This
project defines flavors, so **both of those commands fail**. Fixed, and the missing §21.3
items added:

- prerequisites (Flutter 3.44.8+, Dart 3.12.2+, Android SDK, API 26+),
- clean-clone steps including `git submodule update --init --recursive`,
- flavored run, test, analyze and format commands,
- the real flavored release build commands,
- a note that the project uses no code generation, so there is no `build_runner` step,
- how to add a database migration,
- the full `docs/` list, which was missing four documents.

## 6. Stale versions

`pubspec.yaml` is at `1.9.0+21`, but three files still said `1.6.8`:

- `CLAUDE.md` §5 and `AGENTS.md` — the `--split-debug-info` folder was
  `android-prod-1.6.8`, which contradicted the line in the same section telling the reader
  to keep it in step with `pubspec.yaml`. Now `android-prod-1.9.0`.
- `docs/features.md` — "TextData v1.6.8+15" → "TextData v1.9.0+21".

## 7. `analysis_options.yaml` and `.gitignore`

- Added `avoid_print`. It reports zero issues.
- Added `*.symbols/` and `.flutter-plugins` to `.gitignore` (standard §20.2 and §20.4).

## 8. `docs/` naming and ownership

- `docs/TextData-Idea.md` → **`docs/textdata_idea.md`** (`git mv`), matching the
  `<app>_idea.md` catalogue name and the `snake_case` rule. Links updated in `CLAUDE.md`,
  `AGENTS.md`, `README.md`, `docs/architecture.md`, `docs/implementation-plan.md` and
  `docs/implementation-progress.md`. Links inside old `plans/` and `change_log/` entries
  were left alone — those are point-in-time records of what happened at the time.
- `docs/features.md` and `docs/feature_analysis_and_roadmap.md` are not recognized
  document types. Rather than merge them now, each gained a purpose paragraph and a
  "which document owns what" callout saying which living document wins on a disagreement.
- The existing kebab-case names (`security-rules.md`, `release-signing.md`,
  `workflow-rules.md`, `implementation-plan.md`, `implementation-progress.md`,
  `security-audit-phase13.md`) were **not** renamed — the guideline tolerates older
  kebab names and says not to rename for style alone.

## 9. Rule files updated

`CLAUDE.md` and `AGENTS.md` §8 gained the logging rule: use `AppLogger`, never `print` or
`debugPrint`, with a pointer to `docs/architecture.md` §16.

## 10. `docs/project_structure.md`

- Added the `logging/` row to the `lib/core/` table.
- Added a callout recording the **accepted deviation** on `fonts/`: the standard §3.3 puts
  fonts under `assets/fonts/`, this project keeps them at the root. Moving them would
  rewrite every font path and licence file for no functional gain.
- Rewrote the "Large files and why" section. It claimed six files were over 500 lines with
  stale line counts; the real number is **fifteen**. All fifteen are now listed with
  current counts and a one-line justification each.

---

## 11. Deviations from the approved plan

Two things were done differently from the plan. Both are recorded here because they were
not what was approved.

1. **`avoid_redundant_argument_values` was not enabled.** The plan said to add it and fix
   whatever it reported. It reports **111 existing sites**, including regex
   `caseSensitive: false` flags in the parsers and explicit arguments in
   `backup_crypto.dart` and `secure_wipe.dart`. Stripping those values is a real
   behavioural risk inside a conformance pass, and in several places writing the value out
   is the clearer, safer code. The rule is a "recommended baseline" addition, not a MUST.
   The reason is written as a comment in `analysis_options.yaml` so the next reader does
   not re-add it blindly. `avoid_print` was added as planned.
2. **No `logger` package was added.** The plan said to add the `logger` dependency.
   Standard §14.2 explicitly leaves the implementation to the project, and `AppLogger`
   built on `dart:developer` meets every requirement with **no new dependency** to
   licence-check or audit for hidden networking. For an offline-first app with a strict
   dependency policy that is the better trade. `pubspec.yaml` was therefore not changed.

## 12. Work deliberately left for later

None of these were in scope for a conformance pass:

- Move existing diagnostics in `lib/` onto `AppLogger`.
- Localize the preset chip labels in `column_selection_sheet.dart` (`Bullet - `, `Col 4`,
  `01. (Pad 2)` and similar). Their labels are mostly the literal syntax being inserted
  with an English word attached, so they need keys shaped differently from ordinary UI copy.
- Non-UI exception messages in `lib/sync/payload.dart` and its neighbours are surfaced to
  users through `SnackBar(content: Text(e.message))` in a few places. Making those
  localized needs an error-code layer, not a string swap.
- Split the fifteen files over 500 lines.
- Fold `features.md` and `feature_analysis_and_roadmap.md` into the living documents.
- Move `fonts/` under `assets/fonts/`.
- Commit the `docs/guidelines` submodule pointer, which is ahead of the recorded commit.
  The submodule working tree is clean — nothing inside it was edited from this project.
