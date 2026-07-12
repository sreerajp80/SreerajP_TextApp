# Change log — Phase 5: Output & utility services

**Date:** 2026-07-10
**Implements plan:** `plans/20260710_111717_phase-5-output-utility-services.md`
**Phase:** 5 (Output & utility services) — tasks 5.1–5.5.

---

## What was done

Built the five shared "send it somewhere" services in `lib/core/` and wired them
into the TXT format (the first and, so far, only consumer). Later format phases
(6–9) reuse the same service instances.

### New packages (all open source — CLAUDE.md §3.1)

Added to `pubspec.yaml`: `share_plus` ^13.2.0 (BSD-3), `archive` ^4.0.2 (MIT),
`pdf` ^3.11.1 (Apache-2.0), `printing` ^5.13.4 (Apache-2.0), `flutter_tts` ^4.2.0
(MIT). `share_plus` was pinned to 13.x because 10.x conflicted with the existing
`package_info_plus` on `win32`; the solver resolved cleanly at 13.x. No Syncfusion.
No new dangerous permissions.

### 5.1 Share service
- `lib/core/share/share_service.dart` — `ShareService` over an injectable
  `ShareLauncher`; default `SharePlusLauncher` materializes bytes in the shared
  save temp dir and calls `share_plus`. Shares file bytes or raw text.

### 5.2 Zip service
- `lib/core/zip/zip_service.dart` — pure `ZipService` on `archive`;
  `zipEntries` / `zipOne` / `unzip`.

### 5.3 Print service
- `lib/core/print/print_service.dart` — `PrintService` over an injectable
  `PrintLauncher`; default `PrintingLauncher` calls `Printing.layoutPdf`. A
  document prints via its PDF rendering.

### 5.4 Export / convert service
- `lib/core/export/export_target.dart` — `ExportTarget` enum (pdf/docx/html/
  markdown/plainText), `TextContent`, `ExportResult`, `UnsupportedExportException`.
- `lib/core/export/format_exporter.dart` — `FormatExporter` interface.
- `lib/core/export/export_service.dart` — single service with a format registry;
  `supportedTargets` / `canExport` / `export`; unknown format or unsupported target
  throws `UnsupportedExportException` (clean rejection, never a crash — CLAUDE.md §3.4).
- `lib/core/export/pdf_writer.dart` — text → paged PDF (`pdf`).
- `lib/core/export/docx_writer.dart` — text → minimal valid `.docx` (OOXML) via
  `archive`; XML-escapes `& < > "`.
- `lib/core/export/html_writer.dart` — text → escaped self-contained HTML.
- `lib/core/export/txt_exporter.dart` — TXT exporter supporting all five targets.

### 5.5 TTS module
- `lib/core/tts/tts_state.dart` — `TtsLanguage` (en-US, ml-IN), `TtsAvailability`
  (ready / needsInstall / unavailable).
- `lib/core/tts/tts_service.dart` — `TtsService` (a `ChangeNotifier`) over an
  injectable `TtsEngine`; default `FlutterTtsEngine` wraps `flutter_tts`. State
  machine reports availability; `speak` re-checks first so a vanished voice
  auto-disables instead of failing.

### Wiring
- `lib/core/output/output_providers.dart` — Riverpod providers for all five services.
- `lib/formats/txt/txt_document_session.dart` — added a `textContent` snapshot getter.
- `lib/formats/txt/txt_output_actions.dart` — TXT actions: share, share as zip,
  print, run/save/share an export.
- `lib/formats/txt/txt_export_sheet.dart` — pick a target → export → share or save.
- `lib/formats/txt/txt_read_aloud_button.dart` — English read-aloud toggle; hides
  itself when TTS is unavailable (never a dead button).
- `lib/formats/txt/txt_toolbar.dart` — read-aloud button + overflow items
  (Share, Share as zip, Print, Export…).
- `android/app/src/main/AndroidManifest.xml` — added a `TTS_SERVICE` `<queries>`
  entry so `flutter_tts` can see the engine on Android 11+.

## Tests added (all green; full suite 190 passing, `flutter analyze` clean)

- `test/core/zip/zip_service_test.dart` — round-trip + ZIP signature.
- `test/core/share/share_service_test.dart` — request MIME/name/bytes (fake launcher).
- `test/core/print/print_service_test.dart` — job built (fake launcher).
- `test/core/export/export_service_test.dart` — TXT→PDF valid (`%PDF-`), TXT→DOCX
  valid zip with escaped text, plain-text verbatim, unknown format rejected.
- `test/core/export/docx_writer_test.dart` — core parts, one paragraph per line,
  escaping, empty input.
- `test/core/tts/tts_service_test.dart` — ready / needs-install / unavailable,
  speak, auto-disable when a voice disappears.

## Known limitations / follow-ups

- Exported PDF uses the `pdf` package's built-in Courier font (Latin-1 only), so
  non-ASCII text — including Malayalam — does not render in the PDF yet. Bundling a
  Unicode TTF is a later polish item, not in Phase 5 scope.
- The full **Speech** Settings section and the Malayalam guided-install intent
  launcher are deferred to Phase 11.4 (as planned).
- Format-specific export targets for MD/CSV/JSON/XML land in their own phases
  (6–9), each registering a `FormatExporter` with the same `ExportService`.
- Manual on-device pass still owed: real share sheet, print preview, open an
  exported PDF/DOCX, hear English read-aloud.
