# Change log — Fix settings sync key-namespace mismatch

Implements plan
[plans/20260712_121814_sync-settings-key-namespace.md](../plans/20260712_121814_sync-settings-key-namespace.md).

## What was wrong

P2P settings sync transferred nothing. The allow-list
`SyncConstants.syncableSettingKeys` listed **bare** keys (`theme_mode`,
`font_scale`, ...), but the app stores every setting under a **prefixed**
namespace (`appearance.*`, `tabs.*`, `tts.*`). The whole settings pipeline
(export, existing-key check, merge, apply) filters by that one set, so no real
stored key ever matched and `exportSettings()` always returned an empty map.
The old tests passed only because they wrote bare keys straight into the store.

## What changed

### Production

- **`lib/sync/sync_constants.dart`** — replaced the bare keys in
  `syncableSettingKeys` with the real namespaced storage keys, and added a
  comment saying they must be the real keys. Final set:
  - `appearance.theme_mode`, `appearance.font_scale`, `appearance.font_family`,
    `appearance.line_spacing`, `appearance.word_wrap`
  - `tabs.restore_on_relaunch`, `tabs.over_limit`, `tabs.fixed_cap`,
    `tabs.cap_mode`
  - `tts.english_enabled`, `tts.malayalam_enabled`
  - Dropped `theme_use_dynamic_color` (no such setting exists in the app).
  - Per the approved decisions: `tabs.cap_mode` is synced alongside
    `tabs.fixed_cap` so a synced fixed cap actually takes effect, and the two
    TTS voice toggles are now included.

  No other production logic changed — export, merge, and apply already key off
  this set, so fixing the set fixes the whole flow.

### Tests

- **`test/sync/sync_provider_test.dart`** — the full loopback round-trip now
  seeds and asserts the real keys `appearance.theme_mode` and `tabs.over_limit`,
  proving two namespaces end-to-end instead of a bare test-only key.
- **`test/sync/payload_test.dart`** — updated build/parse/merge cases to use the
  real keys (`appearance.theme_mode`, `appearance.font_scale`). The
  rejection cases (`not_allowed`, `weird`, `device_key`) are unchanged.

## Verification

- `flutter test test/sync/` — all pass.
- `flutter test` (full suite) — 536 tests, all pass.
- Manual two-device transfer remains a release gate (CLAUDE.md §6); not run here.

## Security

Only non-sensitive preference keys were added. `neverSyncKeys` is untouched, so
`device_key`, `app_lock_pin`, and `app_lock_recovery` still can never reach a
payload. No wire-format or protocol-version change.
