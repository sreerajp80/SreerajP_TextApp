import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/editor/atomic_saver.dart';
import 'package:text_data/core/editor/encoding.dart';

/// A fake save target that keeps a "committed" copy so a test can prove the
/// original is intact after an interrupted write.
class FakeSaveTarget implements SaveTarget {
  @override
  final bool canOverwrite;

  /// Set to throw part-way through [writeOverwrite] without committing.
  final bool failMidWrite;

  Uint8List committed;
  SaveDestination? lastCopy;

  FakeSaveTarget({
    this.canOverwrite = true,
    this.failMidWrite = false,
    Uint8List? original,
  }) : committed = original ?? Uint8List.fromList(utf8.encode('ORIGINAL'));

  @override
  Future<void> writeOverwrite(Uint8List bytes) async {
    if (failMidWrite) {
      // Simulate an interruption before anything is committed.
      throw Exception('write interrupted');
    }
    committed = bytes;
  }

  @override
  Future<SaveDestination> writeCopy(String suggestedName, Uint8List bytes) async {
    lastCopy = SaveDestination(
      uri: 'content://new/$suggestedName',
      displayName: suggestedName,
    );
    return lastCopy!;
  }
}

/// A gate that rejects any text containing the word "BAD".
class _NoBadWordGate extends SaveGate {
  const _NoBadWordGate();
  @override
  GateResult check(String text) => text.contains('BAD')
      ? const GateResult.invalid('Content is not well-formed.')
      : const GateResult.valid();
}

void main() {
  const saver = AtomicSaver();

  test('a successful overwrite writes the encoded bytes', () async {
    final target = FakeSaveTarget();
    final result = await saver.save(
      'new content',
      target,
      encoding: TextEncodingType.utf8,
      lineEnding: LineEndingStyle.lf,
    );
    expect(result.outcome, SaveOutcome.saved);
    expect(utf8.decode(target.committed), 'new content');
  });

  test('an interrupted write leaves the original intact', () async {
    final target = FakeSaveTarget(failMidWrite: true);
    final before = target.committed;

    final result = await saver.save(
      'attempted new content',
      target,
      encoding: TextEncodingType.utf8,
      lineEnding: LineEndingStyle.lf,
    );

    expect(result.outcome, SaveOutcome.failed);
    // Original bytes untouched.
    expect(target.committed, before);
    expect(utf8.decode(target.committed), 'ORIGINAL');
  });

  test('a read-only target offers copy only', () async {
    final target = FakeSaveTarget(canOverwrite: false);
    final result = await saver.save(
      'x',
      target,
      encoding: TextEncodingType.utf8,
      lineEnding: LineEndingStyle.lf,
    );
    expect(result.outcome, SaveOutcome.readOnlyNeedsCopy);
    // Nothing was written.
    expect(utf8.decode(target.committed), 'ORIGINAL');
  });

  test('the gate blocks invalid content and writes nothing', () async {
    final target = FakeSaveTarget();
    final result = await saver.save(
      'this is BAD',
      target,
      encoding: TextEncodingType.utf8,
      lineEnding: LineEndingStyle.lf,
      gate: const _NoBadWordGate(),
    );
    expect(result.outcome, SaveOutcome.blockedByGate);
    expect(result.message, isNotNull);
    expect(utf8.decode(target.committed), 'ORIGINAL');
  });

  test('save as a copy skips the gate and does not touch the original',
      () async {
    final target = FakeSaveTarget();
    final result = await saver.saveAsCopy(
      'this is BAD but saved as a copy',
      target,
      'copy.txt',
      encoding: TextEncodingType.utf8,
      lineEnding: LineEndingStyle.lf,
    );
    expect(result.outcome, SaveOutcome.savedAsCopy);
    expect(result.destination?.displayName, 'copy.txt');
    expect(utf8.decode(target.committed), 'ORIGINAL');
  });
}
