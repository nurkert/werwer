import 'dart:convert';

import 'package:game_core/game_core.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

void main() {
  final key = List.generate(32, (i) => i);
  final secret = List.generate(32, (i) => 255 - i);
  final candidate = Candidate(key: key, secret: secret);

  test('takeover messages round-trip', () {
    final client = Hello(
      name: 'Ada',
      room: '1234',
      candidate: candidate,
      epoch: 2,
    );
    final hello = ClientMessage.parse(client.encode()) as Hello;
    expect(hello.candidate!.key, key);
    expect(hello.candidate!.secret, secret);
    expect(hello.epoch, 2);
    expect(hello.encode(), client.encode());

    final messages = <HostMessage>[
      const Welcome(token: '0123456789abcdef0123456789abcdef', you: _p1),
      const Welcome(
        token: '0123456789abcdef0123456789abcdef',
        you: _p1,
        epoch: 3,
      ),
      const Custody(epoch: 1, version: 9, sealed: 'abc'),
      const Custody(epoch: 1, version: 9, sealed: 'abc', takeOver: true),
      const Custody.drop(epoch: 1),
      Witness(epoch: 1, key: key, successor: candidate),
      Witness(epoch: 1, key: key, successor: candidate, release: true),
      const Witness(epoch: 1),
    ];
    for (final m in messages) {
      expect(HostMessage.parse(m.encode()).encode(), m.encode());
    }
    final release = Release(epoch: 4, key: key);
    final back = Release.parse(release.encode());
    expect(back.epoch, 4);
    expect(back.key, key);
  });

  test('a hello without a candidate stays as small as before', () {
    const hello = Hello(name: 'Ada', room: '1234');
    expect(hello.encode(), isNot(contains('ck')));
    expect(hello.encode(), isNot(contains('epoch')));
  });

  test('malformed takeover messages are refused', () {
    String host(Map<String, Object?> fields) =>
        jsonEncode({'v': protocolVersion, ...fields});
    final b64 = base64Url.encode(key);
    final bad = [
      host({'type': 'custody', 'epoch': 1, 'version': 1}),
      host({
        'type': 'custody',
        'epoch': 1,
        'version': 1,
        'sealed': 'x' * (maxCustody + 1),
      }),
      host({'type': 'custody', 'epoch': -1, 'version': 1, 'sealed': ''}),
      host({'type': 'witness', 'epoch': 1, 'key': 'short'}),
      host({'type': 'witness', 'epoch': 1, 'key': b64, 'sk': b64}),
      host({'type': 'witness', 'epoch': maxEpoch + 1}),
    ];
    for (final raw in bad) {
      expect(() => HostMessage.parse(raw), throwsA(isA<ProtocolError>()));
    }
    expect(
      () => ClientMessage.parse(
        jsonEncode({
          'v': protocolVersion,
          'type': 'hello',
          'name': 'Ada',
          'room': '1234',
          'ck': b64,
        }),
      ),
      throwsA(isA<ProtocolError>()),
    );
    for (final raw in [
      '{"v":$protocolVersion,"type":"release","epoch":1,"key":"x"}',
      '{"v":$protocolVersion,"type":"other","epoch":1,"key":"$b64"}',
      '{"v":$protocolVersion,"type":"release","key":"$b64"}',
    ]) {
      expect(() => Release.parse(raw), throwsA(isA<ProtocolError>()));
    }
  });

  test('a candidate needs 32-byte halves', () {
    expect(
      () => Candidate(key: key.take(31).toList(), secret: secret),
      throwsArgumentError,
    );
  });
}

const PlayerId _p1 = PlayerId('p1');
