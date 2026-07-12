import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/editor/editor_controller.dart';

void main() {
  group('EditorController undo/redo', () {
    test('a sequence of edits + undo returns exact prior states', () {
      final c = EditorController(text: '', coalesceUndo: false);
      c.insert('Hello');
      c.insert(' ');
      c.insert('world');
      expect(c.text, 'Hello world');

      c.undo();
      expect(c.text, 'Hello ');
      c.undo();
      expect(c.text, 'Hello');
      c.undo();
      expect(c.text, '');
      expect(c.canUndo, isFalse);
    });

    test('redo replays undone edits exactly', () {
      final c = EditorController(text: 'ab', coalesceUndo: false);
      c.replace(2, 2, 'c'); // abc
      c.replace(0, 1, 'X'); // Xbc
      expect(c.text, 'Xbc');

      c.undo();
      c.undo();
      expect(c.text, 'ab');

      c.redo();
      expect(c.text, 'abc');
      c.redo();
      expect(c.text, 'Xbc');
      expect(c.canRedo, isFalse);
    });

    test('a new edit clears the redo stack', () {
      final c = EditorController(text: '', coalesceUndo: false);
      c.insert('a');
      c.insert('b');
      c.undo(); // 'a'
      expect(c.canRedo, isTrue);
      c.insert('c'); // 'ac'
      expect(c.canRedo, isFalse);
      expect(c.text, 'ac');
    });

    test('deletion is reversible', () {
      final c = EditorController(text: 'hello', coalesceUndo: false);
      c.replace(0, 2, ''); // 'llo'
      expect(c.text, 'llo');
      c.undo();
      expect(c.text, 'hello');
    });

    test('coalescing groups consecutive typing into one undo step', () {
      final c = EditorController(text: '', coalesceUndo: true);
      c.insert('w');
      c.insert('o');
      c.insert('r');
      c.insert('d');
      expect(c.text, 'word');
      c.undo();
      // The whole run collapses because it was contiguous typing.
      expect(c.text, '');
      expect(c.canUndo, isFalse);
    });

    test('a caret move breaks the coalescing run', () {
      final c = EditorController(text: '', coalesceUndo: true);
      c.insert('ab');
      c.setSelection(const EditorSelection.collapsed(0));
      c.insert('X'); // 'Xab'
      expect(c.text, 'Xab');
      c.undo();
      expect(c.text, 'ab'); // only the second run undone
    });

    test('isDirty tracks changes against the saved baseline', () {
      final c = EditorController(text: 'v1');
      expect(c.isDirty, isFalse);
      c.insert('!');
      expect(c.isDirty, isTrue);
      c.markSaved();
      expect(c.isDirty, isFalse);
    });
  });
}
