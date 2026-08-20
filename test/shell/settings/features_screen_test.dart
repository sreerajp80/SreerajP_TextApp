import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sreerajp_textapp/shell/settings/features_screen.dart';

import '../../support/test_support.dart';

void main() {
  testWidgets('FeaturesScreen renders categories and feature highlights', (
    tester,
  ) async {
    // Tall viewport to lay out all categories
    tester.view.physicalSize = const Size(1000, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(localizedApp(home: const FeaturesScreen()));
    await tester.pumpAndSettle();

    // Verify header
    expect(find.text('SreerajP Text App Features'), findsOneWidget);
    expect(find.byIcon(Icons.stars_rounded), findsOneWidget);

    // Verify all 8 categories
    expect(find.text('MULTI-FORMAT DOCUMENT ENGINE'), findsOneWidget);
    expect(find.text('SMART CODE & TEXT EDITOR'), findsOneWidget);
    expect(find.text('DATA ANALYSIS & SQL QUERYING'), findsOneWidget);
    expect(find.text('P2P LAN SYNC & OPTICAL AIRQR'), findsOneWidget);
    expect(find.text('PRIVACY, SECURITY & VAULT'), findsOneWidget);
    expect(find.text('VOICE & TEXT-TO-SPEECH (TTS)'), findsOneWidget);
    expect(find.text('EXPORT, CONVERSION & PRINTING'), findsOneWidget);
    expect(find.text('PERSONALIZATION & ACCESSIBILITY'), findsOneWidget);

    // Verify specific feature highlights
    expect(find.text('5 Core Formats Supported'), findsOneWidget);
    expect(
      find.text('Multi-Cursor Editing & Precision Carets'),
      findsOneWidget,
    );
    expect(find.text('In-Memory SQLite SQL Queries'), findsOneWidget);
    expect(find.text('Local Wi-Fi P2P Device Sync'), findsOneWidget);
    expect(find.text('Biometric & App PIN Lock'), findsOneWidget);
    expect(find.text('Bilingual English & Malayalam TTS'), findsOneWidget);
  });
}
