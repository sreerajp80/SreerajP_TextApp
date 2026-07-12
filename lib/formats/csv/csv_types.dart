/// The type the app infers for a CSV column, used for right-aligning numbers,
/// the insights panel, and the chart (task 7.1 / 7.4).
enum ColumnType { text, number, date, boolean, currency }

extension ColumnTypeInfo on ColumnType {
  String get label {
    switch (this) {
      case ColumnType.text:
        return 'Text';
      case ColumnType.number:
        return 'Number';
      case ColumnType.date:
        return 'Date';
      case ColumnType.boolean:
        return 'Boolean';
      case ColumnType.currency:
        return 'Currency';
    }
  }
}

/// Infers a column's type from its values (task 7.1). Empty cells are ignored;
/// a column is a given type only when **every** non-empty value fits it. The
/// order of the checks (boolean → currency → number → date → text) resolves the
/// overlaps (e.g. `1` counts as a number, not a boolean).
///
/// Pure Dart, host-tested.
ColumnType inferColumnType(Iterable<String> values) {
  final nonEmpty =
      values.map((v) => v.trim()).where((v) => v.isNotEmpty).toList();
  if (nonEmpty.isEmpty) return ColumnType.text;

  if (nonEmpty.every(_isBoolean)) return ColumnType.boolean;
  if (nonEmpty.every(_isCurrency)) return ColumnType.currency;
  if (nonEmpty.every(_isNumber)) return ColumnType.number;
  if (nonEmpty.every(_isDate)) return ColumnType.date;
  return ColumnType.text;
}

const _boolWords = {'true', 'false', 'yes', 'no'};

bool _isBoolean(String v) => _boolWords.contains(v.toLowerCase());

/// Parses a numeric value, tolerating thousands separators. Returns null when
/// the text is not a plain number.
num? parseNumber(String v) {
  final cleaned = v.replaceAll(',', '').trim();
  if (cleaned.isEmpty) return null;
  return num.tryParse(cleaned);
}

bool _isNumber(String v) => parseNumber(v) != null;

const _currencySymbols = r'$€£¥₹';

/// Parses a currency value like `$1,299.00` or `₹500` into a number, or null.
num? parseCurrency(String v) {
  var s = v.trim();
  if (s.isEmpty) return null;
  // A leading or trailing currency symbol makes it a currency value.
  final hasSymbol = _currencySymbols.contains(s[0]) ||
      _currencySymbols.contains(s[s.length - 1]);
  if (!hasSymbol) return null;
  s = s.replaceAll(RegExp('[$_currencySymbols]'), '').replaceAll(',', '').trim();
  return num.tryParse(s);
}

bool _isCurrency(String v) => parseCurrency(v) != null;

bool _isDate(String v) {
  if (DateTime.tryParse(v) != null) return true;
  // Common day/month/year forms DateTime.tryParse does not accept.
  final m = RegExp(r'^(\d{1,4})[/\-.](\d{1,2})[/\-.](\d{1,4})$').firstMatch(v);
  return m != null;
}
