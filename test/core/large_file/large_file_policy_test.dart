import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/large_file/large_file_policy.dart';

void main() {
  const mb = 1024 * 1024;

  group('classifyBySize', () {
    test('small file is normal', () {
      expect(LargeFilePolicy.classifyBySize(0), FileSizeClass.normal);
      expect(LargeFilePolicy.classifyBySize(1024), FileSizeClass.normal);
      expect(
        LargeFilePolicy.classifyBySize(LargeFilePolicy.largeThresholdBytes - 1),
        FileSizeClass.normal,
      );
    });

    test('at the large threshold is large', () {
      expect(
        LargeFilePolicy.classifyBySize(LargeFilePolicy.largeThresholdBytes),
        FileSizeClass.large,
      );
      expect(LargeFilePolicy.classifyBySize(10 * mb), FileSizeClass.large);
      expect(
        LargeFilePolicy
            .classifyBySize(LargeFilePolicy.oversizedThresholdBytes - 1),
        FileSizeClass.large,
      );
    });

    test('at the oversized threshold is oversized', () {
      expect(
        LargeFilePolicy.classifyBySize(LargeFilePolicy.oversizedThresholdBytes),
        FileSizeClass.oversized,
      );
      expect(LargeFilePolicy.classifyBySize(200 * mb), FileSizeClass.oversized);
    });

    test('unknown or negative size falls back to normal', () {
      expect(LargeFilePolicy.classifyBySize(null), FileSizeClass.normal);
      expect(LargeFilePolicy.classifyBySize(-5), FileSizeClass.normal);
    });
  });

  group('isOversized', () {
    test('only true at or above the oversized threshold', () {
      expect(LargeFilePolicy.isOversized(null), isFalse);
      expect(LargeFilePolicy.isOversized(10 * mb), isFalse);
      expect(
        LargeFilePolicy.isOversized(LargeFilePolicy.oversizedThresholdBytes),
        isTrue,
      );
      expect(LargeFilePolicy.isOversized(60 * mb), isTrue);
    });
  });
}
