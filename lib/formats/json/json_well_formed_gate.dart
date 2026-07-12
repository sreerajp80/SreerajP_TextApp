import '../../core/editor/atomic_saver.dart';
import 'json_parser.dart';

/// The pre-save well-formedness gate for JSON (task 8.5).
///
/// Registered with the [AtomicSaver] so a Save (overwrite) is **blocked** when
/// the buffer is not strict, well-formed JSON — the message names the error
/// line. "Save as a copy" bypasses the gate (that is the built-in escape hatch),
/// so the user can still keep a broken draft if they choose (CLAUDE.md §3.6).
class JsonWellFormedGate extends SaveGate {
  final JsonParser parser;

  const JsonWellFormedGate([this.parser = const JsonParser()]);

  @override
  GateResult check(String text) {
    final result = parser.parse(text);
    if (result.ok) return const GateResult.valid();
    return GateResult.invalid(
      'Not valid JSON (line ${result.errorLine}): ${result.errorMessage}',
    );
  }
}
