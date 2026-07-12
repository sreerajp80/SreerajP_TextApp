import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/config/app_config.dart';
import 'package:text_data/core/config/config_service.dart';

void main() {
  test('valid config parses to the expected values', () async {
    const json = '''
    {
      "appName": "My App",
      "description": "Does things.",
      "version": "2.1.0",
      "build": "7",
      "details": {
        "Author": "Sreeraj P",
        "Email": "sreerajp@zohomail.in",
        "License": "Open source.",
        "AI used": "Example AI",
        "IDE used": "Example IDE",
        "Ignored": 42
      }
    }''';
    final service = ConfigService(loadAsset: (_) async => json);
    final config = await service.load();

    expect(config.appName, 'My App');
    expect(config.version, '2.1.0');
    expect(config.build, '7');
    expect(config.details, {
      'Author': 'Sreeraj P',
      'Email': 'sreerajp@zohomail.in',
      'License': 'Open source.',
      'AI used': 'Example AI',
      'IDE used': 'Example IDE',
    });
  });

  test('malformed JSON degrades to the safe fallback (no crash)', () async {
    final service = ConfigService(loadAsset: (_) async => '{ not json ');
    final config = await service.load();
    expect(config.appName, AppConfig.fallback.appName);
    expect(config.version, AppConfig.fallback.version);
  });

  test('a missing asset degrades to the fallback', () async {
    final service = ConfigService(
      loadAsset: (_) async => throw Exception('asset missing'),
    );
    final config = await service.load();
    expect(config.appName, AppConfig.fallback.appName);
  });

  test('non-object JSON degrades to the fallback', () async {
    final service = ConfigService(loadAsset: (_) async => '[1, 2, 3]');
    final config = await service.load();
    expect(config.appName, AppConfig.fallback.appName);
  });

  test('partial config fills missing fields from the fallback', () async {
    final service = ConfigService(
      loadAsset: (_) async => '{ "appName": "Only Name" }',
    );
    final config = await service.load();
    expect(config.appName, 'Only Name');
    expect(config.description, AppConfig.fallback.description);
    expect(config.details, isEmpty);
  });

  test('wrong field types are ignored, not thrown', () async {
    final service = ConfigService(
      loadAsset: (_) async => '{ "appName": 123, "details": "nope" }',
    );
    final config = await service.load();
    expect(config.appName, AppConfig.fallback.appName);
    expect(config.details, isEmpty);
  });
}
