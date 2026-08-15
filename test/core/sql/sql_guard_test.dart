import 'package:flutter_test/flutter_test.dart';

import 'package:text_data/core/sql/sql_guard.dart';

/// Feature 4 — the read-only gate in front of the query engine.
///
/// The engine runs over a throwaway in-memory copy, but `ATTACH` would let a
/// query reach the app's real database file on disk, so the gate matters
/// (CLAUDE.md §3.4).
void main() {
  group('allowed', () {
    test('a plain SELECT passes', () {
      final result = SqlGuard.check('SELECT * FROM data');
      expect(result.ok, isTrue);
      expect(result.statement, 'SELECT * FROM data');
    });

    test('a WITH query passes', () {
      expect(SqlGuard.check('WITH x AS (SELECT 1) SELECT * FROM x').ok, isTrue);
    });

    test('lower case and leading whitespace pass', () {
      expect(SqlGuard.check('   select 1  ').ok, isTrue);
    });

    test('a trailing semicolon is accepted and removed', () {
      final result = SqlGuard.check('SELECT 1;');
      expect(result.ok, isTrue);
      expect(result.statement, 'SELECT 1');
    });

    test('a blocked word inside a string literal is still allowed', () {
      final result = SqlGuard.check("SELECT * FROM data WHERE note = 'delete'");
      expect(result.ok, isTrue);
      expect(result.statement, contains("'delete'"));
    });

    test('a blocked word inside a comment is still allowed', () {
      expect(SqlGuard.check('SELECT 1 -- drop it').ok, isTrue);
      expect(SqlGuard.check('SELECT 1 /* insert here */').ok, isTrue);
    });

    test('a quoted identifier named like a keyword is allowed', () {
      expect(SqlGuard.check('SELECT "update" FROM data').ok, isTrue);
    });

    test('replace() is a normal function, not a blocked word', () {
      expect(SqlGuard.check("SELECT replace(a,'x','y') FROM data").ok, isTrue);
    });

    test('an escaped quote inside a literal does not end it', () {
      expect(SqlGuard.check("SELECT 'it''s drop' FROM data").ok, isTrue);
    });
  });

  group('refused', () {
    test('nothing typed', () {
      expect(SqlGuard.check('   ').failure, SqlGuardFailure.empty);
    });

    test('a statement that is not a query', () {
      expect(
        SqlGuard.check('DELETE FROM data').failure,
        SqlGuardFailure.notSelect,
      );
      expect(
        SqlGuard.check('PRAGMA table_info(data)').failure,
        SqlGuardFailure.notSelect,
      );
    });

    test('two statements', () {
      expect(
        SqlGuard.check('SELECT 1; DROP TABLE data').failure,
        SqlGuardFailure.multipleStatements,
      );
    });

    test('ATTACH is blocked — it could reach the app database', () {
      final result = SqlGuard.check("SELECT 1 FROM data; ATTACH 'x' AS y");
      expect(result.ok, isFalse);
      final direct = SqlGuard.check("WITH a AS (SELECT 1) ATTACH 'x' AS y");
      expect(direct.failure, SqlGuardFailure.forbiddenKeyword);
      expect(direct.keyword, 'attach');
    });

    test('a write hidden behind WITH is blocked', () {
      final result = SqlGuard.check(
        'WITH x AS (SELECT 1) INSERT INTO data SELECT * FROM x',
      );
      expect(result.failure, SqlGuardFailure.forbiddenKeyword);
      expect(result.keyword, 'insert');
    });

    test('file functions are blocked', () {
      expect(
        SqlGuard.check("SELECT readfile('/etc/hosts')").keyword,
        'readfile',
      );
      expect(
        SqlGuard.check("SELECT load_extension('evil.so')").keyword,
        'load_extension',
      );
    });
  });

  group('masking', () {
    test('literals and comments are blanked but stay the same length', () {
      const sql = "SELECT 'abc' -- x\nFROM data";
      final masked = SqlGuard.mask(sql);
      expect(masked.length, sql.length);
      expect(masked, contains('SELECT'));
      expect(masked, isNot(contains('abc')));
    });
  });
}
