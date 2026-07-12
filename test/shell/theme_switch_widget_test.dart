import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/app.dart';
import 'package:text_data/core/storage/device_memory.dart';
import 'package:text_data/core/storage/key_value_store.dart';
import 'package:text_data/core/storage/saf_service.dart';
import 'package:text_data/shell/app_shell.dart';
import 'package:text_data/shell/home/recents_controller.dart';
import 'package:text_data/shell/onboarding/onboarding_controller.dart';

import '../support/test_support.dart';

void main() {
  testWidgets('switching the theme changes the visible scheme', (tester) async {
    final store = await inMemoryKeyValueStore(
      {OnboardingController.completeKey: true}, // skip onboarding
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreSyncProvider.overrideWithValue(store),
          safServiceProvider.overrideWithValue(FakeSafService()),
          deviceMemoryProvider
              .overrideWithValue(const FakeDeviceMemory(4 * 1024 * 1024 * 1024)),
          recentsControllerProvider
              .overrideWith(() => StubRecentsController()),
        ],
        child: const TextDataApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Default: not dark.
    expect(
      Theme.of(tester.element(find.byType(AppShell))).brightness,
      Brightness.light,
    );

    // Go to Settings, open the Appearance card, and pick Dark.
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    // Return to the shell so it is on-stage again (the Appearance detail page
    // is pushed over it, which pushes the shell off-stage).
    await tester.pageBack();
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.byType(AppShell))).brightness,
      Brightness.dark,
    );
  });
}
