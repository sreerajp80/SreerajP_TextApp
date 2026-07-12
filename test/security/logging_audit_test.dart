import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Whole-app guard for security-rules: "Never log file contents, payloads,
/// secrets, keys, or the pairing code — not even in debug builds."
///
/// `test/sync/no_secret_logging_test.dart` already forbids *any* logging inside
/// `lib/sync`. This test widens the net to the whole `lib/` tree and fails on
/// any new logging call unless it is on a short, reviewed allow-list. That way a
/// stray `print`/`debugPrint` added anywhere — near an editor buffer, a SAF URI,
/// a secure value — is caught by CI before it can leak.
void main() {
  // Reviewed, secret-free logging that is allowed to stay. Each entry is
  // `relativePath` -> a substring that must appear on the logging line. Keep
  // this list tiny; every addition needs a security review.
  const allowed = <String, String>{
    // Guarded by `kDebugMode`; prints only the app version/build mismatch, no
    // secret material. See config_service.dart.
    'lib/core/config/config_service.dart': 'ConfigService: version/build',
  };

  test('lib/ has no unreviewed logging calls', () {
    final dir = Directory('lib');
    expect(dir.existsSync(), isTrue, reason: 'lib/ must exist');

    // print(...), debugPrint(...), developer.log(...), stdout/stderr writes.
    // `print(` is matched only as a call (a `.` after it means it is a variable
    // named `print`, e.g. a PrintService — not the logging function).
    final logCall = RegExp(
      r'\bprint\s*\(|\bdebugPrint\s*\(|\bdeveloper\.log\s*\(|\bstderr\b|\bstdout\b',
    );

    final offenders = <String>[];
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final rel = entity.path.replaceAll(r'\', '/');
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final trimmed = line.trimLeft();
        // Skip comments.
        if (trimmed.startsWith('//') || trimmed.startsWith('*')) continue;
        if (!logCall.hasMatch(line)) continue;

        // Allow-listed? The reviewed snippet may sit a couple of lines below the
        // logging call (multi-line debugPrint), so scan a small window.
        final snippetForFile = allowed[rel];
        if (snippetForFile != null) {
          final window = lines
              .skip(i)
              .take(4)
              .join('\n');
          if (window.contains(snippetForFile)) continue;
        }

        offenders.add('$rel:${i + 1}: ${line.trim()}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Unreviewed logging found (security-rules: never log secrets, '
          'payloads, keys, file contents). Review and, if truly secret-free, '
          'add to the allow-list in this test:\n${offenders.join('\n')}',
    );
  });
}
