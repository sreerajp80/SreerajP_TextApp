import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/storage/device_memory.dart';
import 'package:text_data/core/storage/tab_cap.dart';

void main() {
  const gb = 1024 * 1024 * 1024;

  group('autoTabCap', () {
    test('maps sample RAM values to expected caps', () {
      expect(autoTabCap(2 * gb), 3);
      expect(autoTabCap(3 * gb), 4);
      expect(autoTabCap(4 * gb), 5);
      expect(autoTabCap(6 * gb), 6);
      expect(autoTabCap(8 * gb), 8);
      expect(autoTabCap(12 * gb), 10);
    });

    test('boundaries fall into the lower band', () {
      // Just over 2 GB moves up to the 3 GB band.
      expect(autoTabCap(2 * gb + 1), 4);
      // Just over 4 GB moves up to the 6 GB band.
      expect(autoTabCap(4 * gb + 1), 6);
    });

    test('zero or unknown RAM falls back to the smallest cap', () {
      expect(autoTabCap(0), 3);
      expect(autoTabCap(-1), 3);
    });
  });

  group('FakeDeviceMemory', () {
    test('reports the injected RAM and derived cap', () async {
      const mem = FakeDeviceMemory(6 * gb);
      expect(await mem.totalPhysicalBytes(), 6 * gb);
      expect(await mem.autoTabCapForDevice(), 6);
    });
  });
}
