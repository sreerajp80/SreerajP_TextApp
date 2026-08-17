import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sreerajp_textapp/core/constants/app_constants.dart';

/// Guards the persisted-key registry in `lib/core/constants/app_constants.dart`.
///
/// These tests scan the real source of `lib/` rather than a hand-written list,
/// so a key added in the future is covered automatically. That is the point of
/// the registry: two features must not be able to pick the same key string, and
/// a key must not appear under an unregistered namespace.
void main() {
  // Matches `static const String someKey = 'a.b_c';` — a persisted settings key.
  //
  // The identifier must end in `Key`, which is this project's naming convention
  // for a persisted key. That is what separates a real key from other dotted
  // string constants, such as `AppDatabase.defaultFileName = 'text_data.db'`.
  // Private (`_someKey`) constants are matched too.
  final settingsKeyPattern = RegExp(
    r"""static\s+const\s+String\s+_?\w*Key\s*=\s*'([a-z][a-z0-9_]*(?:\.[a-z0-9_]+)+)'""",
  );

  late List<File> sourceFiles;

  setUpAll(() {
    sourceFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        // Generated localizations hold no settings keys.
        .where((f) => !f.path.replaceAll(r'\', '/').contains('/l10n/'))
        .toList();
  });

  /// Every `namespace.name` settings key found in `lib/`, mapped to the files
  /// that declare it.
  Map<String, List<String>> collectSettingsKeys() {
    final found = <String, List<String>>{};
    for (final file in sourceFiles) {
      final text = file.readAsStringSync();
      for (final match in settingsKeyPattern.allMatches(text)) {
        final key = match.group(1)!;
        found.putIfAbsent(key, () => []).add(file.path);
      }
    }
    return found;
  }

  test('the scan finds the settings keys that are known to exist', () {
    final keys = collectSettingsKeys().keys.toSet();

    // A sanity check on the regex itself. If this fails, the pattern stopped
    // matching and the other tests in this file would pass vacuously.
    expect(keys, contains('editor.autosave_seconds'));
    expect(keys, contains('appearance.theme_mode'));
    expect(keys, contains('security.app_lock_enabled'));
    expect(keys, contains('tabs.open_set'));
    expect(keys, contains('tts.english_enabled'));
    expect(keys, contains('md.split.on'));
    expect(keys, contains('onboarding.complete'));
    expect(keys.length, greaterThanOrEqualTo(20));
  });

  test('every settings key uses a registered namespace', () {
    final offenders = <String>[];

    for (final entry in collectSettingsKeys().entries) {
      final key = entry.key;
      final registered = SettingsNamespaces.all.any(
        (ns) => key.startsWith('$ns.'),
      );
      if (!registered) {
        offenders.add('$key (in ${entry.value.join(', ')})');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'These keys use a namespace that is not in SettingsNamespaces.all.\n'
          'Add the namespace to lib/core/constants/app_constants.dart, or move '
          'the key under an existing one:\n  ${offenders.join('\n  ')}',
    );
  });

  test('no settings key is declared in two different files', () {
    final duplicates = <String>[];

    for (final entry in collectSettingsKeys().entries) {
      final distinctFiles = entry.value.toSet();
      if (distinctFiles.length > 1) {
        duplicates.add('${entry.key} (in ${distinctFiles.join(', ')})');
      }
    }

    expect(
      duplicates,
      isEmpty,
      reason:
          'The same persisted key string is declared in more than one place, so '
          'two features would overwrite each other:\n  ${duplicates.join('\n  ')}',
    );
  });

  test('secure-store keys do not collide with settings keys', () {
    final settingsKeys = collectSettingsKeys().keys.toSet();
    final overlap = SecureStoreKeys.all.intersection(settingsKeys);

    expect(
      overlap,
      isEmpty,
      reason: 'A secret key reuses a settings key name.',
    );
  });

  test('the registered namespaces are all actually in use', () {
    final keys = collectSettingsKeys().keys.toSet();
    final unused = SettingsNamespaces.all
        .where((ns) => !keys.any((k) => k.startsWith('$ns.')))
        .toList();

    expect(
      unused,
      isEmpty,
      reason:
          'These namespaces are registered but no key uses them. Remove them so '
          'the registry stays honest: ${unused.join(', ')}',
    );
  });
}
