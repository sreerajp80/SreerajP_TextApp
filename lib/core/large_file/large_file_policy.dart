/// How big an opened file is, compared with the app's comfortable limits.
///
/// The app reads a file's size **before** opening it (from the SAF picker /
/// recents), so it can decide how to open the file without reading its bytes.
/// This is the single place those size limits live (Phase 10, arch §11).
enum FileSizeClass {
  /// Small enough for the normal full editor (the common case).
  normal,

  /// On the larger side but still fully editable — a hint band the UI may use
  /// to be cautious (e.g. warn before an expensive action). Behaves like
  /// [normal] for opening.
  large,

  /// Above the comfortable limit. Opened in a degraded, raw, paged, view-only
  /// mode with editing turned off, so memory stays bounded and the app never
  /// crashes (CLAUDE.md §3.4, arch §11).
  oversized,
}

/// One place to tune the large-file thresholds and to classify a file by size.
///
/// Kept as pure functions/constants so they are fully testable without a device.
class LargeFilePolicy {
  const LargeFilePolicy._();

  static const int _mb = 1024 * 1024;

  /// At or above this size a file is [FileSizeClass.large] (still editable).
  static const int largeThresholdBytes = 5 * _mb;

  /// At or above this size a file is [FileSizeClass.oversized] and opens in the
  /// degraded view-only mode (target comfortable limit ~50 MB, arch §11).
  static const int oversizedThresholdBytes = 50 * _mb;

  /// Classifies a file from its size in bytes.
  ///
  /// A `null` (unknown) size is treated as [FileSizeClass.normal] — the app
  /// cannot gate what it cannot measure, so it opens normally and relies on the
  /// never-crash parsers. This is a documented Way-1 limitation.
  static FileSizeClass classifyBySize(int? sizeBytes) {
    if (sizeBytes == null || sizeBytes < 0) return FileSizeClass.normal;
    if (sizeBytes >= oversizedThresholdBytes) return FileSizeClass.oversized;
    if (sizeBytes >= largeThresholdBytes) return FileSizeClass.large;
    return FileSizeClass.normal;
  }

  /// Whether a file of [sizeBytes] should open in the degraded view-only mode.
  static bool isOversized(int? sizeBytes) =>
      classifyBySize(sizeBytes) == FileSizeClass.oversized;
}
