import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../metadata/file_metadata.dart';
import '../storage/saf_service.dart';
import 'atomic_saver.dart';
import 'encoding.dart';

/// Dependency-injection providers for the shared editor services built in
/// Phase 3. Phase 4 (TXT) is the first consumer; later format modules reuse the
/// same instances. The services themselves are pure Dart and unit-tested
/// directly — these providers only wire them into the widget tree.

/// The single [TextCodecService] used for all encode/decode across formats.
final textCodecServiceProvider =
    Provider<TextCodecService>((ref) => const TextCodecService());

/// The atomic saver (encode → gate → single verified write).
final atomicSaverProvider = Provider<AtomicSaver>(
  (ref) => AtomicSaver(ref.watch(textCodecServiceProvider)),
);

/// The metadata service, backed by the app's [SafService].
final metadataServiceProvider = Provider<MetadataService>(
  (ref) => MetadataService(ref.watch(safServiceProvider)),
);

/// The app's private temp directory, used by [SafSaveTarget] to materialize and
/// verify bytes locally before pushing them through a SAF URI. Cached for the
/// app's lifetime.
final saveTempDirProvider = FutureProvider<Directory>((ref) async {
  final support = await getApplicationSupportDirectory();
  final dir = Directory('${support.path}/save_tmp');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
});
