import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/formats/txt/txt_link_warning_dialog.dart';
import 'package:text_data/l10n/app_localizations.dart';

void main() {
  group('TxtLinkDetector', () {
    test('finds an http and https link', () {
      final links = TxtLinkDetector.findLinks(
        'see http://a.com and https://b.org/x here',
      );
      expect(links.map((l) => l.url),
          ['http://a.com', 'https://b.org/x']);
    });

    test('trims trailing sentence punctuation', () {
      final links = TxtLinkDetector.findLinks('go to https://example.com.');
      expect(links.single.url, 'https://example.com');
    });

    test('no links in plain prose', () {
      expect(TxtLinkDetector.findLinks('just some words'), isEmpty);
    });
  });

  group('showLinkWarningDialog', () {
    Future<void> pumpTrigger(
      WidgetTester tester, {
      required UrlOpener open,
    }) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showLinkWarningDialog(
                context,
                'https://example.com',
                open: open,
              ),
              child: const Text('tap'),
            ),
          ),
        ),
      ));
    }

    testWidgets('shows the URL and only opens on explicit accept',
        (tester) async {
      Uri? opened;
      await pumpTrigger(tester, open: (u) async {
        opened = u;
        return true;
      });

      await tester.tap(find.text('tap'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('link-warning-dialog')), findsOneWidget);
      expect(find.text('https://example.com'), findsOneWidget);
      expect(opened, isNull); // nothing launched just by showing.

      await tester.tap(find.byKey(const Key('link-warning-open')));
      await tester.pumpAndSettle();
      expect(opened, Uri.parse('https://example.com'));
    });

    testWidgets('cancel launches nothing', (tester) async {
      var launched = false;
      await pumpTrigger(tester, open: (u) async {
        launched = true;
        return true;
      });

      await tester.tap(find.text('tap'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(launched, isFalse);
    });

    testWidgets('copy does not launch', (tester) async {
      var launched = false;
      await pumpTrigger(tester, open: (u) async {
        launched = true;
        return true;
      });

      await tester.tap(find.text('tap'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('link-warning-copy')));
      await tester.pumpAndSettle();

      expect(launched, isFalse);
    });
  });
}
