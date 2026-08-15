/// Why a typed query was refused before it ever reached SQLite.
enum SqlGuardFailure {
  /// Nothing was typed.
  empty,

  /// The statement does not start with `SELECT` or `WITH`.
  notSelect,

  /// More than one statement was typed.
  multipleStatements,

  /// A word that can write, read a file, or reach another database was used.
  forbiddenKeyword,
}

/// The outcome of [SqlGuard.check].
class SqlGuardResult {
  final bool ok;
  final SqlGuardFailure? failure;

  /// The offending word, when [failure] is [SqlGuardFailure.forbiddenKeyword].
  final String? keyword;

  /// The statement with its trailing `;` removed, ready to run. Empty when the
  /// check failed.
  final String statement;

  const SqlGuardResult.pass(this.statement)
    : ok = true,
      failure = null,
      keyword = null;

  const SqlGuardResult.fail(this.failure, {this.keyword})
    : ok = false,
      statement = '';
}

/// Checks that a typed query is a single, read-only `SELECT` (Feature 4).
///
/// The query engine runs over a **throwaway in-memory copy** of the open
/// document, so a write could not damage the user's file. This guard is still
/// required, for one reason above all: `ATTACH` would let a query open the app's
/// real database file on disk. Typed SQL is untrusted input like any opened file
/// (CLAUDE.md §3.4, §8).
///
/// The check runs over a copy of the text with string literals, quoted
/// identifiers, and comments blanked out, so a perfectly ordinary query such as
/// `WHERE note = 'delete me'` is not mistaken for a `DELETE`.
///
/// Pure Dart, host-tested.
class SqlGuard {
  const SqlGuard._();

  /// Words that must not appear anywhere in the statement.
  ///
  /// `REPLACE` is deliberately **absent**: it is a normal string function
  /// (`replace(name, 'a', 'b')`), and `REPLACE INTO` cannot appear here anyway
  /// because a statement must begin with `SELECT` or `WITH`.
  static const forbidden = <String>{
    'attach',
    'detach',
    'pragma',
    'insert',
    'update',
    'delete',
    'drop',
    'alter',
    'create',
    'vacuum',
    'reindex',
    'begin',
    'commit',
    'rollback',
    'savepoint',
    'release',
    'load_extension',
    'readfile',
    'writefile',
    'fts3_tokenizer',
  };

  static SqlGuardResult check(String sql) {
    final trimmed = sql.trim();
    if (trimmed.isEmpty) {
      return const SqlGuardResult.fail(SqlGuardFailure.empty);
    }

    final masked = mask(trimmed);

    // One statement only. A single trailing `;` is normal typing and is dropped.
    final withoutTrailing = masked.replaceFirst(RegExp(r';\s*$'), '');
    if (withoutTrailing.contains(';')) {
      return const SqlGuardResult.fail(SqlGuardFailure.multipleStatements);
    }

    if (!RegExp(r'^(select|with)\b', caseSensitive: false).hasMatch(masked)) {
      return const SqlGuardResult.fail(SqlGuardFailure.notSelect);
    }

    for (final word in RegExp(
      r'[A-Za-z_][A-Za-z0-9_]*',
    ).allMatches(withoutTrailing)) {
      final lower = word[0]!.toLowerCase();
      if (forbidden.contains(lower)) {
        return SqlGuardResult.fail(
          SqlGuardFailure.forbiddenKeyword,
          keyword: lower,
        );
      }
    }

    // Return the *original* text minus its trailing semicolon — the mask is only
    // ever used for checking, never for running.
    return SqlGuardResult.pass(trimmed.replaceFirst(RegExp(r';\s*$'), ''));
  }

  /// Replaces the contents of string literals, quoted identifiers and comments
  /// with spaces, keeping the text the same length so positions still line up.
  ///
  /// Visible for testing.
  static String mask(String sql) {
    final out = List<String>.from(sql.split(''));
    var i = 0;
    while (i < sql.length) {
      final ch = sql[i];

      // -- line comment
      if (ch == '-' && i + 1 < sql.length && sql[i + 1] == '-') {
        while (i < sql.length && sql[i] != '\n') {
          out[i] = ' ';
          i++;
        }
        continue;
      }

      // /* block comment */
      if (ch == '/' && i + 1 < sql.length && sql[i + 1] == '*') {
        out[i] = ' ';
        out[i + 1] = ' ';
        i += 2;
        while (i < sql.length) {
          if (sql[i] == '*' && i + 1 < sql.length && sql[i + 1] == '/') {
            out[i] = ' ';
            out[i + 1] = ' ';
            i += 2;
            break;
          }
          out[i] = ' ';
          i++;
        }
        continue;
      }

      // 'text', "identifier", [identifier], `identifier`
      final closer = _closerFor(ch);
      if (closer != null) {
        i++; // keep the opening mark, blank what is inside
        while (i < sql.length) {
          if (sql[i] == closer) {
            // A doubled mark ('' or "") is an escape, not the end.
            if (i + 1 < sql.length && sql[i + 1] == closer) {
              out[i] = ' ';
              out[i + 1] = ' ';
              i += 2;
              continue;
            }
            i++; // keep the closing mark
            break;
          }
          out[i] = ' ';
          i++;
        }
        continue;
      }

      i++;
    }
    return out.join();
  }

  static String? _closerFor(String ch) {
    switch (ch) {
      case "'":
        return "'";
      case '"':
        return '"';
      case '`':
        return '`';
      case '[':
        return ']';
      default:
        return null;
    }
  }
}
