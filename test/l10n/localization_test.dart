import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/l10n/app_localizations.dart';

/// Guards task 13.4: the localization delegate is wired and resolves English
/// strings. A missing delegate or a broken ARB would fail these before release.
void main() {
  test('English is a supported locale', () {
    expect(
      AppLocalizations.supportedLocales.map((l) => l.languageCode),
      contains('en'),
    );
  });

  test('Malayalam is a supported locale', () {
    expect(
      AppLocalizations.supportedLocales.map((l) => l.languageCode),
      contains('ml'),
    );
  });

  testWidgets('AppLocalizations resolves Malayalam strings', (tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ml'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // A plain getter, a placeholder method, and a plural all resolve in Malayalam
    // (values differ from English, so the ml ARB is really being used).
    expect(l10n.actionSave, 'സംരക്ഷിക്കുക');
    expect(l10n.languageMalayalam, 'മലയാളം');
    expect(l10n.exportCreated('report.pdf'), contains('report.pdf'));
    expect(l10n.splitSaved(3), contains('3'));
    expect(l10n.filesAutoCap(1), isNot(l10n.filesAutoCap(5)));
  });

  testWidgets('AppLocalizations resolves and renders localized text',
      (tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return Scaffold(body: Text(l10n.appTitle));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // A plain getter, a placeholder method, and a plural all resolve.
    expect(l10n.appTitle, 'TextData');
    expect(find.text('TextData'), findsOneWidget);
    expect(l10n.exportCreated('report.pdf'), 'Created report.pdf');
    expect(l10n.splitSaved(3), 'Saved 3 parts.');
    expect(l10n.filesAutoCap(1), 'Auto — 1 tab');
    expect(l10n.filesAutoCap(5), 'Auto — 5 tabs');
  });
}
