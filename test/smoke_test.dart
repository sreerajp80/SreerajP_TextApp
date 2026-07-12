import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:text_data/app.dart';
import 'package:text_data/core/storage/device_memory.dart';
import 'package:text_data/core/storage/key_value_store.dart';
import 'package:text_data/core/storage/saf_service.dart';
import 'package:text_data/shell/app_shell.dart';
import 'package:text_data/shell/home/recents_controller.dart';
import 'package:text_data/shell/onboarding/onboarding_controller.dart';

import 'support/test_support.dart';

void main() {
  testWidgets('App builds and shows the shell once onboarding is complete',
      (tester) async {
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

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(AppShell), findsOneWidget);
  });
}
