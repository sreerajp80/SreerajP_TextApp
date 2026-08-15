import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:text_data/core/security/security_providers.dart';
import 'package:text_data/core/storage/secure_store.dart';
import 'package:text_data/core/vault/vault_service.dart';

/// Provider for the [SecureStore] instance backed by hardware Keystore.
final secureStoreProvider = Provider<SecureStore>(
  (ref) => FlutterSecureStore(),
);

/// Provider for [VaultService].
final vaultServiceProvider = Provider<VaultService>((ref) {
  final secureStore = ref.watch(secureStoreProvider);
  final biometrics = ref.watch(biometricServiceProvider);
  return VaultService(secureStore: secureStore, biometrics: biometrics);
});
