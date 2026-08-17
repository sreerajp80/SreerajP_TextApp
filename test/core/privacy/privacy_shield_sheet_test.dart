import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sreerajp_textapp/core/privacy/ui/privacy_shield_sheet.dart';
import 'package:sreerajp_textapp/core/share/share_service.dart';
import '../../support/test_support.dart';

class _FakeShareLauncher implements ShareLauncher {
  List<ShareFileRequest>? lastFiles;
  String? lastText;

  @override
  Future<void> shareFiles(
    List<ShareFileRequest> requests, {
    String? subject,
  }) async {
    lastFiles = requests;
  }

  @override
  Future<void> shareText(String text, {String? subject}) async {
    lastText = text;
  }
}

void main() {
  testWidgets('PrivacyShieldSheet renders clean state when no PII found', (
    tester,
  ) async {
    final launcher = _FakeShareLauncher();
    final share = ShareService(launcher);
    final saf = FakeSafService();

    await tester.pumpWidget(
      localizedApp(
        home: Scaffold(
          body: PrivacyShieldSheet(
            text: 'Just regular notes with no secrets.',
            documentTitle: 'notes.txt',
            mimeType: 'text/plain',
            shareService: share,
            safService: saf,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Offline Privacy Shield'), findsOneWidget);
    expect(find.text('No Sensitive Data Detected'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
  });

  testWidgets(
    'PrivacyShieldSheet detects items and applies redactions in-place',
    (tester) async {
      final launcher = _FakeShareLauncher();
      final share = ShareService(launcher);
      final saf = FakeSafService();
      String? appliedText;

      await tester.pumpWidget(
        localizedApp(
          home: Scaffold(
            body: PrivacyShieldSheet(
              text: 'Contact user@example.com at 192.168.1.1.',
              documentTitle: 'data.txt',
              mimeType: 'text/plain',
              onApplyToEditor: (newText) {
                appliedText = newText;
              },
              shareService: share,
              safService: saf,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Offline Privacy Shield'), findsOneWidget);
      expect(find.text('Email'), findsWidgets);
      expect(find.text('IP Address'), findsWidgets);

      // Tap "Apply to Document"
      final applyBtn = find.text('Apply to Document');
      expect(applyBtn, findsOneWidget);
      await tester.tap(applyBtn);
      await tester.pumpAndSettle();

      expect(appliedText, isNotNull);
      expect(
        appliedText,
        'Contact [REDACTED: EMAIL] at [REDACTED: IP_ADDRESS].',
      );
    },
  );

  testWidgets('PrivacyShieldSheet shares scrubbed copy via ShareService', (
    tester,
  ) async {
    final launcher = _FakeShareLauncher();
    final share = ShareService(launcher);
    final saf = FakeSafService();

    await tester.pumpWidget(
      localizedApp(
        home: Scaffold(
          body: PrivacyShieldSheet(
            text: 'Contact support@company.com now.',
            documentTitle: 'sample.txt',
            mimeType: 'text/plain',
            shareService: share,
            safService: saf,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final shareBtn = find.text('Share Scrubbed');
    expect(shareBtn, findsOneWidget);
    await tester.tap(shareBtn);
    await tester.pumpAndSettle();

    expect(launcher.lastFiles, isNotNull);
    expect(launcher.lastFiles!.length, 1);
    expect(launcher.lastFiles!.first.name, 'scrubbed_sample.txt');
    final sharedContent = String.fromCharCodes(launcher.lastFiles!.first.bytes);
    expect(sharedContent, 'Contact [REDACTED: EMAIL] now.');
  });
}
