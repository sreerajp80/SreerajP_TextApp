import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:text_data/core/audit/audit_constants.dart';
import 'package:text_data/core/audit/audit_repository.dart';
import 'package:text_data/core/storage/app_database.dart';

void main() {
  setUpAll(() => sqfliteFfiInit());

  late AppDatabase database;
  late AuditRepository repository;

  setUp(() async {
    database = await AppDatabase.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    repository = AuditRepository(database.db);
  });

  tearDown(() => database.close());

  group('AuditRepository', () {
    test(
      'empty repository returns empty verification result and genesis hash',
      () async {
        expect(await repository.count(), 0);
        expect(await repository.getLatestHash(), AuditConstants.genesisHash);

        final verification = await repository.verifyChain();
        expect(verification.isEmpty, isTrue);
        expect(verification.totalEntries, 0);
      },
    );

    test(
      'appends entries in a cryptographic chain and verifies successfully',
      () async {
        final entry1 = await repository.append(
          eventType: AuditEventType.fileOpen,
          timestamp: 1000,
          fileName: 'doc.txt',
          fileFingerprint: '100-abc',
          detail: 'Opened',
        );

        expect(entry1.id, 1);
        expect(entry1.previousHash, AuditConstants.genesisHash);
        expect(entry1.entryHash.length, 64);

        final entry2 = await repository.append(
          eventType: AuditEventType.fileSave,
          timestamp: 2000,
          fileName: 'doc.txt',
          fileFingerprint: '100-abc',
          beforeHash: 'hash_before',
          afterHash: 'hash_after',
          detail: 'Saved',
        );

        expect(entry2.id, 2);
        expect(entry2.previousHash, entry1.entryHash);

        final entry3 = await repository.append(
          eventType: AuditEventType.fileExport,
          timestamp: 3000,
          fileName: 'doc.txt',
          fileFingerprint: '100-abc',
          detail: 'Exported as PDF',
        );

        expect(entry3.id, 3);
        expect(entry3.previousHash, entry2.entryHash);
        expect(await repository.count(), 3);
        expect(await repository.getLatestHash(), entry3.entryHash);

        // Verify chain
        final verification = await repository.verifyChain();
        expect(verification.isVerified, isTrue);
        expect(verification.totalEntries, 3);
        expect(verification.corruptedEntryId, isNull);
      },
    );

    test('detects tampered entry hash in chain', () async {
      await repository.append(
        eventType: AuditEventType.fileOpen,
        timestamp: 1000,
        fileName: 'a.txt',
      );
      await repository.append(
        eventType: AuditEventType.fileSave,
        timestamp: 2000,
        fileName: 'a.txt',
      );
      await repository.append(
        eventType: AuditEventType.fileExport,
        timestamp: 3000,
        fileName: 'a.txt',
      );

      // Tamper with entry 2 in the database directly
      await database.db.update(
        'audit_log',
        {'detail': 'Tampered detail without updating hash'},
        where: 'id = ?',
        whereArgs: [2],
      );

      final verification = await repository.verifyChain();
      expect(verification.isCorrupted, isTrue);
      expect(verification.corruptedEntryId, 2);
      expect(verification.corruptedEntryIndex, 2);
      expect(verification.totalEntries, 3);
    });

    test('detects broken previous_hash linkage in chain', () async {
      await repository.append(
        eventType: AuditEventType.fileOpen,
        timestamp: 1000,
        fileName: 'a.txt',
      );
      await repository.append(
        eventType: AuditEventType.fileSave,
        timestamp: 2000,
        fileName: 'a.txt',
      );

      // Tamper with previous_hash of entry 2
      await database.db.update(
        'audit_log',
        {
          'previous_hash':
              '0000000000000000000000000000000000000000000000000000000000000000',
        },
        where: 'id = ?',
        whereArgs: [2],
      );

      final verification = await repository.verifyChain();
      expect(verification.isCorrupted, isTrue);
      expect(verification.corruptedEntryId, 2);
    });

    test('clear removes all entries', () async {
      await repository.append(
        eventType: AuditEventType.fileOpen,
        timestamp: 1000,
      );
      await repository.append(
        eventType: AuditEventType.fileSave,
        timestamp: 2000,
      );

      expect(await repository.count(), 2);
      await repository.clear();
      expect(await repository.count(), 0);
      expect(await repository.getLatestHash(), AuditConstants.genesisHash);
    });

    test(
      'clearForFingerprint removes only entries matching the fingerprint',
      () async {
        await repository.append(
          eventType: AuditEventType.fileOpen,
          timestamp: 1000,
          fileFingerprint: 'target-fp',
          fileName: 'target.txt',
        );
        await repository.append(
          eventType: AuditEventType.fileOpen,
          timestamp: 2000,
          fileFingerprint: 'other-fp',
          fileName: 'other.txt',
        );
        await repository.append(
          eventType: AuditEventType.fileSave,
          timestamp: 3000,
          fileFingerprint: 'target-fp',
          fileName: 'target.txt',
        );

        final deleted = await repository.clearForFingerprint('target-fp');
        expect(deleted, 2);

        final remaining = await repository.getAll();
        expect(remaining.length, 1);
        expect(remaining.first.fileFingerprint, 'other-fp');
      },
    );

    test(
      'getAll and getByFingerprint paginate and sort newest-first',
      () async {
        for (var i = 1; i <= 5; i++) {
          await repository.append(
            eventType: AuditEventType.fileOpen,
            timestamp: 1000 * i,
            fileName: 'file$i.txt',
            fileFingerprint: i <= 3 ? 'group-a' : 'group-b',
          );
        }

        final page1 = await repository.getAll(limit: 2, offset: 0);
        expect(page1.length, 2);
        expect(page1[0].fileName, 'file5.txt');
        expect(page1[1].fileName, 'file4.txt');

        final groupA = await repository.getByFingerprint('group-a');
        expect(groupA.length, 3);
        expect(groupA.first.fileName, 'file3.txt');
      },
    );
  });
}
