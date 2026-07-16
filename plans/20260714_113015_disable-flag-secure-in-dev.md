# Disable screenshot protection (FLAG_SECURE) in dev builds so scrcpy works

**Status:** completed

## What the issue is

The app turns on Android's `FLAG_SECURE` (blocks screenshots, screen-record, and
the recents thumbnail) while the "block screenshots" security setting is on
(default **on**), and it is forced on during sync pairing. `FLAG_SECURE` makes
scrcpy show a black screen, so during **remote development** the developer cannot
see the app. They also cannot reach the in-app toggle to turn it off, because that
screen is itself blacked out.

## The plan for the fix

Make `FLAG_SECURE` a no-op in **debug and profile builds only**, at the single
place that talks to the platform channel. Release/production builds are unchanged
and keep full screenshot protection.

- In `PlatformWindowSecurity.setSecure`, when `!kReleaseMode` (i.e. debug or
  profile), always request `secure = false` before calling the channel. In release
  the value is passed through unchanged.
- This one change covers **both** call sites (the global `ScreenshotProtector` and
  the forced-on sync pairing screen), because both go through this method.

This keeps production security intact (chosen approach: debug/profile only).

## Files to be changed

1. **Edit:** `lib/core/security/window_security.dart` — in
   `PlatformWindowSecurity.setSecure`, force `secure = false` when `!kReleaseMode`;
   add the `flutter/foundation.dart` import for `kReleaseMode`. Add a short comment
   explaining it is a development-only relaxation.

## Steps

1. Make the code change above.
2. `flutter analyze lib` — expect no issues.
3. Build a **debug** APK and install it on the connected device
   (moto g54 5G, Android 15) so scrcpy is no longer blacked out.
   - Note: a debug build uses debug signing, so the current release build must be
     uninstalled first. This clears app data (recent-file list, drafts, saved SAF
     permissions, and security settings). This is expected for a dev device.
4. Launch the app and confirm scrcpy shows the UI (no black screen), including
   after opening the sync pairing screen.
5. Write the change log to `change_log/`.

## Risk / notes

- Production is untouched: release builds still apply `FLAG_SECURE` exactly as
  before.
- The relaxation is tied to the build mode, not a runtime flag, so it cannot leak
  into a shipped release.
- Reminder: the in-app "block screenshots" setting still exists and still works;
  in debug/profile it simply has no effect on the window.
