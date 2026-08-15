import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/config/app_config.dart';
import 'package:text_data/core/config/config_service.dart';
import 'package:text_data/core/editor/editor_settings.dart';
import 'package:text_data/core/storage/device_memory.dart';
import 'package:text_data/core/storage/key_value_store.dart';
import 'package:text_data/core/storage/saf_service.dart';
import 'package:text_data/shell/settings/settings_screen.dart';

import '../../support/test_support.dart';

AppConfig configWithVersion(String version) => AppConfig(
  appName: 'Text & Data App',
  description: 'A test description.',
  version: version,
  build: '7',
  details: const {
    'Author': 'Sreeraj P',
    'Email': 'test@example.com',
    'License': 'All libraries used are open source.',
  },
);

void main() {
  Future<void> pumpSettings(
    WidgetTester tester, {
    required KeyValueStore store,
    required AppConfig config,
  }) async {
    // A tall viewport so every settings card is laid out at once.
    tester.view.physicalSize = const Size(1000, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreSyncProvider.overrideWithValue(store),
          safServiceProvider.overrideWithValue(FakeSafService()),
          deviceMemoryProvider.overrideWithValue(
            const FakeDeviceMemory(4 * 1024 * 1024 * 1024),
          ),
          appConfigProvider.overrideWith((ref) async => config),
        ],
        child: localizedApp(home: const SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('all nine settings cards render', (tester) async {
    final store = await inMemoryKeyValueStore();
    await pumpSettings(
      tester,
      store: store,
      config: configWithVersion('1.0.0'),
    );

    for (final header in const [
      'Appearance',
      'Editor',
      'Files & Tabs',
      'Speech (read aloud)',
      'Sync',
      'Security',
      'Audit Log',
      'Help',
      'About',
    ]) {
      expect(find.text(header), findsOneWidget, reason: 'missing $header');
    }
  });

  testWidgets('Help shows topics and detail pages', (tester) async {
    final store = await inMemoryKeyValueStore();
    await pumpSettings(
      tester,
      store: store,
      config: configWithVersion('1.0.0'),
    );

    await tester.tap(find.text('Help'));
    await tester.pumpAndSettle();

    expect(find.text('LAN Sync & Live Diff'), findsOneWidget);
    expect(find.text('Privacy Shield & PII Scrubber'), findsOneWidget);
    expect(find.text('Document Vault & Encrypted Backups'), findsOneWidget);
    expect(find.text('SQL Query Engine'), findsOneWidget);
    expect(find.text('Multi-Cursor & Column Editing'), findsOneWidget);
    expect(find.text('Split array'), findsOneWidget);

    // Tapping a topic opens its detail screen
    await tester.tap(find.text('Privacy Shield & PII Scrubber'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Zero Network Leakage'), findsOneWidget);
    expect(find.textContaining('Automatic Detection'), findsOneWidget);

    // Back to Help list
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Test search filter
    await tester.enterText(find.byType(TextField), 'SQL');
    await tester.pumpAndSettle();

    expect(find.text('SQL Query Engine'), findsOneWidget);
    expect(find.text('Privacy Shield & PII Scrubber'), findsNothing);

    // Search with no results
    await tester.enterText(find.byType(TextField), 'nonexistent_topic_xyz');
    await tester.pumpAndSettle();

    expect(find.text('No matching help topics found.'), findsOneWidget);
  });

  testWidgets('About shows the values from the config', (tester) async {
    final store = await inMemoryKeyValueStore();
    await pumpSettings(
      tester,
      store: store,
      config: configWithVersion('1.0.0'),
    );
    await tester.ensureVisible(find.text('About'));
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();

    expect(find.text('1.0.0 (build 7)'), findsOneWidget);
    expect(find.text('A test description.'), findsOneWidget);
  });

  testWidgets('editing the config changes About with no code change', (
    tester,
  ) async {
    final store = await inMemoryKeyValueStore();
    // A different config value shows on the same screen, unchanged code.
    await pumpSettings(
      tester,
      store: store,
      config: configWithVersion('2.5.0'),
    );
    await tester.ensureVisible(find.text('About'));
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();

    expect(find.text('2.5.0 (build 7)'), findsOneWidget);
  });

  testWidgets('tapping a card opens its settings page', (tester) async {
    final store = await inMemoryKeyValueStore();
    await pumpSettings(
      tester,
      store: store,
      config: configWithVersion('1.0.0'),
    );

    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();

    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
  });

  testWidgets('toggling confirm-before-overwrite persists', (tester) async {
    final store = await inMemoryKeyValueStore();
    await pumpSettings(
      tester,
      store: store,
      config: configWithVersion('1.0.0'),
    );
    await tester.tap(find.text('Editor'));
    await tester.pumpAndSettle();

    // Default is on; tap the switch to turn it off.
    await tester.tap(find.text('Confirm before overwriting'));
    await tester.pumpAndSettle();

    expect(store.getBool(EditorSettings.confirmOverwriteKey), isFalse);
  });
}
