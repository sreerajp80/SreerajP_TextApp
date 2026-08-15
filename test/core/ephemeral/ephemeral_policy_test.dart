import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/ephemeral/ephemeral_models.dart';
import 'package:text_data/core/ephemeral/ephemeral_policy.dart';

EphemeralMark markAt(int? expiry, {bool burnAfterOutput = false}) {
  return EphemeralMark(
    tabId: 'tab-1',
    fingerprint: '12-abc',
    displayName: 'notes.txt',
    expiresAtMillis: expiry,
    burnAfterOutput: burnAfterOutput,
  );
}

void main() {
  group('remaining', () {
    test('counts down towards the expiry', () {
      final mark = markAt(10_000);
      expect(
        EphemeralPolicy.remaining(mark, 4_000),
        const Duration(seconds: 6),
      );
    });

    test('is null when the mark has no timer', () {
      expect(EphemeralPolicy.remaining(markAt(null), 4_000), isNull);
    });

    test('never goes negative once the expiry has passed', () {
      expect(EphemeralPolicy.remaining(markAt(1_000), 9_000), Duration.zero);
    });

    test('a clock that jumps backwards only lengthens the life', () {
      final mark = markAt(10_000);
      // Device clock moves back an hour mid-session.
      final left = EphemeralPolicy.remaining(mark, -3_590_000);
      expect(left, isNotNull);
      expect(left!.isNegative, isFalse);
      expect(left.inMilliseconds, greaterThan(0));
    });
  });

  group('isExpired', () {
    test('false before the expiry', () {
      expect(EphemeralPolicy.isExpired(markAt(10_000), 9_999), isFalse);
    });

    test('true exactly at the expiry', () {
      expect(EphemeralPolicy.isExpired(markAt(10_000), 10_000), isTrue);
    });

    test('a mark with no timer never expires on its own', () {
      expect(EphemeralPolicy.isExpired(markAt(null), 1 << 40), isFalse);
    });
  });

  group('expired', () {
    test('picks out only the marks that are due', () {
      final marks = [
        markAt(5_000),
        markAt(50_000),
        markAt(null, burnAfterOutput: true),
      ];
      final due = EphemeralPolicy.expired(marks, 6_000);
      expect(due.length, 1);
      expect(due.single.expiresAtMillis, 5_000);
    });
  });

  group('formatRemaining', () {
    test('shows m:ss under an hour', () {
      expect(
        EphemeralPolicy.formatRemaining(const Duration(minutes: 4, seconds: 7)),
        '4:07',
      );
    });

    test('pads the seconds', () {
      expect(
        EphemeralPolicy.formatRemaining(const Duration(seconds: 9)),
        '0:09',
      );
    });

    test('shows hours and minutes from an hour up', () {
      expect(
        EphemeralPolicy.formatRemaining(
          const Duration(hours: 3, minutes: 12, seconds: 40),
        ),
        '3h 12m',
      );
    });

    test('drops the minutes when they are zero', () {
      expect(EphemeralPolicy.formatRemaining(const Duration(hours: 24)), '24h');
    });

    test('is empty when there is no timer', () {
      expect(EphemeralPolicy.formatRemaining(null), '');
    });
  });

  group('isUrgent', () {
    test('true in the last minute', () {
      expect(EphemeralPolicy.isUrgent(const Duration(seconds: 60)), isTrue);
      expect(EphemeralPolicy.isUrgent(Duration.zero), isTrue);
    });

    test('false above a minute, and for no timer', () {
      expect(EphemeralPolicy.isUrgent(const Duration(seconds: 61)), isFalse);
      expect(EphemeralPolicy.isUrgent(null), isFalse);
    });
  });

  group('expiryFor', () {
    test('adds the chosen lifetime to now', () {
      const option = EphemeralOption(duration: EphemeralDuration.oneHour);
      expect(EphemeralPolicy.expiryFor(option, 1_000), 1_000 + 3_600_000);
    });

    test('uses the typed minutes for a custom choice', () {
      const option = EphemeralOption(
        duration: EphemeralDuration.custom,
        customMinutes: 3,
      );
      expect(EphemeralPolicy.expiryFor(option, 0), 180_000);
    });

    test('is null for "no timer"', () {
      const option = EphemeralOption(duration: EphemeralDuration.none);
      expect(EphemeralPolicy.expiryFor(option, 1_000), isNull);
    });

    test('a custom value of zero means no timer, not instant death', () {
      const option = EphemeralOption(
        duration: EphemeralDuration.custom,
        customMinutes: 0,
      );
      expect(EphemeralPolicy.expiryFor(option, 1_000), isNull);
    });
  });

  group('EphemeralOption', () {
    test('is a no-op only with neither a timer nor burn-after-output', () {
      const nothing = EphemeralOption(
        duration: EphemeralDuration.none,
        burnAfterOutput: false,
      );
      expect(nothing.isNoOp, isTrue);

      const burnOnly = EphemeralOption(
        duration: EphemeralDuration.none,
        burnAfterOutput: true,
      );
      expect(burnOnly.isNoOp, isFalse);

      const timerOnly = EphemeralOption(duration: EphemeralDuration.fourHours);
      expect(timerOnly.isNoOp, isFalse);
    });

    test('an unknown stored value falls back to one hour', () {
      expect(
        EphemeralDuration.fromPrefValue('something-else'),
        EphemeralDuration.oneHour,
      );
      expect(EphemeralDuration.fromPrefValue(null), EphemeralDuration.oneHour);
    });

    test('round-trips through its stored value', () {
      for (final d in EphemeralDuration.values) {
        expect(EphemeralDuration.fromPrefValue(d.prefValue), d);
      }
    });
  });
}
