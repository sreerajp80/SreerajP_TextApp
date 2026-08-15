import 'package:xml/xml.dart';

/// One 1-tap repair the app can offer for a broken XML file (roadmap §4.3.3).
class XmlQuickFix {
  /// A stable id, so the UI picks its own label per fix.
  final String id;

  /// The repaired text this fix would produce.
  final String result;

  const XmlQuickFix({required this.id, required this.result});
}

/// Finds quick fixes for the common ways an XML file is broken
/// (roadmap §4.3.3).
///
/// The fixes are the ones a person would make by hand: close the tags that were
/// left open, escape a bare `&`, wrap several top-level elements in one root,
/// and clear junk sitting before the `<?xml …?>` declaration. Each is offered
/// only when it changes the text **and** leaves the document parseable — so a
/// tap never trades one error for another.
///
/// Note that the app's XML parser is forgiving: it accepts a bare `&` and text
/// before the declaration. Those two fixes therefore stay hidden until the file
/// really fails to parse, and usually earn their place through [fixAll] — the
/// app never nags about a file it already reads happily.
///
/// Pure Dart apart from the `xml` parser used to check the result, so every fix
/// is host-tested.
class XmlQuickFixes {
  const XmlQuickFixes._();

  static const String closeTags = 'closeTags';
  static const String escapeAmpersands = 'escapeAmpersands';
  static const String wrapRoot = 'wrapRoot';
  static const String trimBeforeDeclaration = 'trimBeforeDeclaration';

  /// The fixes worth offering for [source]. Empty when the text already parses.
  static List<XmlQuickFix> forSource(String source) {
    if (source.trim().isEmpty) return const [];
    if (_parses(source)) return const [];

    final candidates = <String, String Function(String)>{
      trimBeforeDeclaration: trimJunkBeforeDeclaration,
      escapeAmpersands: escapeBareAmpersands,
      closeTags: closeUnclosedTags,
      wrapRoot: wrapInSingleRoot,
    };

    final fixes = <XmlQuickFix>[];
    for (final entry in candidates.entries) {
      final result = entry.value(source);
      if (result == source) continue;
      // A fix that still leaves the document broken is not worth a tap.
      if (!_parses(result)) continue;
      fixes.add(XmlQuickFix(id: entry.key, result: result));
    }
    return fixes;
  }

  /// Applying every fix in turn, for a file with more than one problem.
  /// Returns null when the combination changes nothing or still does not parse.
  static XmlQuickFix? fixAll(String source) {
    if (source.trim().isEmpty) return null;
    if (_parses(source)) return null;
    var text = source;
    text = trimJunkBeforeDeclaration(text);
    text = escapeBareAmpersands(text);
    text = closeUnclosedTags(text);
    text = wrapInSingleRoot(text);
    if (text == source || !_parses(text)) return null;
    return XmlQuickFix(id: 'fixAll', result: text);
  }

  // --- individual fixes ----------------------------------------------------

  /// Closes any element left open, innermost first, at the end of the document.
  static String closeUnclosedTags(String source) {
    final open = _openElements(source);
    if (open.isEmpty) return source;
    final buffer = StringBuffer(source.trimRight());
    for (final name in open.reversed) {
      buffer.write('</$name>');
    }
    return buffer.toString();
  }

  /// Escapes an `&` that does not start an entity, which is the most common
  /// reason a hand-edited XML file stops parsing.
  static String escapeBareAmpersands(String source) {
    // An entity is `&name;`, `&#123;` or `&#x1F;` — anything else is a bare
    // ampersand that has to be written `&amp;`.
    final entity = RegExp(r'^&(#[0-9]+|#x[0-9A-Fa-f]+|[A-Za-z][A-Za-z0-9]*);');
    final out = StringBuffer();
    for (var i = 0; i < source.length; i++) {
      if (source[i] != '&') {
        out.write(source[i]);
        continue;
      }
      final rest = source.substring(i, (i + 12).clamp(0, source.length));
      out.write(entity.hasMatch(rest) ? '&' : '&amp;');
    }
    return out.toString();
  }

