import 'json_node.dart';

/// One schema violation: where it is and what is wrong (task 8.4).
class JsonSchemaError {
  final String path;
  final String message;
  const JsonSchemaError(this.path, this.message);

  @override
  String toString() => '$path: $message';
}

/// A **subset** JSON Schema validator (plan §3.5).
///
/// Supported keywords: `type`, `required`, `properties`, `items`, `enum`,
/// `minimum`, `maximum`, `minLength`, `maxLength`, and a boolean
/// `additionalProperties`. Unknown keywords are ignored rather than failing, so
/// a richer schema still validates what it can. Not a full Draft implementation
/// (`$ref`, `allOf`/`anyOf`, pattern, format, … are out of scope).
class JsonSchemaValidator {
  const JsonSchemaValidator();

  /// Validates [instance] against [schema] (a decoded schema map). Returns an
  /// empty list when the instance is valid.
  List<JsonSchemaError> validate(JsonNode instance, Object? schema) {
    final errors = <JsonSchemaError>[];
    _validate(dartValueOf(instance), schema, r'$', errors);
    return errors;
  }

  void _validate(
      Object? value, Object? schema, String path, List<JsonSchemaError> errors) {
    if (schema is! Map) return;

    final type = schema['type'];
    if (type != null && !_typeMatches(value, type)) {
      errors.add(JsonSchemaError(
          path, 'expected type ${_typeText(type)} but found ${_typeOf(value)}'));
      return; // Other checks assume the type held.
    }

    final enumValues = schema['enum'];
    if (enumValues is List && !enumValues.any((e) => _deepEquals(e, value))) {
      errors.add(JsonSchemaError(path, 'value is not one of the allowed values'));
    }

    if (value is num) {
      final min = schema['minimum'];
      if (min is num && value < min) {
        errors.add(JsonSchemaError(path, 'must be >= $min'));
      }
      final max = schema['maximum'];
      if (max is num && value > max) {
        errors.add(JsonSchemaError(path, 'must be <= $max'));
      }
    }

    if (value is String) {
      final minLen = schema['minLength'];
      if (minLen is num && value.length < minLen) {
        errors.add(JsonSchemaError(path, 'must be at least $minLen characters'));
      }
      final maxLen = schema['maxLength'];
      if (maxLen is num && value.length > maxLen) {
        errors.add(JsonSchemaError(path, 'must be at most $maxLen characters'));
      }
    }

    if (value is Map) {
      final required = schema['required'];
      if (required is List) {
        for (final key in required) {
          if (!value.containsKey(key)) {
            errors.add(JsonSchemaError(path, 'missing required key "$key"'));
          }
        }
      }
      final properties = schema['properties'];
      if (properties is Map) {
        for (final entry in value.entries) {
          final propSchema = properties[entry.key];
          if (propSchema != null) {
            _validate(entry.value, propSchema, _childPath(path, '${entry.key}'),
                errors);
          } else if (schema['additionalProperties'] == false) {
            errors.add(JsonSchemaError(
                _childPath(path, '${entry.key}'), 'additional key not allowed'));
          }
        }
      }
    }

    if (value is List) {
      final items = schema['items'];
      if (items is Map) {
        for (var i = 0; i < value.length; i++) {
          _validate(value[i], items, '$path[$i]', errors);
        }
      }
    }
  }

  bool _typeMatches(Object? value, Object type) {
    if (type is List) return type.any((t) => _typeMatches(value, t as Object));
    switch (type) {
      case 'object':
        return value is Map;
      case 'array':
        return value is List;
      case 'string':
        return value is String;
      case 'number':
        return value is num;
      case 'integer':
        return value is int || (value is num && value == value.roundToDouble());
      case 'boolean':
        return value is bool;
      case 'null':
        return value == null;
      default:
        return true;
    }
  }

  String _typeText(Object type) =>
      type is List ? type.join(' or ') : '$type';

  String _typeOf(Object? value) {
    if (value == null) return 'null';
    if (value is Map) return 'object';
    if (value is List) return 'array';
    if (value is String) return 'string';
    if (value is bool) return 'boolean';
    if (value is num) return 'number';
    return 'unknown';
  }

  bool _deepEquals(Object? a, Object? b) {
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_deepEquals(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }

  String _childPath(String parent, String key) => '$parent.$key';
}

/// Converts a parsed [JsonNode] into plain Dart values (`Map` / `List` / `String`
/// / `num` / `bool` / `null`) for schema validation. Numbers become `num` (this
/// may lose precision, which is fine for validation — round-tripping uses the raw
/// text instead).
Object? dartValueOf(JsonNode node) {
  switch (node.kind) {
    case JsonKind.object:
      return {
        for (final child in node.children) (child.key ?? ''): dartValueOf(child),
      };
    case JsonKind.array:
      return [for (final child in node.children) dartValueOf(child)];
    case JsonKind.string:
      return node.stringValue ?? '';
    case JsonKind.number:
      return node.numberValue ?? node.rawText;
    case JsonKind.boolean:
      return node.rawText == 'true';
    case JsonKind.nullValue:
      return null;
  }
}
