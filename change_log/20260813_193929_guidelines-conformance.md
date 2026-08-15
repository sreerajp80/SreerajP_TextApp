# Change log — Guidelines conformance

**Date:** 2026-08-13
**Plan:** `plans/20260813_192612_guidelines-conformance.md`
**Result:** Groups 1, 2, and 3 implemented. Group 4 not done (it was optional in the plan).

This change brings the project structure, documentation, and coding standards in line with
the shared guidelines in `docs/guidelines/`.

---

## 1. Documentation (Group 1)

### Created

- **`AGENTS.md`** — the mandatory root instruction file for non-Claude AI agents, written to
  `docs/guidelines/AGENTS_MD_GUIDELINE.md`. Thin profile. It carries all "Always" sections
  and mirrors `CLAUDE.md` exactly, including the inline workflow and simple-English rules.
- **`docs/project_structure.md`** — the root and `lib/` file tree, one line per folder, the
  shared shape every `formats/<type>/` folder follows, and the rules for where a new file
  goes.
- **`docs/dependencies.md`** — every runtime and dev package with its licence and the reason
  it is here, the blocked list, the vendored `re_editor` note, fonts, a pre-add checklist,
  and the audit cadence.

### Changed

- **`CLAUDE.md`** — rewritten in the canonical section order from
  `docs/guidelines/CLAUDE_MD_GUIDELINE.md` §2. The existing hard rules, security pointer, and
  workflow text were kept. Nine missing "Always" sections were added:
  project identity table, "read these docs" table, architecture rules, build & run commands,
  build flavors, signing / keystore, code style / naming, dependency constraints, and
  dos & don'ts. The workflow section now carries the "relative repository paths only, no
  sensitive data" clause the guideline requires inline.
- **`docs/GUIDELINES_MANIFEST.md`** — refreshed from the submodule master copy. The local
  copy was an older, shorter version.

### Not done, on purpose

The older kebab-case doc names (`security-rules.md`, `release-signing.md`,
`workflow-rules.md`, `implementation-plan.md`, `implementation-progress.md`) were **not**
renamed. `DOCS_FOLDER_GUIDELINE.md` §3 tolerates them and says not to rename for style
alone. New docs use `snake_case`.

---

## 2. Lint rules and package imports (Group 2)

### `analysis_options.yaml`

Added the stricter rule set from the engineering standard §16.1, on top of `flutter_lints`:
`always_use_package_imports`, `cancel_subscriptions`, `close_sinks`, `avoid_empty_else`,
`no_duplicate_case_values`, `use_enums`, `prefer_single_quotes`, `prefer_const_constructors`,
`prefer_const_declarations`, `prefer_final_fields`, `prefer_final_locals`, `prefer_is_empty`,
`unnecessary_brace_in_string_interps`, `unnecessary_this`, `noop_primitive_operations`,
`avoid_bool_literals_in_conditional_expressions`, `avoid_unnecessary_containers`,
`sized_box_for_whitespace`, `use_key_in_widget_constructors`, `sort_child_properties_last`,
`use_decorated_box`, `use_full_hex_values_for_flutter_colors`.

Two rules from the standard's list were left out on purpose:

- `avoid_print` — already on via `flutter_lints`.
- `avoid_redundant_argument_values` — noisy on Flutter widget code and it fights explicit,
  readable defaults.

### `test/analysis_options.yaml` (new)

Tests import app code as `package:text_data/...`, but the shared test helper
(`test/support/test_support.dart`) sits outside `lib/` and has no package URI, so it must be
imported relatively. This file inherits the root config and turns off
`always_use_package_imports` for `test/` only.

### Import conversion

All relative imports under `lib/` were rewritten to `package:text_data/...`:

- **914 imports across 204 files.**
- Done with a one-off script; every target path was resolved and checked to exist before
  rewriting. No unresolved paths.
- The package had no `part`, `export`, or conditional imports, so nothing else needed care.
- `test/` already used `package:` imports for app code and was left alone.

### Automated lint fixes

Enabling the new rules surfaced 27 issues. All were fixed with `dart fix --apply` on `lib`
and `test` (31 fixes across 20 files) — mostly `prefer_const_constructors`,
`prefer_const_declarations`, `noop_primitive_operations`, `use_decorated_box`, and
`avoid_bool_literals_in_conditional_expressions`. No hand edits to logic were needed.

### Formatting scope corrected

`dart format .` reformats the vendored `third_party/re_editor` copy, which must stay as
upstream apart from its documented patch. Those 54 files were reverted, and the documented
command in `CLAUDE.md`, `AGENTS.md`, and CI is now **`dart format lib test`**.

---

## 3. CI (Group 3)

Created **`.github/workflows/ci.yml`** — runs on push and pull request to `master`, and on
manual dispatch:

1. `flutter pub get`
2. `dart format --output=none --set-exit-if-changed lib test`
3. `flutter analyze --no-pub`
4. `flutter test --no-pub --coverage`, with `coverage/lcov.info` uploaded as an artifact

Flutter is pinned to 3.44.8 with caching.

---

## 4. Verification

| Check | Result |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test` | Clean — 373 files, 0 changed |
| `flutter analyze --no-pub` | **No issues found** |
| `flutter test` | **All 831 tests passed** |
| Relative imports left in `lib/` | 0 |
| `package:text_data/` imports in `lib/` | 914 |
| `third_party/` modified | 0 files |
| Line endings in `lib/` | 259 files, all LF — unchanged |

One extra check was run because the rewrite touched almost every file:
`lib/formats/csv/csv_table.dart` contains a deliberate NUL byte and some UTF-8 punctuation,
which makes tools treat it as binary. Its odd-byte set is byte-for-byte the same before and
after the rewrite (only the offsets moved by the import length), so nothing was corrupted.

---

## 5. Left open

- **Group 4 — `lib/core/constants/app_constants.dart`.** Still not created. The plan marked
  it optional because it means moving constants out of working code. Needs its own decision.
- **Six files over 500 lines** (`csv_document_session.dart` 956, `json_document_session.dart`
  764, `json_parser.dart` 661, `md_document_session.dart` 631, `xml_document_session.dart`
  623, `txt_document_session.dart` 510). Engineering standard §16.2 says "split or justify".
  Each is one document type's session with a single clear job. Splitting them is a
  risk-bearing refactor and should be its own plan.
- **Transitive `http`.** It is in the tree via `package_info_plus`, `printing`, and
  `flutter_svg`/`vector_graphics`. The app never calls it. Recorded in
  `docs/dependencies.md` §4.1 with the conditions for keeping it.
- **`docs/security.md` full blueprint.** The project has a short `security-rules.md` plus a
  security section in `architecture.md`. The fuller blueprint (threat model, OWASP checklist)
  from the Sensitive Data Extension is not written as its own file.
