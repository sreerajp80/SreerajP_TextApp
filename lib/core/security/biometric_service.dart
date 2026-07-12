import 'package:local_auth/local_auth.dart';

/// Outcome of a biometric prompt, as a plain enum so callers and tests never
/// depend on the plugin's exception types.
enum BiometricResult {
  /// The user passed the biometric check.
  success,

  /// The check ran but did not pass (wrong finger/face, cancelled).
  failed,

  /// Biometrics are not set up or not available on this device.
  unavailable,
}

/// Fingerprint / face unlock for app-lock (task 13.2). Behind an interface so
/// the controller and tests can inject a fake. Biometric is a convenience only —
/// the PIN and recovery code remain the source of truth.
abstract class BiometricService {
  /// Whether the device supports and has enrolled biometrics.
  Future<bool> isAvailable();

  /// Prompts the user. [reason] is shown by the system dialog.
  Future<BiometricResult> authenticate(String reason);
}

/// Real implementation over the `local_auth` plugin.
class LocalAuthBiometricService implements BiometricService {
  final LocalAuthentication _auth;

  LocalAuthBiometricService([LocalAuthentication? auth])
      : _auth = auth ?? LocalAuthentication();

  @override
  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported && canCheck;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<BiometricResult> authenticate(String reason) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      return ok ? BiometricResult.success : BiometricResult.failed;
    } catch (_) {
      return BiometricResult.unavailable;
    }
  }
}

/// Always-unavailable service for hosts/tests without biometric hardware.
class UnavailableBiometricService implements BiometricService {
  const UnavailableBiometricService();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<BiometricResult> authenticate(String reason) async =>
      BiometricResult.unavailable;
}
