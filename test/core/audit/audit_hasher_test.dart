import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/audit/audit_constants.dart';
import 'package:text_data/core/audit/audit_hasher.dart';

void main() {
  group('AuditHasher', () {
    test('produces deterministic 64-char hex SHA-256 hash', () {
      final hash1 = AuditHasher.computeEntryHash(
        previousHash: AuditConstants.genesisHash,
        eventType: AuditEventType.fileOpen,
        timestamp: 1000000,
        beforeHash: 'abc',
        afterHash: 'def',
        detail: 'Opened file',
      );

      final hash2 = AuditHasher.computeEntryHash(
        previousHash: AuditConstants.genesisHash,
        eventType: AuditEventType.fileOpen,
        timestamp: 1000000,
        beforeHash: 'abc',
        afterHash: 'def',
        detail: 'Opened file',
      );

      expect(hash1, hash2);
      expect(hash1.length, 64);
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(hash1), isTrue);
    });

    test('changing any single field alters the computed hash', () {
      final base = AuditHasher.computeEntryHash(
        previousHash: AuditConstants.genesisHash,
        eventType: AuditEventType.fileSave,
        timestamp: 1000,
        beforeHash: 'before_hash_val',
        afterHash: 'after_hash_val',
        detail: 'Saved document',
      );

      // Change previousHash
      expect(
        AuditHasher.computeEntryHash(
          previousHash:
              '1111111111111111111111111111111111111111111111111111111111111111',
          eventType: AuditEventType.fileSave,
          timestamp: 1000,
          beforeHash: 'before_hash_val',
          afterHash: 'after_hash_val',
          detail: 'Saved document',
        ),
        isNot(equals(base)),
      );

      // Change eventType
      expect(
        AuditHasher.computeEntryHash(
          previousHash: AuditConstants.genesisHash,
          eventType: AuditEventType.fileOpen,
          timestamp: 1000,
          beforeHash: 'before_hash_val',
          afterHash: 'after_hash_val',
          detail: 'Saved document',
        ),
        isNot(equals(base)),
      );

      // Change timestamp
      expect(
        AuditHasher.computeEntryHash(
          previousHash: AuditConstants.genesisHash,
          eventType: AuditEventType.fileSave,
          timestamp: 1001,
          beforeHash: 'before_hash_val',
          afterHash: 'after_hash_val',
          detail: 'Saved document',
        ),
        isNot(equals(base)),
      );

      // Change beforeHash
      expect(
        AuditHasher.computeEntryHash(
          previousHash: AuditConstants.genesisHash,
          eventType: AuditEventType.fileSave,
          timestamp: 1000,
          beforeHash: 'different_before_hash',
          afterHash: 'after_hash_val',
          detail: 'Saved document',
        ),
        isNot(equals(base)),
      );

      // Change afterHash
      expect(
        AuditHasher.computeEntryHash(
          previousHash: AuditConstants.genesisHash,
          eventType: AuditEventType.fileSave,
          timestamp: 1000,
          beforeHash: 'before_hash_val',
          afterHash: 'different_after_hash',
          detail: 'Saved document',
        ),
        isNot(equals(base)),
      );

      // Change detail
      expect(
        AuditHasher.computeEntryHash(
          previousHash: AuditConstants.genesisHash,
          eventType: AuditEventType.fileSave,
          timestamp: 1000,
          beforeHash: 'before_hash_val',
          afterHash: 'after_hash_val',
          detail: 'Different detail',
        ),
        isNot(equals(base)),
      );
    });

    test('handles null nullable fields consistently', () {
      final hashWithNulls = AuditHasher.computeEntryHash(
        previousHash: AuditConstants.genesisHash,
        eventType: AuditEventType.securityLockToggle,
        timestamp: 2000,
      );

      expect(hashWithNulls.length, 64);

      final verified = AuditHasher.verifyEntry(
        storedEntryHash: hashWithNulls,
        previousHash: AuditConstants.genesisHash,
        eventType: AuditEventType.securityLockToggle,
        timestamp: 2000,
      );
      expect(verified, isTrue);

      final wrongVerification = AuditHasher.verifyEntry(
        storedEntryHash: hashWithNulls,
        previousHash: AuditConstants.genesisHash,
        eventType: AuditEventType.securityLockToggle,
        timestamp: 2001,
      );
      expect(wrongVerification, isFalse);
    });
  });
}
