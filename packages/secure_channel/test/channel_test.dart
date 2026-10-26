import 'dart:async';
import 'dart:convert';

import 'package:game_host/game_host.dart';
import 'package:secure_channel/secure_channel.dart';
import 'package:test/test.dart';

/// A memory transport whose frames can be watched and altered on the way.
class Wire implements Transport {
  final _inner = MemoryTransport();
  final seen = <String>[];
  String Function(String frame)? tamper;

  @override
  Stream<Connection> get connections => _inner.connections;

  Connection connect() => _Tap(this, _inner.connect());

  @override
  Future<void> close() => _inner.close();
}

class _Tap implements Connection {
  _Tap(this._wire, this._raw);
  final Wire _wire;
  final Connection _raw;

  @override
  Stream<String> get messages => _raw.messages.map((m) {
    _wire.seen.add(m);
    return m;
  });

  @override
  void send(String message) {
    _wire.seen.add(message);
    _raw.send(_wire.tamper?.call(message) ?? message);
  }

  @override
  Future<void> close() => _raw.close();
}

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  late HostKeys keys;
  late Wire wire;
  late SecureTransport secure;
  final accepted = <SecureConnection>[];
  final received = <String>[];

  setUp(() async {
    keys = await HostKeys.generate();
    wire = Wire();
    secure = SecureTransport(wire, keys);
    accepted.clear();
    received.clear();
    secure.connections.listen((c) {
      final s = c as SecureConnection;
      accepted.add(s);
      // Echo server: replies with the message reversed.
      s.messages.listen((m) {
        received.add(m);
        s.send(m.split('').reversed.join());
      });
    });
  });

  test('with the QR secret the host is authenticated', () async {
    final client = await connectSecure(
      wire.connect(),
      hostKey: keys.publicKey,
      roomSecret: keys.roomSecret,
    );
    final replies = <String>[];
    client.messages.listen(replies.add);
    client.send('hello werewolf');
    await settle();
    expect(replies, ['flowerew olleh']);
    expect(client.verified, isTrue);
    expect(accepted.single.verified, isTrue);
    // Nothing readable on the wire.
    expect(wire.seen.any((f) => f.contains('werewolf')), isFalse);
  });

  test('without the QR code both sides show the same check code', () async {
    final client = await connectSecure(wire.connect());
    await settle();
    expect(client.verified, isFalse);
    expect(accepted.single.verified, isFalse);
    expect(client.checkCode, accepted.single.checkCode);
    expect(client.checkCode, hasLength(checkLength));
  });

  test('a wrong room secret or a fake host fails', () async {
    final other = await HostKeys.generate();
    await expectLater(
      connectSecure(
        wire.connect(),
        hostKey: keys.publicKey,
        roomSecret: other.roomSecret,
      ),
      throwsA(isA<NoiseError>()),
    );
    await expectLater(
      connectSecure(
        wire.connect(),
        hostKey: other.publicKey,
        roomSecret: keys.roomSecret,
      ),
      throwsA(isA<NoiseError>()),
    );
    await settle();
    // NKpsk2 checks the secret with the first real message: a connection
    // with the wrong secret may get past the handshake but never delivers
    // anything, and it is closed.
    expect(received, isEmpty);
  });

  test('messages are padded to fixed sizes', () async {
    final client = await connectSecure(
      wire.connect(),
      hostKey: keys.publicKey,
      roomSecret: keys.roomSecret,
    );
    client.messages.listen((_) {});
    wire.seen.clear();
    client
      ..send('x')
      ..send('a much longer message about who the werewolf might be');
    await settle();
    final sizes = wire.seen.map((f) => base64Url.decode(f).length).toSet();
    expect(sizes, {paddingSteps.first + 16});
  });

  test('a tampered frame ends the connection', () async {
    final client = await connectSecure(
      wire.connect(),
      hostKey: keys.publicKey,
      roomSecret: keys.roomSecret,
    );
    final done = Completer<void>();
    client.messages.listen((_) {}, onDone: done.complete);
    wire.tamper = (frame) {
      final bytes = base64Url.decode(frame);
      bytes[10] ^= 1;
      return base64Url.encode(bytes);
    };
    client.send('vote for Bo');
    await done.future.timeout(const Duration(seconds: 2));
  });

  test('host keys survive saving and loading', () async {
    final back = await HostKeys.fromJson(await keys.toJson());
    expect(back.publicKey, keys.publicKey);
    expect(back.roomSecret, keys.roomSecret);
  });
}
