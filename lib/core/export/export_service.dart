import 'export_target.dart';
import 'format_exporter.dart';

/// The single conversion service (task 5.4).
///
/// Every format registers a [FormatExporter] here keyed by its format id. The
/// service is the one place the app asks "can this format produce that target,
/// and what are the bytes?". An unknown format or an unsupported target is
/// rejected cleanly with an [UnsupportedExportException] — never a crash
/// (CLAUDE.md §3.4).
class ExportService {
  final Map<String, FormatExporter> _exporters;

  ExportService(List<FormatExporter> exporters)
      : _exporters = {for (final e in exporters) e.formatId: e};

  /// The targets [formatId] can produce, or an empty set if the format is not
  /// registered.
  Set<ExportTarget> supportedTargets(String formatId) =>
      _exporters[formatId]?.supportedTargets ?? const {};

  /// Whether [formatId] can produce [target].
  bool canExport(String formatId, ExportTarget target) =>
      supportedTargets(formatId).contains(target);

  /// Builds the output for [target] from [content] using the exporter for
  /// [formatId].
  ///
  /// Throws [UnsupportedExportException] if the format is unknown or the target
  /// is not supported.
  Future<ExportResult> export(
    String formatId,
    ExportTarget target,
    TextContent content,
  ) async {
    final exporter = _exporters[formatId];
    if (exporter == null) {
      throw UnsupportedExportException(
        'This file type cannot be exported yet.',
      );
    }
    if (!exporter.supportedTargets.contains(target)) {
      throw UnsupportedExportException(
        'Cannot export ${content.displayName} to ${target.label}.',
      );
    }
    return exporter.export(target, content);
  }
}
