import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:text_data/core/audit/audit_constants.dart';
import 'package:text_data/core/audit/audit_repository.dart';
import 'package:text_data/core/audit/audit_service.dart';
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

  group('AuditService', () {
    test('records entries when enabled', () async {
      final service = AuditService(repository: repository, enabled: true);
      expect(service.isEnabled, isTrue);

      final entry = await service.record(
        eventType: AuditEventType.fileOpen,
        fileName: 'test.txt',
        fileFingerprint: '100-abc',
        detail: 'Opened file',
      );

      expect(entry, isNotNull);
      expect(entry!.fileName, 'test.txt');
      expect(await service.entryCount(), 1);

      final entries = await service.getEntries();
      expect(entries.length, 1);
      expect(entries.first.eventType, AuditEventType.fileOpen);
    });

    test('no-ops when disabled', () async {
      final service = AuditService(repository: repository, enabled: false);
      expect(service.isEnabled, isFalse);

      final entry = await service.record(
        eventType: AuditEventType.fileOpen,
        fileName: 'test.txt',
      );

      expect(entry, isNull);
      expect(await service.entryCount(), 0);
    });

    test('clearLog clears and appends auditCleared genesis entry', () async {
      final service = AuditService(repository: repository, enabled: true);
      await service.record(
        eventType: AuditEventType.fileOpen,
        fileName: 'a.txt',
      );
      await service.record(
        eventType: AuditEventType.fileSave,
        fileName: 'a.txt',
      );
      expect(await service.entryCount(), 2);

      await service.clearLog();

      expect(await service.entryCount(), 1);
      final entries = await service.getEntries();
      expect(entries.first.eventType, AuditEventType.auditCleared);
      expect(entries.first.previousHash, AuditConstants.genesisHash);

      final verification = await service.verifyChain();
      expect(verification.isVerified, isTrue);
    });

    test('clearForFingerprint removes entries for target file only', () async {
      final service = AuditService(repository: repository, enabled: true);
      await service.record(
        eventType: AuditEventType.fileOpen,
        fileName: 'a.txt',
        fileFingerprint: 'fp-a',
      );
      await service.record(
        eventType: AuditEventType.fileOpen,
        fileName: 'b.txt',
        fileFingerprint: 'fp-b',
      );

      await service.clearForFingerprint('fp-a');

      final remaining = await service.getEntries();
      expect(remaining.length, 1);
      expect(remaining.first.fileFingerprint, 'fp-b');
    });
  });
}
