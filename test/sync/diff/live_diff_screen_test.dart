import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sreerajp_textapp/l10n/app_localizations.dart';
import 'package:sreerajp_textapp/sync/diff/live_diff_controller.dart';
import 'package:sreerajp_textapp/sync/ui/live_diff_screen.dart';

void main() {
  testWidgets(
    'LiveDiffScreen renders diff summary and allows hunk resolution',
    (tester) async {
      final ctrl = LiveDiffController(
        documentName: 'survey.csv',
        mimeType: 'text/csv',
        initialLocalContent: 'ID,Score\n1,10\n2,20',
        initialRemoteContent: 'ID,Score\n1,10\n2,25',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: LiveDiffScreen(controller: ctrl),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('survey.csv'), findsOneWidget);
      expect(find.text('1 Differences Found'), findsOneWidget);
      expect(find.text('Auto-Merge'), findsOneWidget);

      // Tap Auto-Merge button
      await tester.tap(find.text('Auto-Merge'));
      await tester.pumpAndSettle();

      expect(find.byType(LiveDiffScreen), findsOneWidget);
    },
  );
}
