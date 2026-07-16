# Change log: Exclude third_party from Dart analysis

**Plan:** `plans/20260714_140000_exclude-third-party-from-analysis.md`
**Date:** 2026-07-14

## What changed

Added an `analyzer.exclude` block to `analysis_options.yaml` to stop the Dart
analyzer from reporting on vendored code under `third_party/`:

```yaml
analyzer:
  exclude:
    - third_party/**
```

## Why

`flutter analyze` reported 77 issues, all inside the vendored `re_editor`
package (bad imports and outdated API use in its bundled example app, plus many
lint infos). None were in our own `lib/` or `test/` code. Vendored third-party
code should not be analyzed or hand-edited.

## Result

`flutter analyze` now reports "No issues found!" Our own code is unaffected.
