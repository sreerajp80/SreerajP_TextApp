import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/sync/sync_crypto.dart';
import 'package:text_data/sync/sync_transport.dart';

void main() {
  const loopback = '127.0.0.1';

  test('happy path: connect, then receive the pushed payload', () async {
    final code = SyncCrypto.generatePairingCode();
    final host = await SyncHost.start(code: code);
    addTearDown(host.stop);

    SyncClient? client;
    try {
      client = await SyncClient.connect(
        host: loopback,
        port: host.port,
        code: code,
      );
      await host.clientConnected;
      expect(host.hasClient, isTrue);

      const payload = '{"hello":"world"}';
      await host.sendToConnectedClient(payload);
      expect(await client.awaitPayload(), payload);
    } finally {
      await client?.close();
    }
  });

  test('wrong code is rejected and never connects', () async {
    final host = await SyncHost.start(code: SyncCrypto.generatePairingCode());
    addTearDown(host.stop);

    // A different valid code derives a different key -> GCM tag fails.
    final wrong = SyncCrypto.generatePairingCode();
    await expectLater(
      SyncClient.connect(host: loopback, port: host.port, code: wrong),
      throwsA(isA<SyncTransportException>()),
    );
    expect(host.hasClient, isFalse);
  });

  test('host keeps listening after a wrong code, accepts a good one next',
      () async {
    final code = SyncCrypto.generatePairingCode();
    final host = await SyncHost.start(code: code);
    addTearDown(host.stop);

    await expectLater(
      SyncClient.connect(
          host: loopback, port: host.port, code: SyncCrypto.generatePairingCode()),
      throwsA(isA<SyncTransportException>()),
    );

    final client =
        await SyncClient.connect(host: loopback, port: host.port, code: code);
    addTearDown(client.close);
    await host.clientConnected;
    expect(host.hasClient, isTrue);
  });

  test('sendToConnectedClient with no client throws', () async {
    final host = await SyncHost.start(code: SyncCrypto.generatePairingCode());
    addTearDown(host.stop);
    expect(
      () => host.sendToConnectedClient('data'),
      throwsA(isA<SyncTransportException>()),
    );
  });
}
