import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/formats/json/json_parser.dart';
import 'package:text_data/formats/json/json_schema_validator.dart';

void main() {
  const parser = JsonParser();
  const validator = JsonSchemaValidator();

  final schema = {
    'type': 'object',
    'required': ['name', 'age'],
    'properties': {
      'name': {'type': 'string', 'minLength': 1},
      'age': {'type': 'integer', 'minimum': 0, 'maximum': 150},
      'role': {
        'type': 'string',
        'enum': ['admin', 'user'],
      },
    },
  };

  test('a valid instance produces no errors', () {
    final node = parser.parse('{"name": "Ada", "age": 36, "role": "admin"}').root!;
    expect(validator.validate(node, schema), isEmpty);
  });

  test('lists a missing required key', () {
    final node = parser.parse('{"name": "Ada"}').root!;
    final errors = validator.validate(node, schema);
    expect(errors.any((e) => e.message.contains('age')), isTrue);
  });

  test('lists a type mismatch', () {
    final node = parser.parse('{"name": 5, "age": 10}').root!;
    final errors = validator.validate(node, schema);
    expect(errors.any((e) => e.path == r'$.name'), isTrue);
  });

  test('lists an out-of-range number and a bad enum', () {
    final node = parser.parse('{"name": "A", "age": 999, "role": "root"}').root!;
    final errors = validator.validate(node, schema);
    expect(errors.any((e) => e.path == r'$.age'), isTrue);
    expect(errors.any((e) => e.path == r'$.role'), isTrue);
  });
}
