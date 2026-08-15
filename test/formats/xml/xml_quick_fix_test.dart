import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/formats/xml/xml_quick_fix.dart';
import 'package:xml/xml.dart';

/// Guards the XML quick fixes (roadmap §4.3.3). A fix is only worth offering
/// when the result actually parses, so most tests check that too.
void main() {
  bool parses(String text) {
    try {
      XmlDocument.parse(text);
      return true;
    } catch (_) {
      return false;
    }
  }

  List<String> fixIds(String source) =>
      XmlQuickFixes.forSource(source).map((f) => f.id).toList();

  group('when fixes are offered', () {
    test('valid XML needs no fixes', () {
      expect(XmlQuickFixes.forSource('<a><b/></a>'), isEmpty);
    });

    test('empty text offers no fixes', () {
      expect(XmlQuickFixes.forSource(''), isEmpty);
      expect(XmlQuickFixes.forSource('   '), isEmpty);
    });

    test('a fix that would still leave the file broken is not offered', () {
      // Escaping the ampersand alone does not mend the missing close tag.
      expect(
        fixIds('<a>x & y'),
        isNot(contains(XmlQuickFixes.escapeAmpersands)),
      );
    });
  });

  group('closing unclosed tags', () {
    test('closes one open element', () {
      final fixed = XmlQuickFixes.closeUnclosedTags('<a><b>text');
      expect(fixed, '<a><b>text</b></a>');
      expect(parses(fixed), isTrue);
    });

    test('closes innermost first', () {
      expect(
        XmlQuickFixes.closeUnclosedTags('<a><b><c>'),
        '<a><b><c></c></b></a>',
      );
    });

    test('leaves a balanced document alone', () {
      expect(XmlQuickFixes.closeUnclosedTags('<a><b/></a>'), '<a><b/></a>');
    });

    test('does not count self-closing tags as open', () {
      expect(XmlQuickFixes.closeUnclosedTags('<a><b/>'), '<a><b/></a>');
    });

    test('ignores tags inside comments and CDATA', () {
      const source = '<a><!-- <b> --><![CDATA[<c>]]>';
      expect(XmlQuickFixes.closeUnclosedTags(source), '$source</a>');
    });

    test('skips the declaration', () {
      final fixed = XmlQuickFixes.closeUnclosedTags('<?xml version="1.0"?><a>');
      expect(fixed, '<?xml version="1.0"?><a></a>');
      expect(parses(fixed), isTrue);
    });

    test('is offered for a real unclosed file', () {
      expect(fixIds('<a><b>text'), contains(XmlQuickFixes.closeTags));
    });
  });

  group('escaping bare ampersands', () {
    test('escapes an ampersand that is not an entity', () {
      final fixed = XmlQuickFixes.escapeBareAmpersands('<a>x & y</a>');
      expect(fixed, '<a>x &amp; y</a>');
      expect(parses(fixed), isTrue);
    });

    test('leaves real entities alone', () {
      const source = '<a>&amp; &lt; &#160; &#x1F;</a>';
      expect(XmlQuickFixes.escapeBareAmpersands(source), source);
    });

    test('is not offered while the parser still accepts the file', () {
      // The app's XML parser tolerates a bare ampersand, so there is nothing to
      // warn about on its own — the fix earns its place inside fixAll instead.
      expect(fixIds('<a>x & y</a>'), isEmpty);
    });
  });

  group('wrapping several roots', () {
    test('wraps two top-level elements', () {
      final fixed = XmlQuickFixes.wrapInSingleRoot('<a/><b/>');
      expect(parses(fixed), isTrue);
      expect(fixed.contains('<root>'), isTrue);
    });

    test('keeps the declaration outside the new root', () {
      final fixed = XmlQuickFixes.wrapInSingleRoot(
        '<?xml version="1.0"?><a/><b/>',
      );
      expect(fixed.startsWith('<?xml version="1.0"?>'), isTrue);
      expect(parses(fixed), isTrue);
    });

    test('leaves a single-root document alone', () {
      expect(XmlQuickFixes.wrapInSingleRoot('<a><b/></a>'), '<a><b/></a>');
    });

    test('is offered for a two-root file', () {
      expect(fixIds('<a/><b/>'), contains(XmlQuickFixes.wrapRoot));
    });
  });

  group('junk before the declaration', () {
    test('removes text sitting before the declaration', () {
      final fixed = XmlQuickFixes.trimJunkBeforeDeclaration(
        'oops<?xml version="1.0"?><a/>',
      );
      expect(fixed, '<?xml version="1.0"?><a/>');
      expect(parses(fixed), isTrue);
    });

    test('removes text sitting before the first tag', () {
      final fixed = XmlQuickFixes.trimJunkBeforeDeclaration('junk<a/>');
      expect(fixed, '<a/>');
    });

    test('leaves plain leading whitespace alone', () {
      expect(XmlQuickFixes.trimJunkBeforeDeclaration('  <a/>'), '  <a/>');
    });

    test('is not offered while the parser still accepts the file', () {
      // Same as the ampersand fix: tidy, but not something to nag about until
      // the document actually fails to parse.
      expect(fixIds('oops<a/>'), isEmpty);
    });

    test('is offered when the junk is what breaks the file', () {
      // Two roots plus junk: trimming alone is not enough, but wrapping is, so
      // the offered set is honest about what each tap achieves.
      expect(fixIds('junk<a/><b/>'), contains(XmlQuickFixes.wrapRoot));
    });
  });

  group('fix everything at once', () {
    test('repairs a file with several problems', () {
      final fix = XmlQuickFixes.fixAll('<a>x & y<b>text');
      expect(fix, isNotNull);
      expect(parses(fix!.result), isTrue);
    });

    test('is not offered for valid XML', () {
      expect(XmlQuickFixes.fixAll('<a/>'), isNull);
    });

    test('a stray close tag does not crash the scanner', () {
      expect(() => XmlQuickFixes.forSource('</a>'), returnsNormally);
    });

    test('an unfinished tag does not crash the scanner', () {
      expect(() => XmlQuickFixes.forSource('<a'), returnsNormally);
    });
  });
}
