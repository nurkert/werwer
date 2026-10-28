@TestOn('vm')
library;

import 'dart:math';

import 'package:game_host/game_host.dart';
import 'package:game_host/relay.dart';
import 'package:protocol/protocol.dart';
import 'package:secure_channel/secure_channel.dart';
import 'package:test/test.dart';
import 'package:whowolf_server/relay_server.dart';

/// Players who come through the relay (from the app or a browser page the
/// relay served) meet the same handshake: without the room's key from the
/// QR code nobody gets in, and the relay only ever sees ciphertext.
void main() {
  test('through the relay only the right key gets a seat', () async {
    final relay = await RelayServer.start(address: '127.0.0.1', port: 0);
    final server = Uri.parse('ws://127.0.0.1:${relay.port}');
    final keys = await HostKeys.generate();
    final other = await HostKeys.generate();
    final host = GameHost(roomCode: '1357', random: Random(1));
    final transport = await RelayTransport.open(server);
    host.serve(SecureTransport(transport, keys));

    for (final (key, secret) in [
      (keys.publicKey, other.roomSecret),
      (other.publicKey, keys.roomSecret),
      (other.publicKey, other.roomSecret),
    ]) {
      await expectLater(
        connectSecure(
          await dialRelay(server, transport.roomId),
          hostKey: key,
          roomSecret: secret,
        ),
        throwsA(isA<SecureChannelError>()),
      );
    }

    final player = await connectSecure(
      await dialRelay(server, transport.roomId),
      hostKey: keys.publicKey,
      roomSecret: keys.roomSecret,
    );
    final first = player.messages.first;
    player.send(const Hello(name: 'Ada', room: '1357', web: true).encode());
    expect(HostMessage.parse(await first), isA<Welcome>());
    await player.close();
    await host.close();
    await relay.close();
  });
}
