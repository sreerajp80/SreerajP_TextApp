# Change log: disable screenshot protection (FLAG_SECURE) in dev builds

**Implements:** `plans/20260714_113015_disable-flag-secure-in-dev.md`
**Date:** 2026-07-14

## Problem

The app applies Android's `FLAG_SECURE` (blocks screenshots, screen-record, and
the recents thumbnail) when the "block screenshots" setting is on (default on), and
forces it on during sync pairing. `FLAG_SECURE` makes scrcpy show a black screen,
so during remote development the developer could not see the app — and could not
reach the in-app toggle to turn it off, because that screen was blacked out too.

## What was changed

- **`lib/core/security/window_security.dart`:** in
  `PlatformWindowSecurity.setSecure`, `FLAG_SECURE` is now forced off in
  **debug and profile** builds (`if (!kReleaseMode) secure = false;`). Added the
  `package:flutter/foundation.dart` import for `kReleaseMode`. This single choke
  point covers both call sites — the global `ScreenshotProtector` and the forced-on
  sync pairing screen — because both go through this method.

Release/production builds are unchanged and keep full screenshot protection. The
relaxation is tied to the compiled build mode, so it cannot leak into a shipped
release. The in-app "block screenshots" setting still exists; in debug/profile it
simply has no window effect.

## Verification

- `flutter analyze lib` -> **No issues found**.
- Built the flavored debug APK and installed the fresh `prod-debug` build
  (v1.6.1) on the device (moto g54 5G, Android 15), after uninstalling the previous
  build (debug signing differs; app data is cleared — expected on a dev device).
- Inspected the live window with `adb shell dumpsys window windows`: the
  `MainActivity` window flags are now
  `LAYOUT_IN_SCREEN LAYOUT_INSET_DECOR SPLIT_TOUCH HARDWARE_ACCELERATED
  DRAWS_SYSTEM_BAR_BACKGROUNDS` — **no `SECURE`** — confirming `FLAG_SECURE` is not
  applied. scrcpy can now mirror the screen.

## Note / gotcha found during testing

The project uses Android product flavors (`prod`, `dev`), so
`flutter build apk --debug` produces flavor-specific APKs
(`app-prod-debug.apk`, `app-dev-debug.apk`). A stale, flavor-less
`app-debug.apk` from an earlier build (2026-07-12, v1.5.0) was still present and was
installed by mistake first, which showed neither the fix nor the new icon. Installing
the correct fresh `app-prod-debug.apk` resolved it. For future device installs, use
the flavored APK (e.g. `app-prod-debug.apk`), not `app-debug.apk`.
