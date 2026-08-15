# Security rules — SreerajP_TextApp

Read this file before changing any security-sensitive code (P2P sync, crypto,
storage, logging, secrets, or anything touching file input). These rules are part of
the project rules in [../CLAUDE.md](../CLAUDE.md).

This is the short, day-to-day rules list. The full blueprint — threat model, sensitive-data
inventory, crypto parameters, OWASP checklist, retention policy, and open risks — is in
[security.md](security.md). Design context is in [architecture.md](architecture.md).

Security is not optional. Follow these for every change.

- **Treat every opened file as untrusted input.** Validate before use. Do not send file
  contents anywhere without the user's explicit action (share/export/sync).
- **P2P sync security lives at the payload layer**, never the transport:
  - Generate a **fresh, high-entropy pairing code per session** (~320 bits).
  - Move the code **out-of-band** (QR or typed). **Never put the pairing code on the wire.**
  - Derive the key with **PBKDF2-HMAC-SHA256** (per-session random salt; the salt may be
    sent in the clear).
  - Seal **every** wire message with **AES-256-GCM**. A wrong code fails the GCM tag and
    aborts the handshake.
  - The random TCP port is conflict-avoidance only — **not** a security boundary.
- **Harden against a hostile peer**: bounded reads (separate caps for handshake vs payload),
  connect + socket timeouts, payload caps (max records, per-field length, schema checks)
  enforced **before** ingestion, single client at a time, idle auto-stop, strict QR parsing.
- **Merge is add-only, client-wins.** The receiver never has its data overwritten on a
  conflict. Only an explicit **allow-list** of non-sensitive settings may sync. **Never**
  sync security/identity state (PINs, app-lock enablement, biometrics, per-device keys).
- **Secret lifecycle:** secrets are re-sealed under the session key only transiently in
  memory while building a payload, and re-encrypted under the receiving device's own key on
  import. Device-specific secrets use **`flutter_secure_storage`**.
- **Never log** file contents, payloads, secrets, keys, or the pairing code — not even in
  debug builds. Keep all error messages user-safe (no secret material).
- **App data must never be backed up off the device.** Android backup stays disabled
  (`allowBackup="false"` plus fully-excluding `backup_rules.xml` and
  `data_extraction_rules.xml`). Drafts hold the plain text of documents being edited, so a
  cloud backup would move user content off-device with no user action. **P2P sync is the
  migration path** between devices. See [security.md](security.md) §10.4.
- Use **`Random.secure()`** for all security-relevant randomness.
- Consider **app-lock** and **screenshot protection** on screens showing the pairing code/QR.
- **Optical air-gap transfer (AirQR) is displayed in the open.** A QR stream is visible to
  anyone who can see the screen, and recordable by anyone with a camera. So:
  - **Seal every payload** with AES-256-GCM, keyed by PBKDF2 over the session code. An
    unsealed transfer is only allowed with an explicit on-screen warning.
  - The **session code never goes inside a frame.** It travels by voice or by hand. A frame
    that carried it would make sealing pointless. `test/airqr/no_secret_logging_test.dart`
    asserts no frame contains the code, the content, or the file name.
  - Keep the **file name and MIME type inside the sealed envelope**, not in the manifest, so
    one scanned frame does not reveal what is being sent.
  - Be honest about the short code: 6 characters is ~30 bits — enough against a bystander,
    not against someone who records the whole stream. Say so in the UI and offer the longer
    code.
  - **Never log** frame contents, the session code, the derived key, or the salt.
  - Treat a received envelope as hostile: check app id, version, and kind; enforce the size
    caps; and **sanitise the suggested file name** so a sender can never propose a path. The
    receiver always chooses the destination through its own SAF picker.
- **Self-destructing documents must never over-promise.** Feature 9 (`lib/core/ephemeral/`)
  clears every trace *the app itself* keeps of one document. Three limits are part of the
  rules, not footnotes, and the UI wording must keep matching them:
  - **Never delete the user's own file.** The app is scoped-storage only, so a burn clears
    app-private data. Any change that starts deleting user documents needs a new decision.
  - **Do not describe the `0x00` overwrite as erasure.** It defeats an ordinary undelete of
    the logical file; flash wear-levelling can keep the old blocks alive out of reach.
    Android's per-app file encryption is the real protection. Say "overwrites the app's
    stored copy", never "securely erases from the device".
  - **Do not claim Dart strings are scrubbed.** `String` is immutable and
    garbage-collected — only `Uint8List` buffers are genuinely zero-filled. A caller may
    only zero a buffer it owns; `SafService.readBytes` documents that its result is the
    caller's, and test doubles must copy for the same reason.
  - **Wipe the search index first.** It is the only store holding the document's own text,
    so a burn interrupted part-way must already have cleared it.
  - **Keep `EphemeralWiper.fingerprintKeyPrefixes` in step with the format sessions.** Every
    per-file preference key a session writes must appear there; a missing prefix is a trace
    that survives a burn.
  - **Never log** a burned document's fingerprint, file name, or content — including in the
    failure report a partial burn returns.
