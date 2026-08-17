import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sreerajp_textapp/core/logging/app_logger.dart';

void main() {
  setUp(AppLogger.reset);
  tearDown(AppLogger.reset);

  group('AppLogger level gate', () {
    test('defaults to info before init, so a missed init stays quiet', () {
      expect(AppLogger.isInitialised, isFalse);
      expect(AppLogger.minimumLevel, LogLevel.info);
      expect(AppLogger.isEnabled(LogLevel.trace), isFalse);
      expect(AppLogger.isEnabled(LogLevel.debug), isFalse);
      expect(AppLogger.isEnabled(LogLevel.info), isTrue);
    });

    test('the dev flavor turns on trace and debug', () {
      AppLogger.init(flavor: 'dev');

      expect(AppLogger.isInitialised, isTrue);
      expect(AppLogger.minimumLevel, LogLevel.trace);
      for (final level in LogLevel.values) {
        expect(AppLogger.isEnabled(level), isTrue, reason: level.label);
      }
    });

    test('the prod flavor drops trace and debug but keeps info and above', () {
      AppLogger.init(flavor: 'prod');

      expect(AppLogger.minimumLevel, LogLevel.info);
      expect(AppLogger.isEnabled(LogLevel.trace), isFalse);
      expect(AppLogger.isEnabled(LogLevel.debug), isFalse);
      expect(AppLogger.isEnabled(LogLevel.info), isTrue);
      expect(AppLogger.isEnabled(LogLevel.warning), isTrue);
      expect(AppLogger.isEnabled(LogLevel.error), isTrue);
      expect(AppLogger.isEnabled(LogLevel.fatal), isTrue);
    });

    test('an unknown flavor name is treated as production', () {
      AppLogger.init(flavor: 'something-else');

      expect(AppLogger.minimumLevel, LogLevel.info);
      expect(AppLogger.isEnabled(LogLevel.debug), isFalse);
    });

    test('severity rises with seriousness', () {
      final ordered = LogLevel.values.map((l) => l.severity).toList();
      final sorted = [...ordered]..sort();
      expect(ordered, sorted);
    });
  });

  group('AppLogger output', () {
    test('every level is callable and none of them throws', () {
      AppLogger.init(flavor: 'dev');

      expect(() {
        AppLogger.trace('trace line');
        AppLogger.debug('debug line');
        AppLogger.info('info line');
        AppLogger.warning('warn line', error: StateError('x'));
        AppLogger.error(
          'error line',
          error: StateError('x'),
          stackTrace: StackTrace.current,
        );
        AppLogger.fatal(
          'fatal line',
          error: StateError('x'),
          stackTrace: StackTrace.current,
        );
      }, returnsNormally);
    });

    test('a suppressed line produces no output at all', () {
      AppLogger.init(flavor: 'prod');

      final printed = <String>[];
      runZoned(
        () => AppLogger.debug('this must not appear'),
        zoneSpecification: ZoneSpecification(
          print: (_, _, _, line) => printed.add(line),
        ),
      );

      expect(printed, isEmpty);
    });
  });
}
