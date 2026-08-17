import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sreerajp_textapp/core/editor/external_change.dart';
import 'package:sreerajp_textapp/shell/tabs/document_tab.dart';
import 'package:sreerajp_textapp/shell/tabs/file_changed_banner.dart';

import '../support/test_support.dart';

/// A document under the banner's control, with every flag set by the test.
class _FakeDocument extends ChangeNotifier implements ReloadableDocument {
  bool _changed = false;
  bool dirty = false;
  bool reloadSucceeds = true;
  int reloadCount = 0;
  int dismissCount = 0;
  int checkCount = 0;

  @override
  bool get externalChangeDetected => _changed;

  @override
  bool get isDirty => dirty;

  void flagChange() {
    _changed = true;
    notifyListeners();
  }

  @override
  Future<void> checkForExternalChange() async => checkCount++;

  @override
  void dismissExternalChange() {
    dismissCount++;
    _changed = false;
    notifyListeners();
  }

  @override
  Future<bool> reloadFromDisk() async {
    reloadCount++;
    if (!reloadSucceeds) return false;
    _changed = false;
    notifyListeners();
    return true;
  }
}

const _tab = DocumentTab(
  id: 'tab-1',
  fingerprint: '10-a',
  uri: 'content://a',
  displayName: 'note.txt',
  mimeType: 'text/plain',
  lastActiveAt: 1,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpBanner(WidgetTester tester, _FakeDocument doc) async {
    await tester.pumpWidget(
      ProviderScope(
        child: localizedApp(
          home: Scaffold(
            body: FileChangedBanner(tab: _tab, resolveDocument: (_, _) => doc),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final banner = find.byKey(const Key('file-changed-banner'));
  final reloadButton = find.byKey(const Key('file-changed-reload-button'));
  final dismissButton = find.byKey(const Key('file-changed-dismiss-button'));
  final confirmDialog = find.byKey(const Key('file-changed-confirm-dialog'));
  final confirmReload = find.byKey(const Key('file-changed-confirm-reload'));

  testWidgets('nothing shows until a change is spotted', (tester) async {
    final doc = _FakeDocument();
    await pumpBanner(tester, doc);

    // The banner checks the file once it is on screen.
    expect(doc.checkCount, 1);
    expect(banner, findsNothing);

    doc.flagChange();
    await tester.pumpAndSettle();
    expect(banner, findsOneWidget);
  });

  testWidgets('reload on a clean tab loads the file straight away', (
    tester,
  ) async {
    final doc = _FakeDocument();
    await pumpBanner(tester, doc);
    doc.flagChange();
    await tester.pumpAndSettle();

    await tester.tap(reloadButton);
    await tester.pumpAndSettle();

    expect(confirmDialog, findsNothing); // nothing to lose, so no question
    expect(doc.reloadCount, 1);
    expect(banner, findsNothing);
  });

  testWidgets('reload on a tab with unsaved edits asks first', (tester) async {
    final doc = _FakeDocument()..dirty = true;
    await pumpBanner(tester, doc);
    doc.flagChange();
    await tester.pumpAndSettle();

    await tester.tap(reloadButton);
    await tester.pumpAndSettle();
    expect(confirmDialog, findsOneWidget);

    // Backing out keeps the edits and the warning.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(doc.reloadCount, 0);
    expect(banner, findsOneWidget);

    // Agreeing reloads.
    await tester.tap(reloadButton);
    await tester.pumpAndSettle();
    await tester.tap(confirmReload);
    await tester.pumpAndSettle();
    expect(doc.reloadCount, 1);
    expect(banner, findsNothing);
  });

  testWidgets('dismiss hides the warning and keeps the content', (
    tester,
  ) async {
    final doc = _FakeDocument();
    await pumpBanner(tester, doc);
    doc.flagChange();
    await tester.pumpAndSettle();

    await tester.tap(dismissButton);
    await tester.pumpAndSettle();

    expect(doc.dismissCount, 1);
    expect(doc.reloadCount, 0);
    expect(banner, findsNothing);
  });

  testWidgets('a failed reload says so and keeps the warning', (tester) async {
    final doc = _FakeDocument()..reloadSucceeds = false;
    await pumpBanner(tester, doc);
    doc.flagChange();
    await tester.pumpAndSettle();

    await tester.tap(reloadButton);
    await tester.pumpAndSettle();

    expect(find.text('Could not reload the file.'), findsOneWidget);
    expect(banner, findsOneWidget);
  });
}
