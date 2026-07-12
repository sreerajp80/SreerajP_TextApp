import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/key_value_store.dart';
import 'app_lock_repository.dart';
import 'biometric_service.dart';
import 'window_security.dart';

/// Screenshot-protection window flag. Real platform channel by default; tests
/// override with a fake to assert `setSecure` calls.
final windowSecurityProvider = Provider<WindowSecurity>(
  (ref) => const PlatformWindowSecurity(),
);

/// Biometric unlock service. Real `local_auth` by default; tests override.
final biometricServiceProvider = Provider<BiometricService>(
  (ref) => LocalAuthBiometricService(),
);

/// App-lock secrets repository, built on the shared [KeyValueStore].
final appLockRepositoryProvider = Provider<AppLockRepository>(
  (ref) => AppLockRepository(ref.read(keyValueStoreSyncProvider)),
);
