import 'dart:convert';
import 'dart:typed_data';

import 'package:sreerajp_textapp/core/security/biometric_service.dart';
import 'package:sreerajp_textapp/core/storage/secure_store.dart';
import 'package:sreerajp_textapp/core/vault/vault_constants.dart';
import 'package:sreerajp_textapp/core/vault/vault_crypto.dart';
import 'package:sreerajp_textapp/core/vault/vault_models.dart';

/// Service coordinating biometric authentication and AES-256-GCM encryption
/// for individual document vault files (`.txvault`).
class VaultService {
  final SecureStore secureStore;
  final BiometricService biometrics;

  VaultService({required this.secureStore, required this.biometrics});

  /// Checks if the device has biometric hardware and enrolled credentials.
  Future<bool> isBiometricsAvailable() => biometrics.isAvailable();

  /// Gets the existing Master Vault Key or creates a new one in the secure keystore.
  Future<Uint8List> getOrCreateMasterKey() async {
    final storedKeyBase64 = await secureStore.read(
      VaultConstants.masterVaultKeyStorageKey,
    );
    if (storedKeyBase64 != null && storedKeyBase64.isNotEmpty) {
      final decoded = base64.decode(storedKeyBase64);
      if (decoded.length == VaultConstants.keyLengthBytes) {
        return Uint8List.fromList(decoded);
      }
    }

    final newKey = VaultCrypto.generateMasterKey();
    await secureStore.write(
      VaultConstants.masterVaultKeyStorageKey,
      base64.encode(newKey),
    );
    return newKey;
  }

  /// Encrypts and locks a document into `.txvault` format.
  /// Prompts for biometric authentication before generating the ciphertext.
  Future<Uint8List> lockDocument({
    required VaultPayload payload,
    String reason = 'Authenticate to lock document in Biometric Vault',
  }) async {
    final bioAvailable = await biometrics.isAvailable();
    if (bioAvailable) {
      final authResult = await biometrics.authenticate(reason);
      if (authResult != BiometricResult.success) {
        throw const VaultCryptoException('Biometric authentication failed.');
      }
    }

    final masterKey = await getOrCreateMasterKey();
    return VaultCrypto.encryptVaultFile(payload, masterKey);
  }

  /// Decrypts a `.txvault` file.
  /// Prompts for biometric authentication before unlocking.
  Future<VaultPayload> unlockDocument({
    required Uint8List fileBytes,
    String reason = 'Authenticate to unlock Biometric Vault document',
  }) async {
    final bioAvailable = await biometrics.isAvailable();
    if (bioAvailable) {
      final authResult = await biometrics.authenticate(reason);
      if (authResult != BiometricResult.success) {
        throw const VaultCryptoException('Biometric authentication failed.');
      }
    }

    final masterKey = await getOrCreateMasterKey();
    return VaultCrypto.decryptVaultFile(fileBytes, masterKey);
  }

  /// Encrypts payload without UI prompt if key is already held in memory.
  Uint8List encryptWithKey(VaultPayload payload, Uint8List key) {
    return VaultCrypto.encryptVaultFile(payload, key);
  }

  /// Decrypts file bytes without UI prompt if key is already held in memory.
  VaultPayload decryptWithKey(Uint8List fileBytes, Uint8List key) {
    return VaultCrypto.decryptVaultFile(fileBytes, key);
  }
}
