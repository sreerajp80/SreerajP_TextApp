import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/app.dart';
import 'package:text_data/core/storage/device_memory.dart';
import 'package:text_data/core/storage/key_value_store.dart';
import 'package:text_data/core/storage/saf_service.dart';
import 'package:text_data/shell/home/recents_controller.dart';
import 'package:text_data/shell/onboarding/onboarding_controller.dart';

import '../support/test_support.dart';

void main() {
  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = await inMemoryKeyValueStore(
      {OnboardingController.completeKey: true},
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
  }

  testWidgets('narrow viewport uses a bottom NavigationBar', (tester) async {
    await pumpAt(tester, const Size(400, 800));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('wide viewport uses a NavigationRail', (tester) async {
    await pumpAt(tester, const Size(1000, 800));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
