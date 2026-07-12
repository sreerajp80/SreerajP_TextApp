import 'dart:typed_data';

import 'encoding.dart';

/// The verdict from a pre-save well-formedness check. Structured formats (JSON,
/// XML) register a real gate in later phases; plain text uses the default
/// always-valid gate (architecture.md §6).
class GateResult {
  final bool ok;

  /// A user-safe reason shown when [ok] is false (never includes file contents).
  final String? message;

  const GateResult.valid()
      : ok = true,
        message = null;
  const GateResult.invalid(this.message) : ok = false;
}

/// A check that runs **before** a save and can block it when the content is not
/// well-formed. The default accepts everything.
abstract class SaveGate {
  const SaveGate();

  GateResult check(String text);
}

/// The gate used by plain-text formats: never blocks.
class AlwaysValidGate extends SaveGate {
  const AlwaysValidGate();

  @override
  GateResult check(String text) => const GateResult.valid();
}

/// Where the saved bytes go. The real implementation writes through the SAF URI;
/// tests use a fake so the atomic behavior is verified with no device.
///
/// A target that can only be read from (a read-only grant) reports
/// [canOverwrite] `false`, so the saver offers **only** "Save as a copy"
/// (architecture.md §6).
abstract class SaveTarget {
  bool get canOverwrite;

  /// Overwrites the existing document with [bytes]. Implementations must be
  /// all-or-nothing: on failure the original bytes stay intact.
  Future<void> writeOverwrite(Uint8List bytes);

  /// Creates a new document named [suggestedName] with [bytes] and returns where
  /// it landed. Used for "Save as a copy".
  Future<SaveDestination> writeCopy(String suggestedName, Uint8List bytes);
}

/// The location a "Save as a copy" produced.
class SaveDestination {
  final String uri;
  final String displayName;

  const SaveDestination({required this.uri, required this.displayName});
}

/// What happened during a save attempt.
enum SaveOutcome {
  /// The original document was overwritten.
  saved,

  /// A new copy was written (original untouched).
  savedAsCopy,

  /// The pre-save gate rejected the content; nothing was written.
  blockedByGate,

  /// The target is read-only; the caller should offer "Save as a copy".
  readOnlyNeedsCopy,

  /// The user cancelled (e.g. dismissed the create-document picker).
  cancelled,

  /// The write failed; the original is intact.
  failed,
}

/// The result of a save, including a user-safe [message] and, for a copy, the
/// new [destination].
class SaveResult {
  final SaveOutcome outcome;
  final String? message;
  final SaveDestination? destination;

  const SaveResult(this.outcome, {this.message, this.destination});

  bool get succeeded =>
      outcome == SaveOutcome.saved || outcome == SaveOutcome.savedAsCopy;
}

/// Atomic save with a well-formedness gate (architecture.md §6, CLAUDE.md §3.5).
///
/// The flow: encode the text (preserving encoding + line endings) → run the gate
/// → hand the fully-materialized bytes to the target in one write. Because the
/// bytes are complete and verified before the target is touched, a failed encode
/// or a blocked gate never corrupts the original, and the target commits
/// all-or-nothing. Pure Dart — the SAF wiring lives in the target.
class AtomicSaver {
  final TextCodecService _codec;

  const AtomicSaver([this._codec = const TextCodecService()]);

  /// Saves [text] over the existing document in [target].
  ///
  /// Returns [SaveOutcome.blockedByGate] if [gate] rejects the content,
  /// [SaveOutcome.readOnlyNeedsCopy] if the target cannot overwrite, or
  /// [SaveOutcome.failed] if the write itself failed (original intact).
  Future<SaveResult> save(
    String text,
    SaveTarget target, {
    required TextEncodingType encoding,
    required LineEndingStyle lineEnding,
    SaveGate gate = const AlwaysValidGate(),
  }) async {
    final gateResult = gate.check(text);
    if (!gateResult.ok) {
      return SaveResult(SaveOutcome.blockedByGate, message: gateResult.message);
    }
    if (!target.canOverwrite) {
      return const SaveResult(SaveOutcome.readOnlyNeedsCopy);
    }
    final bytes = _codec.encode(text, encoding, lineEnding);
    try {
      await target.writeOverwrite(bytes);
      return const SaveResult(SaveOutcome.saved);
    } catch (e) {
      return SaveResult(
        SaveOutcome.failed,
        message: _safeError(e),
      );
    }
  }

  /// Saves [text] as a **new copy**, leaving the original untouched. This is the
  /// "save anyway as a copy" escape hatch, so it does **not** run the gate.
  Future<SaveResult> saveAsCopy(
    String text,
    SaveTarget target,
    String suggestedName, {
    required TextEncodingType encoding,
    required LineEndingStyle lineEnding,
  }) async {
    final bytes = _codec.encode(text, encoding, lineEnding);
    try {
      final dest = await target.writeCopy(suggestedName, bytes);
      return SaveResult(SaveOutcome.savedAsCopy, destination: dest);
    } catch (e) {
      return SaveResult(SaveOutcome.failed, message: _safeError(e));
    }
  }

  String _safeError(Object e) {
    // Never surface raw exception text that might carry a path or content; keep
    // it generic (security-rules: user-safe error messages).
    return 'Could not save the file.';
  }
}
