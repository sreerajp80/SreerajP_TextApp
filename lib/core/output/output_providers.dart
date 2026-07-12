import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../formats/json/json_exporter.dart';
import '../../formats/xml/xml_exporter.dart';
import '../editor/editor_providers.dart';
import '../export/csv_exporter.dart';
import '../export/export_service.dart';
import '../export/md_exporter.dart';
import '../export/txt_exporter.dart';
import '../print/print_service.dart';
import '../share/share_service.dart';
import '../tts/tts_service.dart';
import '../zip/zip_service.dart';

/// Dependency-injection providers for the Phase 5 output & utility services.
/// Mirrors `editor_providers.dart`: the services are pure/host-tested; these
/// providers only wire them into the widget tree. TXT is the first consumer;
/// later formats reuse the same instances.

/// Compress-for-sharing (task 5.2).
final zipServiceProvider = Provider<ZipService>((ref) => const ZipService());

/// Share sheet wrapper (task 5.1). Materializes bytes in the shared save temp
/// dir before handing files to `share_plus`.
final shareServiceProvider = Provider<ShareService>((ref) {
  // The launcher needs the temp dir; the dir is resolved async at first use.
  return ShareService(_DeferredShareLauncher(ref));
});

/// Print service (task 5.3).
final printServiceProvider =
    Provider<PrintService>((ref) => const PrintService(PrintingLauncher()));

/// The single export/convert service (task 5.4) with the TXT exporter
/// registered. Later phases add their own [FormatExporter]s here.
final exportServiceProvider = Provider<ExportService>(
  (ref) => ExportService([
    const TxtExporter(),
    const MarkdownExporter(),
    const JsonExporter(),
    const CsvExporter(),
    const XmlExporter(),
  ]),
);

/// Read-content-aloud module (task 5.5).
final ttsServiceProvider =
    Provider<TtsService>((ref) => TtsService(FlutterTtsEngine()));

/// Wraps the real `share_plus` launcher but resolves the temp dir lazily, so
/// building the provider does not force an async wait until a share happens.
class _DeferredShareLauncher implements ShareLauncher {
  final Ref _ref;
  const _DeferredShareLauncher(this._ref);

  Future<SharePlusLauncher> _real() async {
    final dir = await _ref.read(saveTempDirProvider.future);
    return SharePlusLauncher(dir);
  }

  @override
  Future<void> shareFiles(
    List<ShareFileRequest> requests, {
    String? subject,
  }) async {
    final launcher = await _real();
    await launcher.shareFiles(requests, subject: subject);
  }

  @override
  Future<void> shareText(String text, {String? subject}) async {
    final launcher = await _real();
    await launcher.shareText(text, subject: subject);
  }
}
