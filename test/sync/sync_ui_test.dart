import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/sync/payload.dart';
import 'package:text_data/sync/sync_constants.dart';
import 'package:text_data/sync/sync_provider.dart';
import 'package:text_data/sync/sync_transport.dart';
import 'package:text_data/sync/ui/share_chooser.dart';
import 'package:text_data/sync/ui/sync_status_chip.dart';
import 'package:text_data/sync/ui/sync_summary_view.dart';
import 'package:text_data/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('status chip reflects the host phase', (tester) async {
    await tester.pumpWidget(_wrap(const SyncStatusChip(phase: HostPhase.listening)));
    expect(find.text('Waiting for a device…'), findsOneWidget);

    await tester.pumpWidget(_wrap(const SyncStatusChip(phase: HostPhase.connected)));
    expect(find.text('Device connected'), findsOneWidget);
  });

  testWidgets('share actions are gated until connected', (tester) async {
    var fullSyncCalls = 0;
    Widget chooser(bool connected) => _wrap(ShareChooser(
          connected: connected,
          sending: false,
          onFullSync: () => fullSyncCalls++,
          onSelective: (_, _) {},
        ));

    // Not connected: the Full sync button is disabled.
    await tester.pumpWidget(chooser(false));
    final disabled = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Full sync'),
    );
    expect(disabled.onPressed, isNull);
    await tester.tap(find.widgetWithText(FilledButton, 'Full sync'));
    expect(fullSyncCalls, 0);

    // Connected: it is enabled and fires.
    await tester.pumpWidget(chooser(true));
    final enabled = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Full sync'),
    );
    expect(enabled.onPressed, isNotNull);
    await tester.tap(find.widgetWithText(FilledButton, 'Full sync'));
    expect(fullSyncCalls, 1);
  });

  testWidgets('summary renders per-category and settings counts',
      (tester) async {
    final summary = SyncSummary(
      records: {
        SyncConstants.categoryFavorites:
            const RecordMergeResult(toAdd: [], added: 3, kept: 1),
      },
      settings: const SettingsMergeResult(toApply: {}, applied: 2, kept: 0),
    );
    await tester.pumpWidget(_wrap(SyncSummaryView(summary: summary)));
    expect(find.text('Sync complete'), findsOneWidget);
    expect(find.text('5 added · 1 kept'), findsOneWidget); // totals
    expect(find.text('3 added · 1 kept'), findsOneWidget); // favorites row
    expect(find.text('2 applied · 0 kept'), findsOneWidget); // settings row
  });
}
