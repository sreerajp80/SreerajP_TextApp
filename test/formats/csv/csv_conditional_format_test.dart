import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/formats/csv/csv_conditional_format.dart';
import 'package:text_data/formats/csv/csv_table.dart';

/// Guards the conditional formatting rules (roadmap §4.2.3).
void main() {
  CsvTable table() => CsvTable(
        header: ['name', 'balance'],
        rows: [
          ['Ada', '-40'],
          ['Bob', '120'],
          ['Ada', '0'],
          ['Cid', ''],
          ['Dee', '120'],
        ],
        hasHeader: true,
      );

  CsvHighlight? highlightAt(List<CsvFormatRule> rules, int row, int col) {
    final t = table();
    return CsvConditionalFormat.prepare(t, rules).highlightFor(t, row, col);
  }

  test('highlights numbers below a threshold', () {
    const rules = [
      CsvFormatRule(
        column: 1,
        condition: CsvCondition.lessThan,
        value: '0',
        highlight: CsvHighlight.red,
      ),
    ];
    expect(highlightAt(rules, 0, 1), CsvHighlight.red); // -40
    expect(highlightAt(rules, 1, 1), isNull); // 120
    expect(highlightAt(rules, 2, 1), isNull); // 0 is not below 0
  });

  test('an empty cell is not treated as below a number', () {
    const rules = [
      CsvFormatRule(
        column: 1,
        condition: CsvCondition.lessThan,
        value: '0',
        highlight: CsvHighlight.red,
      ),
    ];
    expect(highlightAt(rules, 3, 1), isNull);
  });

  test('highlights values above a threshold', () {
    const rules = [
      CsvFormatRule(
        column: 1,
        condition: CsvCondition.greaterThan,
        value: '100',
        highlight: CsvHighlight.green,
      ),
    ];
    expect(highlightAt(rules, 1, 1), CsvHighlight.green);
    expect(highlightAt(rules, 0, 1), isNull);
  });

  test('highlights duplicate values in a column', () {
    const rules = [
      CsvFormatRule(
        column: 0,
        condition: CsvCondition.isDuplicate,
        highlight: CsvHighlight.yellow,
      ),
    ];
    expect(highlightAt(rules, 0, 0), CsvHighlight.yellow); // Ada
    expect(highlightAt(rules, 2, 0), CsvHighlight.yellow); // Ada again
    expect(highlightAt(rules, 1, 0), isNull); // Bob is unique
  });

  test('a blank cell never counts as a duplicate', () {
    const rules = [
      CsvFormatRule(
        column: 1,
        condition: CsvCondition.isDuplicate,
        highlight: CsvHighlight.yellow,
      ),
    ];
    expect(highlightAt(rules, 3, 1), isNull);
  });

  test('highlights empty cells', () {
    const rules = [
      CsvFormatRule(
        column: null,
        condition: CsvCondition.isEmpty,
        highlight: CsvHighlight.blue,
      ),
    ];
    expect(highlightAt(rules, 3, 1), CsvHighlight.blue);
    expect(highlightAt(rules, 0, 0), isNull);
  });

  test('contains matches without case', () {
    const rules = [
      CsvFormatRule(
        column: 0,
        condition: CsvCondition.contains,
        value: 'ad',
        highlight: CsvHighlight.blue,
      ),
    ];
    expect(highlightAt(rules, 0, 0), CsvHighlight.blue);
    expect(highlightAt(rules, 1, 0), isNull);
  });

  test('equal and not equal compare numbers as numbers', () {
    const equal = [
      CsvFormatRule(
        column: 1,
        condition: CsvCondition.equalTo,
        value: '120.0',
        highlight: CsvHighlight.green,
      ),
    ];
    expect(highlightAt(equal, 1, 1), CsvHighlight.green);

    const notEqual = [
      CsvFormatRule(
        column: 1,
        condition: CsvCondition.notEqualTo,
        value: '120',
        highlight: CsvHighlight.red,
      ),
    ];
    expect(highlightAt(notEqual, 1, 1), isNull);
    expect(highlightAt(notEqual, 0, 1), CsvHighlight.red);
  });

  test('a rule with no column watches every column', () {
    const rules = [
      CsvFormatRule(
        column: null,
        condition: CsvCondition.contains,
        value: 'a',
        highlight: CsvHighlight.blue,
      ),
    ];
    expect(highlightAt(rules, 0, 0), CsvHighlight.blue); // "Ada"
    expect(highlightAt(rules, 1, 1), isNull); // "120"
  });

  test('the first matching rule wins', () {
    const rules = [
      CsvFormatRule(
        column: 1,
        condition: CsvCondition.lessThan,
        value: '0',
        highlight: CsvHighlight.red,
      ),
      CsvFormatRule(
        column: 1,
        condition: CsvCondition.notEqualTo,
        value: '999',
        highlight: CsvHighlight.green,
      ),
    ];
    expect(highlightAt(rules, 0, 1), CsvHighlight.red);
  });

  test('no rules means nothing to draw', () {
    final t = table();
    final format = CsvConditionalFormat.prepare(t, const []);
    expect(format.isEmpty, isTrue);
    expect(format.highlightFor(t, 0, 0), isNull);
  });

  group('rule storage', () {
    test('round-trips through encode / decode', () {
      const rule = CsvFormatRule(
        column: 2,
        condition: CsvCondition.greaterThan,
        value: '3.5',
        highlight: CsvHighlight.yellow,
      );
      expect(CsvFormatRule.decode(rule.encode()), rule);
    });

    test('round-trips an all-columns rule', () {
      const rule = CsvFormatRule(
        column: null,
        condition: CsvCondition.isEmpty,
        highlight: CsvHighlight.blue,
      );
      expect(CsvFormatRule.decode(rule.encode()), rule);
    });

    test('keeps a value that itself contains a separator', () {
      const rule = CsvFormatRule(
        column: 0,
        condition: CsvCondition.contains,
        value: 'a|b',
        highlight: CsvHighlight.red,
      );
      expect(CsvFormatRule.decode(rule.encode())?.value, 'a|b');
    });

    test('rejects text that is not a rule', () {
      expect(CsvFormatRule.decode(''), isNull);
      expect(CsvFormatRule.decode('1|nope|red|'), isNull);
      expect(CsvFormatRule.decode('1|contains|puce|'), isNull);
      expect(CsvFormatRule.decode('x|contains|red|'), isNull);
    });
  });
}
