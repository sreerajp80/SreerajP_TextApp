# Local patch notes for the vendored `re_editor`

This folder is a copy of **`re_editor` 0.10.0** (from pub.dev, MIT licensed). It is
vendored into the app and wired in through `dependency_overrides` in the project
`pubspec.yaml` so we can carry one small patch that the package gives no public API
for.

## The only change vs. upstream 0.10.0

**File:** `lib/src/_code_input.dart`

Add `enableSuggestions: false` to the `TextInputConfiguration` that `re_editor`
uses when it opens the Android keyboard connection:

- In `_openInputConnection`, the `_TextInputConfiguration(...)` call now passes
  `enableSuggestions: false`.
- The `_TextInputConfiguration` constructor now defaults
  `super.enableSuggestions = false`.

Nothing else is changed.

## Why

With `enableSuggestions` at its default `true`, the Android keyboard keeps a
"composing region" over existing text. When a document was first opened for
editing and the user pressed **Enter** at the end of a line, the newline was
applied twice (once from the `\n` text delta and once from
`performAction(newline)`), so the line was duplicated. This is the known Flutter
Android bug flutter/flutter#31512. Turning suggestions off removes the composing
region, so the first Enter no longer duplicates the line. Disabling suggestions is
also the right behavior for a code/text editor.

## Re-applying on upgrade

When bumping `re_editor`, re-copy the new version into this folder and re-apply the
two edits above (search for `enableSuggestions`). If a future upstream release
fixes flutter/flutter#31512 (or exposes an input-config hook), drop this vendored
copy and the `dependency_overrides` entry and go back to the pub.dev package.
