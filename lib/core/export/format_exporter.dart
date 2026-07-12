import 'export_target.dart';

/// A format module's export capability (task 5.4).
///
/// Each format (TXT now, MD/CSV/JSON/XML in later phases) registers one of
/// these with the [ExportService]. It declares which [ExportTarget]s it can
/// produce and builds the bytes for a requested target.
abstract class FormatExporter {
  /// The format id this exporter handles (e.g. `txt`).
  String get formatId;

  /// The targets this format can produce.
  Set<ExportTarget> get supportedTargets;

  /// Builds the output for [target] from [content]. Only called for a [target]
  /// in [supportedTargets]; the service guards that before calling.
  Future<ExportResult> export(ExportTarget target, TextContent content);
}
