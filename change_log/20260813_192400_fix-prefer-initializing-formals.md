# Change log — fix all `prefer_initializing_formals` analyzer warnings

**Date:** 2026-08-13
**Plan:** [plans/20260813_191500_fix-prefer-initializing-formals.md](../plans/20260813_191500_fix-prefer-initializing-formals.md)

## What was wrong

`flutter analyze` reported 54 issues. All were the same style hint,
`prefer_initializing_formals` (`info` level, not errors — the app built and ran fine).

They showed up because the project moved to Dart 3.12. Dart 3.10 added **private named
parameters**, which let a constructor write `required this._field` in a named parameter
list. That makes the older "take a public name, copy it into the private field" pattern
used across this codebase unnecessary, so the analyzer started flagging it.

## What was changed

Ran `dart fix --apply --code=prefer_initializing_formals` — the analyzer's own automated
fix, scoped to this single lint so nothing else was touched.

**54 edits across 15 files** (69 insertions, 114 deletions):

| File | Edits |
| --- | --- |
| `lib/core/editor/draft_store.dart` | 5 |
| `lib/core/editor/editor_controller.dart` | 1 |
| `lib/core/editor/saf_save_target.dart` | 5 |
| `lib/core/export/csv_exporter.dart` | 2 |
| `lib/core/export/md_exporter.dart` | 2 |
| `lib/core/export/txt_exporter.dart` | 3 |
| `lib/core/storage/key_value_store.dart` | 3 |
| `lib/formats/csv/csv_document_session.dart` | 5 |
| `lib/formats/json/json_document_session.dart` | 5 |
| `lib/formats/json/json_exporter.dart` | 3 |
| `lib/formats/markdown/md_document_session.dart` | 5 |
| `lib/formats/txt/txt_document_session.dart` | 5 |
| `lib/formats/xml/xml_document_session.dart` | 5 |
| `lib/formats/xml/xml_exporter.dart` | 3 |
| `lib/sync/sync_provider.dart` | 2 |

Example, from `draft_store.dart`:

```dart
// before
DraftStore({
  required Directory baseDir,
  required DraftsIndexRepository index,
  int Function()? now,
})  : _baseDir = baseDir,
      _index = index,
      _now = now ?? _wallClockMillis;

// after
DraftStore({
  required this._baseDir,
  required this._index,
  int Function()? now,
})  : _now = now ?? _wallClockMillis;
```

**Callers did not change.** The underscore is private to the class; from outside, the
parameter is still `baseDir`. No public API change, no behaviour change, no dependency
change, no `analysis_options.yaml` change.

## Checks run

- `flutter analyze` → **No issues found!** (was 54).
- `flutter test` → **all 831 tests passed**.
- Hand-reviewed the diff for the two security-sensitive files,
  `lib/core/storage/key_value_store.dart` (secrets storage) and `lib/sync/sync_provider.dart`
  (P2P sync). Both changed only in constructor parameter style. Nothing changed about what
  is stored, logged, or sent, so `docs/security-rules.md` is unaffected.
- Confirmed the tool correctly left the non-plain-copy initializers alone —
  `_now = now ?? _wallClockMillis` in `draft_store.dart` stayed as an initializer, and the
  `_sensitiveKeys = defaultSensitiveKeys` default value was preserved.

## Deliberately not done

`dart format` was **not** run. Checking it showed 186 of the 259 files in `lib/` would be
reformatted, because the codebase predates the newer Dart formatter style. That is a
separate, repo-wide decision and would have hidden this small change inside a huge diff.

One cosmetic leftover from this: a few constructors now read `})  : _now = ...` with two
spaces before the colon, which the old alignment left behind. It is harmless and the
formatter would clean it up whenever the repo-wide reformat is done.
