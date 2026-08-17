import 'package:flutter_test/flutter_test.dart';
import 'package:sreerajp_textapp/core/privacy/pii_detector.dart';
import 'package:sreerajp_textapp/core/privacy/pii_mask_mode.dart';
import 'package:sreerajp_textapp/core/privacy/pii_scrubber.dart';

void main() {
  const detector = PiiDetector();
  const scrubber = PiiScrubber();

  group('PiiScrubber - Redact Mode', () {
    test('redacts detected emails and IP addresses', () {
      const text = 'User john@example.com connected from 192.168.1.50.';
      final scan = detector.scan(text);

      final scrubResult = scrubber.scrub(text, scan, mode: PiiMaskMode.redact);

      expect(scrubResult.scrubbedCount, 2);
      expect(
        scrubResult.scrubbedText,
        'User [REDACTED: EMAIL] connected from [REDACTED: IP_ADDRESS].',
      );
    });
  });

  group('PiiScrubber - Salted Hash Mode', () {
    test(
      'hashes identical values consistently and distinct values differently',
      () {
        const text =
            'Sender: test@example.com, CC: test@example.com, Other: other@example.com.';
        final scan = detector.scan(text);

        final scrubResult = scrubber.scrub(text, scan, mode: PiiMaskMode.hash);

        expect(scrubResult.scrubbedCount, 3);
        final replaced = scrubResult.scrubbedText;
        expect(replaced.contains('[HASH:'), true);

        // Verify identical values get identical hash tokens
        final hashTest = scrubResult.replacementMap['test@example.com']!;
        final hashOther = scrubResult.replacementMap['other@example.com']!;

        expect(hashTest, isNotNull);
        expect(hashOther, isNotNull);
        expect(hashTest != hashOther, true);
        expect(
          replaced,
          'Sender: $hashTest, CC: $hashTest, Other: $hashOther.',
        );
      },
    );
  });

  group('PiiScrubber - Pseudo-Anonymize Mode', () {
    test('replaces sensitive values with format-preserving dummy labels', () {
      const text =
          'Contact alice@example.com or bob@example.com at 192.168.1.1.';
      final scan = detector.scan(text);

      final scrubResult = scrubber.scrub(
        text,
        scan,
        mode: PiiMaskMode.anonymize,
      );

      expect(scrubResult.scrubbedCount, 3);
      expect(
        scrubResult.scrubbedText,
        'Contact user_01@anonymized.local or user_02@anonymized.local at 10.0.0.1.',
      );
    });
  });

  group('PiiScrubber - Partial Selection', () {
    test('masks only selected matches and preserves unselected matches', () {
      const text = 'Primary: first@example.com, Secondary: second@example.com.';
      final scan = detector.scan(text);
      expect(scan.totalCount, 2);

      // Unselect second email
      final modifiedMatches = [
        scan.matches[0], // selected = true
        scan.matches[1].copyWith(isSelected: false),
      ];
      final modifiedScan = scan.copyWith(matches: modifiedMatches);

      final scrubResult = scrubber.scrub(
        text,
        modifiedScan,
        mode: PiiMaskMode.redact,
      );

      expect(scrubResult.scrubbedCount, 1);
      expect(
        scrubResult.scrubbedText,
        'Primary: [REDACTED: EMAIL], Secondary: second@example.com.',
      );
    });
  });

  group('PiiScrubber - Empty inputs', () {
    test('handles empty text gracefully', () {
      final scan = detector.scan('');
      final scrubResult = scrubber.scrub('', scan);

      expect(scrubResult.scrubbedText, '');
      expect(scrubResult.scrubbedCount, 0);
    });
  });
}
