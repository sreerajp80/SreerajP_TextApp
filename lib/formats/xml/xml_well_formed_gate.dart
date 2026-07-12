import '../../core/editor/atomic_saver.dart';
import 'xml_parser.dart';

/// The pre-save well-formedness gate for XML (task 9.5).
///
/// Registered with the [AtomicSaver] so a Save (overwrite) is **blocked** when
/// the buffer is not well-formed XML — the message names the error line. "Save
/// as a copy" bypasses the gate (the built-in escape hatch), so the user can
/// still keep a broken draft if they choose (CLAUDE.md §3.6).
class XmlWellFormedGate extends SaveGate {
  final XmlDocumentParser parser;

  const XmlWellFormedGate([this.parser = const XmlDocumentParser()]);

  @override
  GateResult check(String text) {
    final result = parser.parse(text);
    if (result.ok) return const GateResult.valid();
    return GateResult.invalid(
      'Not well-formed XML (line ${result.errorLine}): ${result.errorMessage}',
    );
  }
}
