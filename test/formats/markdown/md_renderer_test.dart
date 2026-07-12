import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/formats/markdown/md_parse.dart';
import 'package:text_data/formats/markdown/md_renderer.dart';

Future<void> _pump(WidgetTester tester, String source) async {
  final nodes = MdParse.parseBlocks(source, withMath: true);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: MarkdownRenderer(nodes: nodes),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders headings and paragraph text', (tester) async {
    await _pump(tester, '# Hello World\n\nSome paragraph text.');
    expect(find.textContaining('Hello World'), findsOneWidget);
    expect(find.textContaining('paragraph text'), findsOneWidget);
  });

  testWidgets('renders a GFM table', (tester) async {
    await _pump(
      tester,
      '| Name | Age |\n| --- | --- |\n| Ann | 30 |\n| Bob | 25 |',
    );
    expect(find.byType(Table), findsOneWidget);
    expect(find.textContaining('Ann'), findsOneWidget);
  });

  testWidgets('renders task-list checkboxes', (tester) async {
    await _pump(tester, '- [x] done\n- [ ] todo');
    expect(find.byIcon(Icons.check_box), findsOneWidget);
    expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
  });

  testWidgets('a mermaid block falls back to a plain code block',
      (tester) async {
    await _pump(tester, '```mermaid\ngraph TD\nA-->B\n```');
    // Rendered as code text, not a special mermaid widget.
    expect(find.textContaining('graph TD'), findsOneWidget);
  });

  testWidgets('renders strikethrough and a link without crashing',
      (tester) async {
    await _pump(tester, 'This is ~~gone~~ and a [link](https://x.com).');
    expect(find.textContaining('gone'), findsOneWidget);
    expect(find.textContaining('link'), findsOneWidget);
  });

  testWidgets('bad LaTeX degrades to the raw source', (tester) async {
    await _pump(tester, r'Broken math $$\frac{$$ here.');
    // The invalid expression falls back to showing its source.
    expect(find.textContaining(r'\frac{'), findsOneWidget);
  });

  testWidgets('valid inline math renders without error', (tester) async {
    await _pump(tester, r'Euler: $e^{i\pi}+1=0$ done.');
    // No exception thrown; the surrounding text is present.
    expect(find.textContaining('Euler'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
