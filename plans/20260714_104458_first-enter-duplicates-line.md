# Fix: first Enter duplicates the line when a document is first opened for editing

**Status:** completed

## What the issue is

When the user opens an existing document, taps the pen to edit, places the cursor
at the end of a line, and presses **Enter**, the line is duplicated (an extra line
break / duplicated content appears). This happens **only the first time** a document
is opened for editing. Every Enter after that behaves correctly.

## Why it happens (root cause)

The editor uses the open-source **`re_editor`** package (v0.10.0, the latest
published version). The bug is inside that package, triggered on Android:

- When editing starts and the cursor is placed inside already-loaded text, the
  Android keyboard puts a **composing region** (the autocorrect/suggestion
  underline) over the word at the cursor. This is the known Flutter Android bug
  flutter/flutter#31512.
- On the **first Enter**, the keyboard finalizes that composing region, so
  `re_editor` gets the newline through **two paths at the same time**:
  1. A text-change *delta* that contains `\n`
     (`_code_input.dart` ~line 143) → calls `applyNewLine()`.
  2. The keyboard's `performAction(newline)`
     (`_code_input.dart` ~line 105) → calls `applyNewLine()` **again** on Android.
- The line break is applied twice → the line is duplicated.
- After that first Enter the composing region is gone, so later Enters take only
  one path → they work. That is why it is **first-time only**.

The trigger is that `re_editor` opens its keyboard connection with
`enableSuggestions` left at its default value **`true`**
(`_TextInputConfiguration`, `_code_input.dart` ~line 733). It already disables
`autocorrect`, smart dashes, and smart quotes — but not suggestions, which is
what keeps the composing region alive.

`re_editor`'s public `CodeEditor` API gives **no way** to change this, so the
package itself must be patched.

## The fix

Set **`enableSuggestions: false`** on `re_editor`'s input configuration. Since the
package must be changed and the app must stay open-source and build offline, we
**vendor a local copy of `re_editor` inside the repo** and apply this one-line
patch. (Chosen approach: vendor locally.)

## Files to be changed

1. **New:** `third_party/re_editor/**` — a copy of `re_editor` 0.10.0 (the package
   is MIT/open source, allowed by CLAUDE.md §3.1).
2. **Edit:** `third_party/re_editor/lib/src/_code_input.dart` — the only code
   change: add `enableSuggestions: false` to the `_TextInputConfiguration` used in
   `_openInputConnection` (and expose it on the `_TextInputConfiguration`
   constructor). Nothing else in the copy is changed.
3. **New:** `third_party/re_editor/PATCH_NOTES.md` — short note describing the one
   patch and why, so the change is easy to re-apply on a future upgrade.
4. **Edit:** `pubspec.yaml` — add a `dependency_overrides` entry:
   ```yaml
   dependency_overrides:
     re_editor:
       path: third_party/re_editor
   ```
   The existing `re_editor: ^0.10.0` line under `dependencies` stays.

## Steps

1. Copy the package cache folder `re_editor-0.10.0` into `third_party/re_editor/`.
2. Apply the one-line `enableSuggestions: false` patch.
3. Add `PATCH_NOTES.md`.
4. Add the `dependency_overrides` block to `pubspec.yaml`.
5. Run `flutter pub get`.
6. Build and install the app on the connected device (moto g54, Android 15) and
   manually verify: open a document → pen → cursor at end of a line → Enter no
   longer duplicates the line, on the first Enter and after.
7. Run `flutter analyze` and the existing test suite to confirm nothing broke.
8. Write the change log to `change_log/`.

## Risk / notes

- Only one line of behavior changes in the vendored package; everything else is an
  exact copy, so the risk is small.
- Turning off IME suggestions is desirable for a code/text editor anyway (it stops
  the keyboard from second-guessing what you type).
- Vendoring keeps the app fully offline and open source; no external fork or
  network dependency at build time.
