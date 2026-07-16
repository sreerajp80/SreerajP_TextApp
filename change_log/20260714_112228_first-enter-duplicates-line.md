# Change log: fix first Enter duplicating the line in a newly opened editor

**Implements:** `plans/20260714_104458_first-enter-duplicates-line.md`
**Date:** 2026-07-14

## Problem

When a document was opened and put into edit mode (pen), placing the cursor at the
end of a line and pressing **Enter** duplicated the line. It happened only the
**first** time a document was opened for editing.

## Cause

The editor uses the open-source `re_editor` package (0.10.0). On Android the
keyboard keeps a "composing region" over existing text because `re_editor` opens
its keyboard connection with `enableSuggestions` left at the default `true`. On the
first Enter the composing region is finalized, so the newline reaches `re_editor`
through two paths at once (a `\n` text delta and `performAction(newline)`), and the
line break is applied twice. This is the known Flutter Android bug
flutter/flutter#31512. After the first Enter the composing region is gone, so later
Enters work — hence "first time only".

`re_editor` exposes no public API to change this, so the package had to be patched.

## What was changed

1. **Vendored `re_editor` 0.10.0 into the repo** at `third_party/re_editor/`
   (MIT licensed; allowed by CLAUDE.md §3.1). It is an exact copy except for the
   one patch below.

2. **Patched `third_party/re_editor/lib/src/_code_input.dart`:** added
   `enableSuggestions: false` to the `TextInputConfiguration` used when the
   keyboard connection is opened (both at the call site in `_openInputConnection`
   and as the default on the `_TextInputConfiguration` constructor). This removes
   the Android composing region, so the first Enter no longer double-applies the
   newline. Turning off suggestions is also the correct behavior for a text/code
   editor.

3. **Added `third_party/re_editor/PATCH_NOTES.md`** describing the single patch and
   how to re-apply it on a future upgrade (or drop it if upstream fixes the bug or
   exposes an input-config hook).

4. **Edited `pubspec.yaml`:** added a `dependency_overrides` block pointing
   `re_editor` at `third_party/re_editor`. The existing `re_editor: ^0.10.0` under
   `dependencies` is unchanged. Ran `flutter pub get` (override active).

## Verification

- `flutter analyze lib` → **No issues found**. (Analyzing the vendored package
  surfaces only its own pre-existing lint infos/warnings, unrelated to the patch.)
- Built the release APK and installed it on the connected device (moto g54 5G,
  Android 15); launched the app.
- **Manual device check is required to confirm the fix**, because the bug is
  triggered by the on-screen keyboard's composing region. `adb` key injection
  bypasses the soft keyboard and cannot reproduce or validate this IME-specific
  behavior, so the tactile test on the device is the real confirmation: open a
  document → pen → cursor at end of a line → Enter should no longer duplicate the
  line, on the first Enter and after.

## Notes / follow-up

- Consider reporting the missing `enableSuggestions: false` upstream to
  reqable/re-editor so the vendored copy can eventually be dropped.
