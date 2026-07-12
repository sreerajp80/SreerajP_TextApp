import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/config/app_config.dart';
import 'package:text_data/core/config/config_service.dart';
import 'package:text_data/shell/settings/sections/about_section.dart';

import '../../support/test_support.dart';

void main() {
  testWidgets('About renders configured dynamic details', (tester) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const config = AppConfig(
      appName: 'Text & Data App',
      description: 'A test description.',
      version: '1.0.0',
      build: '7',
      details: {
        'Author': 'Sreeraj P',
        'Email': 'test@example.com',
        'License': 'All libraries used are open source.',
        'AI used': 'Example AI',
        'IDE used': 'Example IDE',
        '': 'Hidden label',
        'Hidden value': ' ',
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appConfigProvider.overrideWith((ref) async => config)],
        child: localizedApp(home: const Scaffold(body: AboutSection())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AI used'), findsOneWidget);
    expect(find.text('Example AI'), findsOneWidget);
    expect(find.text('IDE used'), findsOneWidget);
    expect(find.text('Example IDE'), findsOneWidget);
    expect(find.text('Hidden label'), findsNothing);
    expect(find.text('Hidden value'), findsNothing);
    expect(
      tester.widget<ListTile>(find.widgetWithText(ListTile, 'Email')).onTap,
      isNotNull,
    );
    final footer = find.text('Made with ❤ from India');
    expect(footer, findsOneWidget);
    expect(
      find.ancestor(of: footer, matching: find.byType(Center)),
      findsOneWidget,
    );
  });
}
