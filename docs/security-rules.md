# Security rules — SreerajP_TextApp

Read this file before changing any security-sensitive code (P2P sync, crypto,
storage, logging, secrets, or anything touching file input). These rules are part of
the project rules in [../CLAUDE.md](../CLAUDE.md). Full detail is in the Security
Architecture section of [architecture.md](architecture.md).

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
- Use **`Random.secure()`** for all security-relevant randomness.
- Consider **app-lock** and **screenshot protection** on screens showing the pairing code/QR.
