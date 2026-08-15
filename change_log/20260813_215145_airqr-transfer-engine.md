# Optical air-gap transfer (AirQR) — Steps 1 and 2 built

Implements plan `plans/20260813_211621_airqr-transfer-engine.md`, which was scoped by
`plans/20260813_210812_airqr-scope-clarification.md`.

Feature 7 in [docs/feature_analysis_and_roadmap.md](../docs/feature_analysis_and_roadmap.md)
§3 is now partly delivered: **Step 1 (snippet transfer)** and **Step 2 (single-document
transfer)**. Step 3 (settings & rules) is still open.

**No new dependency was added.** `qr_flutter`, `mobile_scanner`, the `CAMERA` permission, and
`SyncCrypto` were all already in the project for LAN pairing, so `pubspec.yaml` and the
Android manifest are untouched.

---

## What a user can now do

- Open any TXT, Markdown, CSV, JSON, or XML document → overflow menu → **Send by QR**. The
  screen shows an animated QR stream and a 6-character session code.
- Select text inside any editor → selection popup → **Send selection by QR**.
- Settings → Sync → **Air-gap transfer (QR)** → **Receive**. The camera collects frames with a
  live progress bar, asks for the session code, verifies the data, then offers to copy it or
  save it as a file through the system file picker.

---

## Three design decisions worth recording

### 1. Reed-Solomon was dropped, and the roadmap was corrected

The roadmap promised "Reed-Solomon error correction to handle dropped frames". That mixes up
two different layers:

- A QR symbol **already** carries Reed-Solomon — that is what error-correction level L/M/Q/H
  is, and it repairs a *damaged* frame. AirQR uses **level M**, so this part is in place.
- A **dropped** frame is an erasure. Nothing inside one QR can rebuild a frame the camera
  never saw. That needs a fountain code, and no vetted open-source Dart implementation exists,
  so it would have meant hand-writing and self-certifying GF(256) maths.

The user approved replacing it with cyclic repetition. §3 below covers how that turned out.

### 2. The repetition needed a shuffle, and it took three tries to get right

This is the part that did not go to plan, and it is worth reading before touching
`airqr_sender.dart`:

| Attempt | What failed |
| --- | --- |
| Loop the frames in a fixed order | A camera dropping frames on a rhythm near the cycle length misses the **same** frame on every pass, forever. The transfer never finishes. |
| Pin the manifest to slot 0, rotate the data frames by one per pass | A period-aligned dropper then starved the **manifest** instead. Nothing may hold a fixed slot. |
| Rotate the whole cycle by one place per pass | Still fails when the drop period and cycle length line up: with a 16-frame cycle and a drop every 3rd scan, the +1 shift cancels exactly (16 ≡ 1 mod 3) and every third frame is lost on every pass. |
| **Reshuffle the whole cycle each pass** (shipped) | No fixed arithmetic relationship exists for a drop rhythm to lock onto. |

All four cases are now regression tests, including a sweep over drop periods 2 through 8. A
permutation still contains every index once, so the manifest appears exactly once per pass and
a late-starting receiver waits at most one cycle.

### 3. Encryption is on by default

The user chose the recommended option: every payload is sealed with AES-256-GCM, keyed by
PBKDF2-HMAC-SHA256 over a 6-character session code, reusing `SyncCrypto` unchanged. A
12-character option exists in the constants for a user who expects the stream to be recorded.

The code is never inside a frame — it is read aloud or typed. The file name and MIME type sit
**inside** the sealed envelope rather than in the manifest, so scanning one frame reveals the
transfer's size but not what the file is called.

---

## Files created

### `lib/airqr/`

