/// Maps total device RAM to the automatic maximum number of open tabs.
///
/// This is the "Auto — N tabs" value shown in Settings (architecture.md §8.3).
/// Kept as a pure function so it is fully testable without a device; Phase 2's
/// tab system reads it.
///
/// Bands (total physical RAM):
///   ≤ 2 GB  → 3 tabs
///   ≤ 3 GB  → 4 tabs
///   ≤ 4 GB  → 5 tabs
///   ≤ 6 GB  → 6 tabs
///   ≤ 8 GB  → 8 tabs
///   > 8 GB  → 10 tabs
///
/// A zero/unknown RAM value falls back to the smallest cap so a device we cannot
/// measure still behaves safely.
int autoTabCap(int totalPhysicalBytes) {
  const gb = 1024 * 1024 * 1024;
  if (totalPhysicalBytes <= 0) return 3;
  if (totalPhysicalBytes <= 2 * gb) return 3;
  if (totalPhysicalBytes <= 3 * gb) return 4;
  if (totalPhysicalBytes <= 4 * gb) return 5;
  if (totalPhysicalBytes <= 6 * gb) return 6;
  if (totalPhysicalBytes <= 8 * gb) return 8;
  return 10;
}