  /// Wraps several top-level elements in one `<root>`, which XML requires.
  /// Leaves the `<?xml …?>` declaration and any leading comment where they are.
  static String wrapInSingleRoot(String source) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) return source;

    // Keep the declaration outside the new root — it must stay first.
    var prologEnd = 0;
    final declaration = RegExp(r'^\s*<\?xml[^>]*\?>');
    final match = declaration.firstMatch(source);
    if (match != null) prologEnd = match.end;

    final body = source.substring(prologEnd);
    if (_topLevelElementCount(body) <= 1) return source;
    return '${source.substring(0, prologEnd)}\n<root>$body\n</root>';
  }

  /// Removes anything before the `<?xml …?>` declaration or the first tag —
  /// a stray BOM-like character or copied text that stops the parse at line 1.
  static String trimJunkBeforeDeclaration(String source) {
    final declaration = source.indexOf('<?xml');
    if (declaration > 0) return source.substring(declaration);
    if (declaration == 0) return source;
    final firstTag = source.indexOf('<');
    if (firstTag > 0 && source.substring(0, firstTag).trim().isNotEmpty) {
      return source.substring(firstTag);
    }
    return source;
  }

  // --- helpers -------------------------------------------------------------

  static bool _parses(String source) {
    try {
      XmlDocument.parse(source);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Element names still open at the end of [source], outermost first.
  ///
  /// A light scan rather than a parse — the document is broken, so the real
  /// parser has already refused it. Comments, CDATA, the declaration, and
  /// self-closing tags are skipped.
  static List<String> _openElements(String source) {
    final stack = <String>[];
    var i = 0;
    while (i < source.length) {
      final lt = source.indexOf('<', i);
      if (lt < 0) break;

      if (source.startsWith('<!--', lt)) {
        final end = source.indexOf('-->', lt + 4);
        i = end < 0 ? source.length : end + 3;
        continue;
      }
      if (source.startsWith('<![CDATA[', lt)) {
        final end = source.indexOf(']]>', lt + 9);
        i = end < 0 ? source.length : end + 3;
        continue;
      }
      if (source.startsWith('<?', lt) || source.startsWith('<!', lt)) {
        final end = source.indexOf('>', lt);
        i = end < 0 ? source.length : end + 1;
        continue;
      }

      final gt = source.indexOf('>', lt);
      if (gt < 0) break;
      final inner = source.substring(lt + 1, gt).trim();
      i = gt + 1;
      if (inner.isEmpty) continue;

      if (inner.startsWith('/')) {
        final name = inner.substring(1).trim();
        // Pop back to the matching open tag; a stray close tag is ignored.
        final at = stack.lastIndexOf(name);
        if (at >= 0) stack.removeRange(at, stack.length);
        continue;
      }
      if (inner.endsWith('/')) continue; // self-closing

      final name = _nameOf(inner);
      if (name.isNotEmpty) stack.add(name);
    }
    return stack;
  }

  /// How many elements sit at the top level of [source].
  static int _topLevelElementCount(String source) {
    var depth = 0;
    var count = 0;
    var i = 0;
    while (i < source.length) {
      final lt = source.indexOf('<', i);
      if (lt < 0) break;
      if (source.startsWith('<!--', lt)) {
        final end = source.indexOf('-->', lt + 4);
        i = end < 0 ? source.length : end + 3;
        continue;
      }
      if (source.startsWith('<?', lt) || source.startsWith('<!', lt)) {
        final end = source.indexOf('>', lt);
        i = end < 0 ? source.length : end + 1;
        continue;
      }
      final gt = source.indexOf('>', lt);
      if (gt < 0) break;
      final inner = source.substring(lt + 1, gt).trim();
      i = gt + 1;
      if (inner.isEmpty) continue;

      if (inner.startsWith('/')) {
        depth--;
        continue;
      }
      if (inner.endsWith('/')) {
        if (depth == 0) count++;
        continue;
      }
      if (depth == 0) count++;
      depth++;
    }
    return count;
  }

  static String _nameOf(String inner) {
    var end = 0;
    while (end < inner.length &&
        inner[end].trim().isNotEmpty &&
        inner[end] != '/') {
      end++;
    }
    return inner.substring(0, end);
  }
}
