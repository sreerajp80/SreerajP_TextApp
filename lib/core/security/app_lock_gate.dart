import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shell/settings/security_settings.dart';
import 'app_lock_controller.dart';
import 'lock_screen.dart';
import 'security_providers.dart';

/// Wraps the app: shows the [LockScreen] whenever app-lock is enabled and the
/// session is locked, and otherwise shows [child]. Re-locks when the app goes to
/// the background so returning to it needs an unlock (task 13.2).
class AppLockGate extends ConsumerStatefulWidget {
  final Widget child;

  const AppLockGate({super.key, required this.child});

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Lock as soon as the app leaves the foreground, so the lock screen is
    // already up (and hidden by FLAG_SECURE) before it returns.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      ref.read(appLockControllerProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(
      securitySettingsProvider.select((s) => s.appLockEnabled),
    );
    final locked = ref.watch(
      appLockControllerProvider.select((s) => s.locked),
    );
    if (enabled && locked) {
      return const LockScreen();
    }
    return widget.child;
  }
}

/// Applies FLAG_SECURE (screenshot / recents / screen-record protection) to the
/// whole app while the "block screenshots" setting is on (task 13.2). The sync
/// pairing screen forces it on regardless; see `sync_host_screen.dart`.
class ScreenshotProtector extends ConsumerStatefulWidget {
  final Widget child;

  const ScreenshotProtector({super.key, required this.child});

  @override
  ConsumerState<ScreenshotProtector> createState() =>
      _ScreenshotProtectorState();
}

class _ScreenshotProtectorState extends ConsumerState<ScreenshotProtector> {
  bool? _applied;

  @override
  Widget build(BuildContext context) {
    final protect = ref.watch(
      securitySettingsProvider.select((s) => s.screenshotProtection),
    );
    if (_applied != protect) {
      _applied = protect;
      // Fire-and-forget; the platform wrapper swallows any channel error.
      ref.read(windowSecurityProvider).setSecure(protect);
    }
    return widget.child;
  }
}
