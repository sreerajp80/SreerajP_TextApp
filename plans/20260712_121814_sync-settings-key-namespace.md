# Fix settings sync key-namespace mismatch

**Status:** completed

## The issue

P2P settings sync transfers nothing. The allow-list
`SyncConstants.syncableSettingKeys` uses **bare** keys
(`theme_mode`, `font_scale`, ...), but the app stores every setting under a
**prefixed** namespace (`appearance.theme_mode`, `tabs.*`, `tts.*`).

Because the whole settings pipeline — export, existing-key check, merge, and
apply — filters strictly by `syncableSettingKeys`, and no real stored key ever
matches a bare allow-list entry:

- `exportSettings()` reads each bare key from the store, finds nothing, and
  returns an empty map. Nothing is ever put on the wire.
- Even if a bare key were on the wire, `applySettings()` would write it back
  under the bare name, which no controller reads.

The existing tests pass only because they write bare `theme_mode` directly into
the store, so the round-trip is self-consistent in the test but never reflects
what the real app writes.

## Root cause

`SyncConstants.syncableSettingKeys` is the single source of truth (used in
[payload.dart](../lib/sync/payload.dart) build/parse/merge and
[sync_data_access.dart](../lib/sync/sync_data_access.dart)). Its entries do not
match the real storage keys defined in the settings controllers.

## The fix

Replace the bare keys in `syncableSettingKeys` with the **real stored keys**.
This one change fixes the entire pipeline because every stage reads from that
set.

### Key mapping (bare → real)

| Old (bare) | New (real stored key) | Type | Source |
|---|---|---|---|
| `theme_mode` | `appearance.theme_mode` | String | `ThemeSettings.modeKey` |
| `font_scale` | `appearance.font_scale` | double | `ThemeSettings.fontScaleKey` |
| `font_family` | `appearance.font_family` | String | `ThemeSettings.fontFamilyKey` |
| `line_spacing` | `appearance.line_spacing` | double | `ThemeSettings.lineSpacingKey` |
| `default_word_wrap` | `appearance.word_wrap` | bool | `ThemeSettings.wordWrapKey` |
| `restore_tabs_on_relaunch` | `tabs.restore_on_relaunch` | bool | `TabsPersistence.restoreEnabledKey` |
| `over_limit_close_lru` | `tabs.over_limit` | String | `TabsController.overLimitKey` |
| `max_open_tabs` | `tabs.fixed_cap` **and** `tabs.cap_mode` | int / String | `TabsController.fixedCapKey`, `capModeKey` |
| `theme_use_dynamic_color` | *(dropped)* | — | no such setting exists in the app |
| *(new)* | `tts.english_enabled` | bool | `TtsSettings.englishKey` |
| *(new)* | `tts.malayalam_enabled` | bool | `TtsSettings.malayalamKey` |

Decisions (confirmed with the user):
- **Tab cap:** sync both `tabs.fixed_cap` and `tabs.cap_mode`, so a synced fixed
  cap actually takes effect on the receiver (a fixed cap is ignored unless
  `cap_mode` = `fixed`).
- **TTS:** include `tts.english_enabled` and `tts.malayalam_enabled`.
- **Dynamic color:** drop `theme_use_dynamic_color`; the app has no
  dynamic-color preference, so it was a dead entry.

### Final allow-list

```
appearance.theme_mode
appearance.font_scale
appearance.font_family
appearance.line_spacing
appearance.word_wrap
tabs.restore_on_relaunch
tabs.over_limit
tabs.fixed_cap
tabs.cap_mode
tts.english_enabled
tts.malayalam_enabled
```

`neverSyncKeys` is unchanged — `device_key`, `app_lock_pin`,
`app_lock_recovery` are already the real keys and stay excluded.

## Files to change

1. **`lib/sync/sync_constants.dart`** — rewrite the `syncableSettingKeys` set to
   the real keys above; update the surrounding comment to note the keys are the
   real namespaced storage keys.
2. **`test/sync/sync_provider_test.dart`** — the round-trip test writes bare
   `theme_mode`; change it to the real key `appearance.theme_mode` so the test
   reflects the real app.
3. **`test/sync/payload_test.dart`** — update the bare `theme_mode` /
   `font_scale` literals used in payload build/parse/merge tests to the real
   keys (`appearance.theme_mode`, `appearance.font_scale`). The
   `not_allowed` / `weird` / `device_key` rejection cases stay as-is.

No production logic changes beyond the constant set — export, merge, and apply
already key off `syncableSettingKeys`.

## Testing

- Update and run the sync tests above.
- Add/extend a round-trip assertion covering a `tabs.*` and a `tts.*` key so the
  new namespaces are proven end-to-end (not just appearance).
- Run the full `flutter test` suite to confirm nothing else depended on the bare
  keys.
- Manual two-device check is a release gate per CLAUDE.md §6, noted for later.

## Risk / security

- Only non-sensitive preference keys are added; all remain outside secure
  storage. `neverSyncKeys` guard is untouched, so identity/lock keys still can
  never reach a payload (security-rules).
- No wire-format or protocol-version change; the payload shape is identical.
