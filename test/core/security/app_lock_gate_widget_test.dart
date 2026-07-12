import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/security/app_lock_gate.dart';
import 'package:text_data/core/security/biometric_service.dart';
import 'package:text_data/core/security/security_providers.dart';
import 'package:text_data/core/security/window_security.dart';
import 'package:text_data/core/storage/key_value_store.dart';

import '../../support/test_support.dart';

/// Captures the FLAG_SECURE calls the app makes.
class FakeWindowSecurity implements WindowSecurity {
  final List<bool> calls = [];

  @override
  Future<void> setSecure(bool secure) async => calls.add(secure);
}

void main() {
  Future<FakeWindowSecurity> pumpGate(
    WidgetTester tester, {
    required KeyValueStore store,
  }) async {
    final window = FakeWindowSecurity();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreSyncProvider.overrideWithValue(store),
          biometricServiceProvider
              .overrideWithValue(const UnavailableBiometricService()),
          windowSecurityProvider.overrideWithValue(window),
        ],
        child: localizedApp(
          home: ScreenshotProtector(
            child: AppLockGate(
              child: const Scaffold(body: Text('SECRET-CHILD')),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return window;
  }

  testWidgets('locked: shows the lock screen and hides the app', (tester) async {
    final store =
        await inMemoryKeyValueStore({'security.app_lock_enabled': true});
    await pumpGate(tester, store: store);

    expect(find.text('Enter your PIN'), findsOneWidget);
    expect(find.text('SECRET-CHILD'), findsNothing);
  });

  testWidgets('unlocked (app-lock off): shows the app', (tester) async {
    final store = await inMemoryKeyValueStore(); // app-lock off by default
    await pumpGate(tester, store: store);

    expect(find.text('SECRET-CHILD'), findsOneWidget);
    expect(find.text('Enter your PIN'), findsNothing);
  });

  testWidgets('screenshot protection on -> FLAG_SECURE set true',
      (tester) async {
    final store = await inMemoryKeyValueStore(); // protection on by default
    final window = await pumpGate(tester, store: store);

    expect(window.calls, contains(true));
  });

  testWidgets('screenshot protection off -> FLAG_SECURE set false',
      (tester) async {
    final store = await inMemoryKeyValueStore(
      {'security.screenshot_protection': false},
    );
    final window = await pumpGate(tester, store: store);

    expect(window.calls, contains(false));
    expect(window.calls, isNot(contains(true)));
  });
}
