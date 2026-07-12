import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/sync/bounded_line_reader.dart';

void main() {
  test('reads newline-delimited lines and tolerates CRLF', () async {
    final controller = StreamController<List<int>>();
    final reader = BoundedLineReader(controller.stream, maxLineBytes: 1024);
    controller.add('one\r\ntwo\n'.codeUnits);
    expect(await reader.readLine(), 'one');
    expect(await reader.readLine(), 'two');
    await controller.close();
  });

  test('an over-long line is rejected at the cap', () async {
    final controller = StreamController<List<int>>();
    final reader = BoundedLineReader(controller.stream, maxLineBytes: 8);
    controller.add('123456789012345'.codeUnits); // no newline, past cap
    expect(reader.readLine(), throwsA(isA<LineTooLongException>()));
    await controller.close();
  });

  test('closed resolves and a pending read fails when the stream drops',
      () async {
    final controller = StreamController<List<int>>();
    final reader = BoundedLineReader(controller.stream, maxLineBytes: 1024);
    final pending = reader.readLine();
    // Attach the matcher before the future can complete with an error, so it is
    // never seen as an unhandled async error.
    final expectation = expectLater(pending, throwsA(anything));
    await controller.close();
    await reader.closed; // must complete
    await expectation;
  });

  test('lines buffered before a reader asks are delivered in order', () async {
    final controller = StreamController<List<int>>();
    final reader = BoundedLineReader(controller.stream, maxLineBytes: 1024);
    controller.add('a\nb\nc\n'.codeUnits);
    await Future<void>.delayed(Duration.zero);
    expect(await reader.readLine(), 'a');
    expect(await reader.readLine(), 'b');
    expect(await reader.readLine(), 'c');
    await controller.close();
  });
}
