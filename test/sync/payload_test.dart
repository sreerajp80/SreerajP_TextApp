import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/sync/payload.dart';
import 'package:text_data/sync/sync_constants.dart';

void main() {
  group('build', () {
    test('includes only chosen categories and allow-listed settings', () {
      final payload = SyncPayload.build(
        syncMode: SyncConstants.syncModeFull,
        categories: [SyncConstants.categoryFavorites],
        recordsByCategory: {
          SyncConstants.categoryFavorites: [
            {'fingerprint': 'fp1', 'displayName': 'a'}
          ],
        },
        settings: {'appearance.theme_mode': 'dark', 'not_allowed': 'x'},
      );
      expect(payload.records.keys, [SyncConstants.categoryFavorites]);
      expect(payload.settings.containsKey('appearance.theme_mode'), isTrue);
      expect(payload.settings.containsKey('not_allowed'), isFalse);
    });

    test('refuses to build with a protected key in settings', () {
      expect(
        () => SyncPayload.build(
          syncMode: SyncConstants.syncModeFull,
          categories: const [],
          recordsByCategory: const {},
          settings: {'device_key': 'leak'},
        ),
        throwsA(isA<PayloadException>()),
      );
    });
  });

  group('validateAndParse', () {
    String wrap(Map<String, Object?> extra) => jsonEncode({
          SyncConstants.keyApp: SyncConstants.appId,
          SyncConstants.keyPayloadVersion: SyncConstants.payloadVersion,
          SyncConstants.keySyncMode: SyncConstants.syncModeFull,
          ...extra,
        });

    test('parses a well-formed payload', () {
      final payload = SyncPayload.validateAndParse(wrap({
        SyncConstants.keyRecords: {
          SyncConstants.categoryFavorites: [
            {'fingerprint': 'fp1'}
          ],
        },
        SyncConstants.keySettings: {'appearance.theme_mode': 'dark'},
      }));
      expect(payload.records[SyncConstants.categoryFavorites], hasLength(1));
      expect(payload.settings['appearance.theme_mode'], 'dark');
    });

    test('rejects a payload from a different app', () {
      final json = jsonEncode({
        SyncConstants.keyApp: 'other_app',
        SyncConstants.keyPayloadVersion: 1,
        SyncConstants.keySyncMode: SyncConstants.syncModeFull,
      });
      expect(() => SyncPayload.validateAndParse(json),
          throwsA(isA<PayloadException>()));
    });

    test('rejects malformed JSON', () {
      expect(() => SyncPayload.validateAndParse('{not json'),
          throwsA(isA<PayloadException>()));
    });

    test('rejects an unknown sync mode', () {
      final json = jsonEncode({
        SyncConstants.keyApp: SyncConstants.appId,
        SyncConstants.keyPayloadVersion: 1,
        SyncConstants.keySyncMode: 'sideways',
      });
      expect(() => SyncPayload.validateAndParse(json),
          throwsA(isA<PayloadException>()));
    });

    test('caps records per category', () {
      final tooMany = List.generate(
        SyncConstants.maxRecordsPerCategory + 1,
        (i) => {'fingerprint': 'fp$i'},
      );
      expect(
        () => SyncPayload.validateAndParse(wrap({
          SyncConstants.keyRecords: {SyncConstants.categoryFavorites: tooMany},
        })),
        throwsA(isA<PayloadException>()),
      );
    });

    test('rejects an over-long field', () {
      final big = 'x' * (SyncConstants.maxFieldLength + 1);
      expect(
        () => SyncPayload.validateAndParse(wrap({
          SyncConstants.keyRecords: {
            SyncConstants.categoryFavorites: [
              {'fingerprint': 'fp1', 'displayName': big}
            ],
          },
        })),
        throwsA(isA<PayloadException>()),
      );
    });

    test('drops unknown categories and unknown settings, keeps allow-listed',
        () {
      final payload = SyncPayload.validateAndParse(wrap({
        SyncConstants.keyRecords: {
          'ghosts': [
            {'x': 1}
          ],
          SyncConstants.categoryFavorites: [
            {'fingerprint': 'fp1'}
          ],
        },
        SyncConstants.keySettings: {'appearance.theme_mode': 'dark', 'weird': 1},
      }));
      expect(payload.records.containsKey('ghosts'), isFalse);
      expect(payload.records.containsKey(SyncConstants.categoryFavorites),
          isTrue);
      expect(payload.settings.containsKey('weird'), isFalse);
      expect(payload.settings['appearance.theme_mode'], 'dark');
    });

    test('rejects a payload trying to push a protected setting', () {
      expect(
        () => SyncPayload.validateAndParse(wrap({
          SyncConstants.keySettings: {'device_key': 'leak'},
        })),
        throwsA(isA<PayloadException>()),
      );
    });
  });

  group('mergeRecords (add-only, client-wins)', () {
    test('skips records the receiver already has', () {
      final result = mergeRecords(
        category: SyncConstants.categoryFavorites,
        records: [
          {'fingerprint': 'fp1'},
          {'fingerprint': 'fp2'},
        ],
        existingKeys: {'fp1'},
      );
      expect(result.added, 1);
      expect(result.kept, 1);
      expect(result.toAdd.single['fingerprint'], 'fp2');
    });

    test('bookmark natural key uses fingerprint+position+label', () {
      final result = mergeRecords(
        category: SyncConstants.categoryBookmarks,
        records: [
          {'fingerprint': 'fp1', 'position': 10, 'label': 'A'},
          {'fingerprint': 'fp1', 'position': 20, 'label': 'B'},
        ],
        existingKeys: {'fp1|10|A'},
      );
      expect(result.added, 1);
      expect(result.kept, 1);
    });

    test('skips malformed records (no natural key)', () {
      final result = mergeRecords(
        category: SyncConstants.categoryFavorites,
        records: [
          {'no_fingerprint': true},
        ],
        existingKeys: const {},
      );
      expect(result.added, 0);
    });
  });

  group('mergeSettings', () {
    test('full sync applies everything (overwrite)', () {
      final result = mergeSettings(
        incoming: {'appearance.theme_mode': 'dark', 'appearance.font_scale': 1.2},
        existingKeys: {'appearance.theme_mode'},
        isFull: true,
      );
      expect(result.applied, 2);
      expect(result.kept, 0);
    });

    test('incremental applies fill-only', () {
      final result = mergeSettings(
        incoming: {'appearance.theme_mode': 'dark', 'appearance.font_scale': 1.2},
        existingKeys: {'appearance.theme_mode'},
        isFull: false,
      );
      expect(result.applied, 1);
      expect(result.kept, 1);
      expect(result.toApply.containsKey('appearance.font_scale'), isTrue);
      expect(result.toApply.containsKey('appearance.theme_mode'), isFalse);
    });
  });
}
