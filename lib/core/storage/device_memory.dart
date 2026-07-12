import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:system_info2/system_info2.dart';

import 'tab_cap.dart';

/// Reads total device RAM, used to compute the automatic tab cap
/// (architecture.md §8.3). Behind an interface so tests inject sample values;
/// the auto-cap maths lives in [autoTabCap] and is tested on its own.
abstract class DeviceMemory {
  /// Total physical RAM in bytes. Returns 0 if it cannot be read.
  Future<int> totalPhysicalBytes();

  /// Convenience: the automatic tab cap for this device.
  Future<int> autoTabCapForDevice() async => autoTabCap(await totalPhysicalBytes());
}

/// Real implementation backed by `system_info2`. Needs no Android permission.
class SystemInfoDeviceMemory implements DeviceMemory {
  @override
  Future<int> totalPhysicalBytes() async {
    try {
      return SysInfo.getTotalPhysicalMemory();
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<int> autoTabCapForDevice() async =>
      autoTabCap(await totalPhysicalBytes());
}

/// Fixed-value [DeviceMemory] for tests.
class FakeDeviceMemory implements DeviceMemory {
  final int bytes;

  const FakeDeviceMemory(this.bytes);

  @override
  Future<int> totalPhysicalBytes() async => bytes;

  @override
  Future<int> autoTabCapForDevice() async => autoTabCap(bytes);
}

final deviceMemoryProvider =
    Provider<DeviceMemory>((ref) => SystemInfoDeviceMemory());
