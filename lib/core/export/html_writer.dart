import 'dart:convert';
import 'dart:typed_data';

/// Builds a simple, self-contained HTML document from plain text (task 5.4).
///
/// The text is HTML-escaped and wrapped in a `<pre>` block so whitespace and
/// line breaks are preserved. No external assets, so the output opens
/// offline (CLAUDE.md §3.2).
class HtmlWriter {
  const HtmlWriter();

  Uint8List fromText(String text, {String? title}) {
    final safeTitle = _escape(title ?? 'Document');
    final body = _escape(text);
    final html = '''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$safeTitle</title>
<style>
  body { margin: 1rem; font-family: system-ui, sans-serif; }
  pre { white-space: pre-wrap; word-wrap: break-word; font-family: ui-monospace, monospace; }
</style>
</head>
<body>
<pre>$body</pre>
</body>
</html>
''';
    return Uint8List.fromList(utf8.encode(html));
  }

  String _escape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}