| File | Purpose |
| --- | --- |
| `airqr_constants.dart` | Frame budget (~1.1 KB/frame), frame rate (5 fps default), size caps, protocol literals. Aliases the sync code alphabet rather than copying it, so the two cannot drift. |
| `airqr_payload.dart` | The transfer envelope, hostile-input validation, and file-name sanitising that strips path separators and control characters. |
| `airqr_codec.dart` | The whole wire format: gzip → AES-256-GCM → base64url → chunks, plus a manifest frame. Pure Dart, no Flutter import. |
| `airqr_sender.dart` | The reshuffling frame cycle (see §2 above). |
| `airqr_receiver.dart` | Frame collection, duplicate handling, missing-frame tracking, live rate, reassembly. |
| `airqr_provider.dart` | Send and receive controllers. The receive provider is `autoDispose` so a half-finished transfer's frames do not leak into the next session. |
| `ui/airqr_landing_screen.dart` | Receive entry point plus honest notes on speed and how to send. |
| `ui/airqr_send_screen.dart` | The animated QR, session code, frame/pass counters, speed and density sliders. |
| `ui/airqr_receive_screen.dart` | Scanner, live progress panel, code entry, result preview. |
| `ui/airqr_size_warning.dart` | The 256 KB / 1 MB / 4 MB size gate. |
| `ui/airqr_send_action.dart` | One shared send path, so all five formats behave identically. |
| `ui/airqr_receive_action.dart` | Saves a received payload through the user's own SAF picker, then opens it. |

### `test/airqr/`

| File | Covers |
| --- | --- |
| `airqr_codec_test.dart` | Round trips (sealed, unsealed, uncompressed, multi-frame); compression actually shrinks; wrong code fails the GCM tag; foreign QR rejected; the **LAN pairing QR is rejected** by the AirQR parser; version mismatch; over-long scan; bad index; malformed digest; corrupted mid-stream chunk. |
| `airqr_receiver_test.dart` | Clean pass; duplicates; out-of-order; frames before the manifest; **the four dropped-frame cases from §2**; missing-frame list; new-manifest restart; wrong code; sender cycle properties. |
| `airqr_payload_test.dart` | Envelope validation, every cap, and name sanitising (`../../etc/passwd`, backslashes, null bytes, over-long, empty). |
| `no_secret_logging_test.dart` | No logging calls anywhere in `lib/airqr`, and no frame leaks the session code, the content, or the file name. |

---

## Files modified

| File | Change |
| --- | --- |
| `lib/core/editor/editor_selection_toolbar.dart` | Optional `onSendSelection` callback adds "Send selection by QR" to the selection popup. Allowed in read-only mode, since it copies text out rather than editing. |
| `lib/formats/{txt,markdown,csv,json,xml}/*_toolbar.dart` | "Send by QR" added to each overflow menu (enum value, menu item, handler). |
| `lib/formats/txt/txt_editor_surface.dart`, `markdown/md_editor_surface.dart`, `csv/csv_raw_view.dart`, `json/json_editor_surface.dart`, `xml/xml_editor_surface.dart` | Pass the selection-send callback through. |
| `lib/shell/settings/sections/sync_section.dart` | "Air-gap transfer (QR)" entry beside LAN sync. |
| `lib/l10n/app_en.arb`, `lib/l10n/app_ml.arb` | 48 new keys each, English and Malayalam. |
| `docs/architecture.md` | New §9A covering the module, frame format, the Reed-Solomon reasoning, the trust model, and the caps. |
| `docs/security-rules.md` | New rules block: seal every payload, never put the code in a frame, keep the name inside the envelope, be honest about a 6-character code, sanitise received names. |
| `docs/project_structure.md` | `lib/airqr/` added to the layout, the file table, the test tree, and the "where do constants live" table. |
| `docs/feature_analysis_and_roadmap.md` | Feature 7 corrected on Reed-Solomon; Phase 18 Steps 1 and 2 ticked. |
| `CLAUDE.md`, `AGENTS.md` | `airqr/` added to the module layout rule, kept in step with each other. |

---

## Verification

- `flutter analyze` — **no issues found**.
- `dart format lib test` — clean.
- `flutter test` — **all 893 tests pass**, including 57 new AirQR tests.

### Not yet verified, and it matters

**A real two-device transfer has not been tested.** Unit tests prove the codec, the dropped-
frame recovery, and the validation, but they cannot prove that a real phone camera reads the
chosen frame density at the chosen frame rate. The same rule the project already applies to
LAN sync (`CLAUDE.md` §10) applies here: **check a real device-to-device transfer by hand
before release.** The speed and density sliders exist precisely because the right defaults can
only be found on real hardware.

### Known limitation

The sending screen does **not** keep the display awake. A long transfer can be interrupted by
the screen timeout. Fixing it properly needs a wakelock package, which is a new dependency and
therefore a separate decision — it was left out rather than added quietly.
