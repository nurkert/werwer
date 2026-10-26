import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:secure_channel/secure_channel.dart';
import 'package:test/test.dart';

List<int> hex(String s) => [
  for (var i = 0; i < s.length; i += 2)
    int.parse(s.substring(i, i + 2), radix: 16),
];

String toHex(List<int> b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

Future<SimpleKeyPair> keys(String privateHex) =>
    X25519().newKeyPairFromSeed(hex(privateHex));

void main() {
  final vectors =
      (jsonDecode(File('test/vectors/noise.json').readAsStringSync())
              as Map<String, Object?>)['vectors']!
          as List<Object?>;

  for (final raw in vectors) {
    final v = raw! as Map<String, Object?>;
    final name = v['protocol_name']! as String;
    test('matches the official vector $name', () async {
      final pattern = NoisePattern.values.firstWhere(
        (p) => p.protocolName == name,
      );
      final psk = (v['init_psks'] as List<Object?>?)?.cast<String>().first;
      final init = await NoiseHandshake.initiator(
        pattern,
        prologue: hex(v['init_prologue']! as String),
        remoteStatic: v['init_remote_static'] == null
            ? null
            : hex(v['init_remote_static']! as String),
        psk: psk == null ? null : hex(psk),
        ephemeral: await keys(v['init_ephemeral']! as String),
      );
      final resp = await NoiseHandshake.responder(
        pattern,
        prologue: hex(v['resp_prologue']! as String),
        staticKeys: v['resp_static'] == null
            ? null
            : await keys(v['resp_static']! as String),
        psk: psk == null ? null : hex(psk),
        ephemeral: await keys(v['resp_ephemeral']! as String),
      );
      final messages = (v['messages']! as List<Object?>)
          .cast<Map<String, Object?>>();
      NoiseCipher? initSend;
      NoiseCipher? initRecv;
      NoiseCipher? respSend;
      NoiseCipher? respRecv;
      for (final (i, m) in messages.indexed) {
        final payload = hex(m['payload']! as String);
        final expected = m['ciphertext']! as String;
        final fromInitiator = i.isEven;
        if (!init.isComplete) {
          final writer = fromInitiator ? init : resp;
          final reader = fromInitiator ? resp : init;
          final c = await writer.writeMessage(payload);
          expect(toHex(c), expected, reason: 'handshake message $i');
          expect(toHex(await reader.readMessage(c)), toHex(payload));
          if (init.isComplete) {
            expect(toHex(init.handshakeHash), v['handshake_hash']);
            expect(toHex(resp.handshakeHash), v['handshake_hash']);
            (initSend, initRecv) = await init.split();
            (respSend, respRecv) = await resp.split();
          }
        } else {
          final send = fromInitiator ? initSend! : respSend!;
          final recv = fromInitiator ? respRecv! : initRecv!;
          final c = await send.encrypt(payload);
          expect(toHex(c), expected, reason: 'transport message $i');
          expect(toHex(await recv.decrypt(c)), toHex(payload));
        }
      }
    });
  }

  test('a wrong room secret or host key fails the handshake', () async {
    final host = await X25519().newKeyPair();
    final hostPub = (await host.extractPublicKey()).bytes;
    final secret = List<int>.generate(32, (i) => i);
    final wrong = List<int>.generate(32, (i) => 31 - i);
    final other =
        (await (await X25519().newKeyPair()).extractPublicKey()).bytes;

    for (final (key, psk) in [(hostPub, wrong), (other, secret)]) {
      final init = await NoiseHandshake.initiator(
        NoisePattern.nkPsk2,
        remoteStatic: key,
        psk: psk,
      );
      final resp = await NoiseHandshake.responder(
        NoisePattern.nkPsk2,
        staticKeys: host,
        psk: secret,
      );
      final m1 = await init.writeMessage();
      Future<void> run() async {
        await resp.readMessage(m1);
        await init.readMessage(await resp.writeMessage());
      }

      await expectLater(run(), throwsA(isA<NoiseError>()));
    }
  });
}
