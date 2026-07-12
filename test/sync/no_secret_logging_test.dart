import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards security-rules: sync code must NEVER log payload contents, secrets,
/// keys, or the pairing code — not even in debug builds. This scans the sync
/// source for any logging call, which would need review before it is allowed.
void main() {
  test('lib/sync has no logging calls', () {
    final dir = Directory('lib/sync');
    expect(dir.existsSync(), isTrue, reason: 'lib/sync must exist');

    final offenders = <String>[];
    // Matches print(...), debugPrint(...), log(...), stdout/stderr writes.
    final logCall = RegExp(
      r'\b(print|debugPrint|log|stderr|stdout)\s*(\.|\()',
    );

    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        // Ignore comments.
        final trimmed = line.trimLeft();
        if (trimmed.startsWith('//') || trimmed.startsWith('*')) continue;
        if (logCall.hasMatch(line)) {
          offenders.add('${entity.path}:${i + 1}: ${line.trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'No logging is allowed in lib/sync (security-rules). Found:\n'
          '${offenders.join('\n')}',
    );
  });
}
