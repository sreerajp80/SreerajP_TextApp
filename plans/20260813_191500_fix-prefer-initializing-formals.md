# Fix all `prefer_initializing_formals` analyzer warnings

**Status:** completed

## What the issue is

`flutter analyze` reports **54 issues, all of the same kind**: `prefer_initializing_formals`.
They are `info` level (style hints), not errors. The app still builds and runs.

Why they appeared now: the project moved to **Dart 3.12**. Dart 3.10 added a language
feature called **private named parameters**. It lets a constructor write
`required this._field` in a *named* parameter list. Outside the class the parameter is
still called `field` (no underscore), so **callers do not change**.

Before that feature, the only way to fill a private field from a named parameter was the
"pass a public name, then copy it in the initializer list" pattern this codebase uses:

```dart
DraftStore({
  required Directory baseDir,
  required DraftsIndexRepository index,
})  : _baseDir = baseDir,
      _index = index;
```

Now the analyzer flags that copying as unnecessary.

I verified the feature really works on the installed Dart 3.12.2 with a small test program
before writing this plan, so this is not a guess.

## The plan for the fix

1. Run `dart fix --apply --code=prefer_initializing_formals`. This is the analyzer's own
   automated fix for exactly this one lint. It rewrites the pattern above into:

   ```dart
   DraftStore({
     required this._baseDir,
     required this._index,
   });
   ```

   Scoping it to this one lint code keeps the change from touching anything else.
2. Run `flutter analyze` and confirm **0 issues**.
3. Run `flutter test` and confirm the suite still passes. This is the real safety check —
   call sites keep the same public names, so nothing should break.
4. Review the diff by hand for the few constructors that also have a default value or an
   extra bit of logic (for example `_now = now ?? _wallClockMillis` in `draft_store.dart`,
   which the tool should leave alone because it is not a plain copy).
5. Write the change log to `change_log/`.

Nothing else changes: no behaviour change, no public API change, no dependency change,
no `analysis_options.yaml` change.

## Files to be changed (15 files, 54 edits)

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

Note: `lib/core/storage/key_value_store.dart` and `lib/sync/sync_provider.dart` are
security-sensitive (secrets storage and P2P sync). The edit there is only the constructor
parameter style — no change to what is stored, logged, or sent — so `docs/security-rules.md`
is not affected. I will still read the diff for those two files closely.

## Risk

Low. The change is mechanical, applied by the analyzer's own fix tool, verified by
`flutter analyze` + `flutter test`, and it does not alter the names callers use.

## Alternative I am not proposing

We could silence the lint in `analysis_options.yaml` instead. I do not recommend it: the
lint is pointing at real boilerplate that the new language feature removes, and turning the
rule off would hide future cases too.
