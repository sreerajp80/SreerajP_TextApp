import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/editor/external_change.dart';

import '../../support/test_support.dart';

/// A minimal document that only does the external-change part, so the shared
/// logic is tested on its own (no file format, no editor).
class _FakeDocument extends ChangeNotifier with ExternalChangeMixin {
  final FakeSafService saf;
  final String uri;
  int reloadCount = 0;
  bool reloadSucceeds = true;

  _FakeDocument(this.saf, this.uri);

  @override
  FakeSafService get diskSaf => saf;

  @override
  String get diskUri => uri;

  @override
  void notifyDiskWatch() => notifyListeners();

  @override
  bool get isDirty => false;

  @override
  Future<bool> reloadFromDisk() async {
    reloadCount++;
    if (!reloadSucceeds) return false;
    await markReloaded();
    return true;
  }
}

Uint8List _bytes(String text) => Uint8List.fromList(text.codeUnits);

void main() {
  const uri = 'content://a';

  _FakeDocument documentWith({int? modifiedAt}) {
    final saf = FakeSafService(
      contents: {uri: _bytes('hello')},
      modifiedTimes: modifiedAt == null ? const {} : {uri: modifiedAt},
    );
    return _FakeDocument(saf, uri);
  }

  test('no warning while the file is untouched', () async {
    final doc = documentWith(modifiedAt: 1000);
    await doc.captureDiskBaseline();

    await doc.checkForExternalChange();

    expect(doc.externalChangeDetected, isFalse);
  });

  test('a newer timestamp on disk raises the warning and notifies', () async {
    final doc = documentWith(modifiedAt: 1000);
    await doc.captureDiskBaseline();
    var notifications = 0;
    doc.addListener(() => notifications++);

    doc.saf.changeOnDisk(uri, _bytes('changed'));
    await doc.checkForExternalChange();

    expect(doc.externalChangeDetected, isTrue);
    expect(notifications, 1);
  });

  test('a provider with no timestamp never warns', () async {
    // No modified time at all: detection must stay quiet rather than guess.
    final doc = documentWith();
    await doc.captureDiskBaseline();

    doc.saf.contents[uri] = _bytes('changed');
    await doc.checkForExternalChange();

    expect(doc.externalChangeDetected, isFalse);
  });

  test('the warning is raised once, not on every check', () async {
    final doc = documentWith(modifiedAt: 1000);
    await doc.captureDiskBaseline();
    doc.saf.changeOnDisk(uri, _bytes('changed'));
    var notifications = 0;
    doc.addListener(() => notifications++);

    await doc.checkForExternalChange();
    await doc.checkForExternalChange();

    expect(notifications, 1);
  });

  test(
    'dismiss hides the warning and does not report the same change again',
    () async {
      final doc = documentWith(modifiedAt: 1000);
      await doc.captureDiskBaseline();
      doc.saf.changeOnDisk(uri, _bytes('changed'));
      await doc.checkForExternalChange();

      doc.dismissExternalChange();
      expect(doc.externalChangeDetected, isFalse);

      // The baseline moved forward, so the same change is old news...
      await Future<void>.delayed(Duration.zero);
      await doc.checkForExternalChange();
      expect(doc.externalChangeDetected, isFalse);

      // ...but a later change warns again.
      doc.saf.changeOnDisk(uri, _bytes('changed twice'));
      await doc.checkForExternalChange();
      expect(doc.externalChangeDetected, isTrue);
    },
  );

  test('after a reload the same change is not reported again', () async {
    final doc = documentWith(modifiedAt: 1000);
    await doc.captureDiskBaseline();
    doc.saf.changeOnDisk(uri, _bytes('changed'));
    await doc.checkForExternalChange();

    expect(await doc.reloadFromDisk(), isTrue);
    expect(doc.externalChangeDetected, isFalse);

    await doc.checkForExternalChange();
    expect(doc.externalChangeDetected, isFalse);
  });
}
