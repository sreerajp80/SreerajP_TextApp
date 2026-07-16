# Exclude third_party from Dart analysis

**Status:** completed

## What the issue is

The Dart analyzer reports errors in vendored code under
`third_party/re_editor/example/lib/editor_autocomplete.dart`:

- A misspelled package import (`re_editor_exmaple`).
- Outdated API use (`CodeFindPanelView`, `ContextMenuControllerImpl`).

This is the **example app** bundled inside the vendored `re_editor` package. It
is not part of our app and is not built by us. The errors only clutter the IDE
Problems panel and `flutter analyze` output. We should not hand-edit vendored
third-party code to fix them.

## Files to be changed

- `analysis_options.yaml` — add an `analyzer.exclude` list for `third_party/**`.

## The plan for the fix

Add an `analyzer` section to `analysis_options.yaml` that excludes the whole
`third_party/` tree from analysis:

```yaml
analyzer:
  exclude:
    - third_party/**
```

This stops the analyzer from reporting on any vendored code, which is the
standard way to handle bundled dependencies. Our own code under `lib/` and
`test/` is unaffected.

## Verify

- Run `flutter analyze` and confirm no errors are reported from `third_party/`.
