import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sreerajp_textapp/core/audit/audit_constants.dart';
import 'package:sreerajp_textapp/core/audit/audit_export.dart';
import 'package:sreerajp_textapp/core/audit/audit_repository.dart';
import 'package:sreerajp_textapp/core/audit/audit_service.dart';
import 'package:sreerajp_textapp/core/storage/app_database.dart';
import 'package:sreerajp_textapp/core/storage/secure_store.dart';

void main() {
  setUpAll(() => sqfliteFfiInit());

  late AppDatabase database;
  late AuditRepository repository;
  late AuditService service;
  late InMemorySecureStore secureStore;

  setUp(() async {
    database = await AppDatabase.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    repository = AuditRepository(database.db);
    service = AuditService(repository: repository, enabled: true);
    secureStore = InMemorySecureStore();
  });

  tearDown(() => database.close());

  group('AuditExport', () {
    test(
      'builds signed JSON certificate with correct metadata and HMAC',
      () async {
        await service.record(
          eventType: AuditEventType.fileOpen,
          fileName: 'report.txt',
          fileFingerprint: '10-abc',
          detail: 'Opened file',
        );
        await service.record(
          eventType: AuditEventType.fileSave,
          fileName: 'report.txt',
          fileFingerprint: '10-abc',
          beforeHash: 'hash1',
          afterHash: 'hash2',
          detail: 'Saved changes',
        );

        final certJson = await AuditExport.buildCertificate(
          service: service,
          secureStore: secureStore,
          appName: 'TextData',
          appVersion: '1.7.1',
        );

        expect(certJson, isNotEmpty);
        final cert = jsonDecode(certJson) as Map<String, dynamic>;

        expect(cert['version'], 1);
        expect(cert['appName'], 'TextData');
        expect(cert['appVersion'], '1.7.1');
        expect(cert['chainStatus'], 'verified');
        expect(cert['totalEntries'], 2);
        expect(cert['entries'], isA<List>());
        expect((cert['entries'] as List).length, 2);
        expect(cert['hmac'], isA<String>());
        expect((cert['hmac'] as String).length, 64);

        // Verify certificate with the same secure store
        final valid = await AuditExport.verifyCertificate(
          certificateJson: certJson,
          secureStore: secureStore,
        );
        expect(valid, isTrue);
      },
    );

    test('certificate verification fails if entries are modified', () async {
      await service.record(
        eventType: AuditEventType.fileOpen,
        fileName: 'report.txt',
      );

      final certJson = await AuditExport.buildCertificate(
        service: service,
        secureStore: secureStore,
        appName: 'TextData',
        appVersion: '1.7.1',
      );

      final cert = jsonDecode(certJson) as Map<String, dynamic>;
      // Tamper with entries in the certificate
      (cert['entries'] as List)[0]['detail'] = 'Tampered text';
      final tamperedJson = jsonEncode(cert);

      final valid = await AuditExport.verifyCertificate(
        certificateJson: tamperedJson,
        secureStore: secureStore,
      );
      expect(valid, isFalse);
    });

    test(
      'certificate verification fails with a different secure store key',
      () async {
        await service.record(
          eventType: AuditEventType.fileOpen,
          fileName: 'report.txt',
        );

        final certJson = await AuditExport.buildCertificate(
          service: service,
          secureStore: secureStore,
          appName: 'TextData',
          appVersion: '1.7.1',
        );

        final otherSecureStore = InMemorySecureStore();
        await otherSecureStore.write(
          AuditExport.signingKeyStorageKey,
          '0000000000000000000000000000000000000000000000000000000000000000',
        );

        final valid = await AuditExport.verifyCertificate(
          certificateJson: certJson,
          secureStore: otherSecureStore,
        );
        expect(valid, isFalse);
      },
    );
  });
}
