import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/app.dart';
import 'package:text_data/core/storage/device_memory.dart';
import 'package:text_data/core/storage/key_value_store.dart';
import 'package:text_data/core/storage/saf_service.dart';
import 'package:text_data/shell/app_shell.dart';
import 'package:text_data/shell/home/recents_controller.dart';
import 'package:text_data/shell/onboarding/onboarding_controller.dart';
import 'package:text_data/shell/onboarding/onboarding_screen.dart';

import '../support/test_support.dart';

void main() {
  Future<KeyValueStore> pumpApp(
    WidgetTester tester, {
    required KeyValueStore store,
  }) async {
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
    return store;
  }

  testWidgets('onboarding shows on first run', (tester) async {
    final store = await inMemoryKeyValueStore();
    await pumpApp(tester, store: store);

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
  });

  testWidgets('finishing onboarding moves to the shell and persists',
      (tester) async {
    final store = await inMemoryKeyValueStore();
    await pumpApp(tester, store: store);

    // Skip closes the intro.
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
    expect(store.getBool(OnboardingController.completeKey), isTrue);
  });

  testWidgets('onboarding is hidden once complete', (tester) async {
    final store = await inMemoryKeyValueStore(
      {OnboardingController.completeKey: true},
    );
    await pumpApp(tester, store: store);

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
  });
}
