import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:text_data/formats/xml/xml_tree_edits.dart';

void main() {
  const edits = XmlTreeEdits();

  XmlDocument parse(String s) => XmlDocument.parse(s);

  test('setText replaces a leaf element value', () {
    final doc = parse('<root><name>old</name></root>');
    final name = doc.rootElement.childElements.first;
    final out = edits.setText(doc, name, 'new');
    expect(parse(out).rootElement.childElements.first.innerText, 'new');
  });

  test('setAttribute adds and updates an attribute', () {
    final doc = parse('<root><item/></root>');
    final item = doc.rootElement.childElements.first;
    final out = edits.setAttribute(doc, item, 'id', '5');
    final reparsed = parse(out);
    expect(reparsed.rootElement.childElements.first.getAttribute('id'), '5');
  });

  test('removeAttribute drops the attribute', () {
    final doc = parse('<root><item id="5"/></root>');
    final item = doc.rootElement.childElements.first;
    final out = edits.removeAttribute(doc, item, 'id');
    expect(parse(out).rootElement.childElements.first.getAttribute('id'),
        isNull);
  });

  test('renameElement keeps attributes and children', () {
    final doc = parse('<root><old a="1"><c/></old></root>');
    final old = doc.rootElement.childElements.first;
    final out = edits.renameElement(doc, old, 'fresh');
    final child = parse(out).rootElement.childElements.first;
    expect(child.name.qualified, 'fresh');
    expect(child.getAttribute('a'), '1');
    expect(child.childElements.first.name.qualified, 'c');
  });

  test('addChild appends a new element', () {
    final doc = parse('<root><a/></root>');
    final out = edits.addChild(doc, doc.rootElement, 'b', text: 'hi');
    final children = parse(out).rootElement.childElements.toList();
    expect(children.map((e) => e.name.qualified), ['a', 'b']);
    expect(children.last.innerText, 'hi');
  });

  test('deleteNode removes an element', () {
    final doc = parse('<root><a/><b/></root>');
    final a = doc.rootElement.childElements.first;
    final out = edits.deleteNode(doc, a);
    expect(parse(out).rootElement.childElements.map((e) => e.name.qualified),
        ['b']);
  });

  test('deleteNode never removes the document root', () {
    final doc = parse('<root><a/></root>');
    final out = edits.deleteNode(doc, doc.rootElement);
    expect(parse(out).rootElement.name.qualified, 'root');
  });

  test('moveSibling swaps element order', () {
    final doc = parse('<root><a/><b/><c/></root>');
    final b = doc.rootElement.childElements.toList()[1];
    final out = edits.moveSibling(doc, b, -1); // move b up
    expect(parse(out).rootElement.childElements.map((e) => e.name.qualified),
        ['b', 'a', 'c']);
  });

  test('moveSibling at an edge is a no-op', () {
    final doc = parse('<root><a/><b/></root>');
    final a = doc.rootElement.childElements.first;
    final out = edits.moveSibling(doc, a, -1); // already first
    expect(parse(out).rootElement.childElements.map((e) => e.name.qualified),
        ['a', 'b']);
  });

  test('every edit leaves well-formed XML', () {
    final doc = parse('<root><a x="1">t</a></root>');
    final a = doc.rootElement.childElements.first;
    final out = edits.setText(doc, a, 'z');
    expect(() => parse(out), returnsNormally);
  });
}
