import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/storage/key_value_store.dart';

Future<void> main() async {
  // The settings store is opened once here so the UI (theme, tabs, onboarding)
  // can read it synchronously from the first frame.
  WidgetsFlutterBinding.ensureInitialized();
  final store = await KeyValueStore.open();

  runApp(
    ProviderScope(
      overrides: [
        keyValueStoreSyncProvider.overrideWithValue(store),
      ],
      child: const TextDataApp(),
    ),
  );
}
