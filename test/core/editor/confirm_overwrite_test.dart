import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/editor/confirm_overwrite.dart';
import 'package:text_data/core/editor/editor_settings.dart';
import 'package:text_data/core/storage/key_value_store.dart';

import '../../support/test_support.dart';

void main() {
  Future<bool?> runHelper(
    WidgetTester tester,
    KeyValueStore store,
  ) async {
    bool? result;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [keyValueStoreSyncProvider.overrideWithValue(store)],
        child: localizedApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await confirmOverwriteIfNeeded(context);
                },
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('returns true without a dialog when the setting is off',
      (tester) async {
    final store = await inMemoryKeyValueStore();
    await store.setBool(EditorSettings.confirmOverwriteKey, false);

    final result = await runHelper(tester, store);
    expect(result, isTrue);
    expect(find.text('Overwrite the file?'), findsNothing);
  });

  testWidgets('shows the dialog and returns true on Overwrite', (tester) async {
    final store = await inMemoryKeyValueStore(); // default: confirm on

    bool? result;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [keyValueStoreSyncProvider.overrideWithValue(store)],
        child: localizedApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await confirmOverwriteIfNeeded(context);
                },
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.text('Overwrite the file?'), findsOneWidget);
    await tester.tap(find.text('Overwrite'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('dialog Cancel returns false', (tester) async {
    final store = await inMemoryKeyValueStore();

    bool? result;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [keyValueStoreSyncProvider.overrideWithValue(store)],
        child: localizedApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await confirmOverwriteIfNeeded(context);
                },
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });
}
