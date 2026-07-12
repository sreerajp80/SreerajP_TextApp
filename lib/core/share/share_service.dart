import 'dart:io';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// A request to share one file's bytes. Captured as a value so tests can verify
/// exactly what would be shared without invoking the real share sheet.
class ShareFileRequest {
  final String name;
  final String mimeType;
  final Uint8List bytes;
  final String? subject;

  const ShareFileRequest({
    required this.name,
    required this.mimeType,
    required this.bytes,
    this.subject,
  });
}

/// The platform side of sharing, behind an interface so the [ShareService]
/// logic stays host-testable (arch §12). The real implementation calls
/// `share_plus`; tests inject a fake that records the request.
abstract class ShareLauncher {
  /// Writes each request's bytes to a temp file and opens the Android share
  /// sheet for them.
  Future<void> shareFiles(List<ShareFileRequest> requests, {String? subject});

  /// Shares raw text (no file).
  Future<void> shareText(String text, {String? subject});
}

/// Default [ShareLauncher] backed by `share_plus` (task 5.1).
class SharePlusLauncher implements ShareLauncher {
  /// Directory used to materialize bytes into temp files before sharing.
  final Directory tempDir;

  const SharePlusLauncher(this.tempDir);

  @override
  Future<void> shareFiles(
    List<ShareFileRequest> requests, {
    String? subject,
  }) async {
    final files = <XFile>[];
    for (final req in requests) {
      final path = '${tempDir.path}/${req.name}';
      final file = File(path);
      await file.writeAsBytes(req.bytes, flush: true);
      files.add(XFile(path, mimeType: req.mimeType, name: req.name));
    }
    await SharePlus.instance.share(ShareParams(files: files, subject: subject));
  }

  @override
  Future<void> shareText(String text, {String? subject}) async {
    await SharePlus.instance.share(ShareParams(text: text, subject: subject));
  }
}

/// Share-to-anywhere service (task 5.1).
///
/// Wraps the Android share sheet so any format can hand off a file or exported
/// output. Files leave the app only through this explicit user action (arch
/// §10 egress note). The platform call sits behind [ShareLauncher] so the
/// request-building logic is unit-tested.
class ShareService {
  final ShareLauncher _launcher;

  const ShareService(this._launcher);

  /// Shares a single file's [bytes] under [name] with [mimeType].
  Future<void> shareFileBytes({
    required String name,
    required String mimeType,
    required Uint8List bytes,
    String? subject,
  }) {
    return _launcher.shareFiles(
      [
        ShareFileRequest(
          name: name,
          mimeType: mimeType,
          bytes: bytes,
          subject: subject,
        ),
      ],
      subject: subject,
    );
  }

  /// Shares plain text with no attached file.
  Future<void> shareText(String text, {String? subject}) =>
      _launcher.shareText(text, subject: subject);
}
