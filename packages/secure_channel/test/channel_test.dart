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
      throwsA(isA<SecureChannelError>()),
    );
    await expectLater(
      connectSecure(
        wire.connect(),
        hostKey: other.publicKey,
        roomSecret: keys.roomSecret,
      ),
      throwsA(isA<SecureChannelError>()),
    );
    await settle();
    // The host checks the secret before it lets the connection through.
    expect(accepted, isEmpty);
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
    expect(sizes, {paddingSteps.first + 17}); // secretstream adds 17 bytes
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

  test('a replayed or reordered frame ends the connection', () async {
    for (final attack in ['replay', 'reorder']) {
      accepted.clear();
      final raw = wire.connect();
      final client = await connectSecure(
        raw,
        hostKey: keys.publicKey,
        roomSecret: keys.roomSecret,
      );
      // The host drops the connection, so the player's stream ends.
      final done = Completer<void>();
      client.messages.listen((_) {}, onDone: done.complete);
      final held = <String>[];
      wire.tamper = (frame) {
        held.add(frame);
        return frame;
      };
      client
        ..send('one')
        ..send('two');
      await settle();
      wire.tamper = null;
      // Write the captured frames straight onto the wire again.
      if (attack == 'replay') {
        raw.send(held.first);
      } else {
        raw
          ..send(held.last)
          ..send(held.first);
      }
      await done.future.timeout(const Duration(seconds: 2));
      wire.tamper = null;
    }
  });

  test(
    'without the QR code a man in the middle gets other check codes',
    () async {
      // The attacker sits on the wire and runs its own handshakes with both
      // sides; the codes it produces only match by chance (1 in 65536).
      final attackerKeys = await HostKeys.generate();
      final towardsPlayer = Wire();
      final fake = SecureTransport(towardsPlayer, attackerKeys);
      final relayed = Completer<SecureConnection>();
      fake.connections.listen((c) => relayed.complete(c as SecureConnection));
      final player = await connectSecure(towardsPlayer.connect());
      final towardsHost = await connectSecure(wire.connect());
      await settle();
      // What the attacker sees matches each side, but the two screens at
      // the table (player and real host) disagree.
      expect(player.checkCode, (await relayed.future).checkCode);
      expect(towardsHost.checkCode, accepted.single.checkCode);
      expect(player.checkCode, isNot(accepted.single.checkCode));
    },
  );

  test('a reveal that does not match the commitment is refused', () async {
    // Swap the player's key after the host has shown its own.
    wire.tamper = (frame) {
      final json = frame.startsWith('{') ? jsonDecode(frame) : null;
      if (json is Map && json['e'] is String) {
        return jsonEncode({'e': base64Url.encode(List.filled(32, 7))});
      }
      return frame;
    };
    await expectLater(
      connectSecure(wire.connect()),
      throwsA(isA<SecureChannelError>()),
    );
    await settle();
    expect(accepted, isEmpty);
  });

  test('old or unknown handshakes are dropped', () async {
    for (final hello in [
      jsonEncode({'noise': 1, 'p': 'nn', 'm': 'AAAA'}),
      jsonEncode({'secure': 2, 'p': 'qr', 'e': 'AAAA'}),
      jsonEncode({'secure': 3, 'p': 'xx'}),
      'x' * 5000,
    ]) {
      final raw = wire.connect();
      final done = Completer<void>();
      raw.messages.listen((_) {}, onDone: done.complete);
      raw.send(hello);
      await done.future.timeout(const Duration(seconds: 2));
    }
    expect(accepted, isEmpty);
  });

  test('a whole recorded connection cannot be played again', () async {
    // Someone on the Wi-Fi (or the relay) records every frame the player
    // sends, then opens a new connection and sends them all again.
    final sent = <String>[];
    wire.tamper = (frame) {
      sent.add(frame);
      return frame;
    };
    final client = await connectSecure(
      wire.connect(),
      hostKey: keys.publicKey,
      roomSecret: keys.roomSecret,
    );
    client.send('{"type":"hello"}');
    await settle();
    wire.tamper = null;
    expect(accepted, hasLength(1));
    expect(received, ['{"type":"hello"}']);

    final replay = wire.connect();
    final done = Completer<void>();
    replay.messages.listen((_) {}, onDone: done.complete);
    sent.forEach(replay.send);
    // The host's fresh value for this connection gives other keys: the old
    // confirm does not open, the host hangs up and nothing is delivered.
    await done.future.timeout(const Duration(seconds: 2));
    expect(accepted, hasLength(1));
    expect(received, hasLength(1));
  });

  test('only a few joins without the QR code start per minute', () async {
    var now = 0;
    final slow = SecureTransport(Wire(), keys, clock: () => now);
    final limited = Wire();
    final gate = SecureTransport(limited, keys, clock: () => now);
    var admitted = 0;
    gate.connections.listen((_) => admitted++);
    Future<bool> tryJoin() async {
      try {
        await connectSecure(limited.connect());
        return true;
      } on SecureChannelError {
        return false;
      }
    }

    for (var i = 0; i < maxUncheckedJoinsPerMinute; i++) {
      expect(await tryJoin(), isTrue);
    }
    expect(await tryJoin(), isFalse);
    // With the QR code nothing is limited.
    expect(
      await connectSecure(
        limited.connect(),
        hostKey: keys.publicKey,
        roomSecret: keys.roomSecret,
      ),
      isA<SecureConnection>(),
    );
    now += 61000;
    expect(await tryJoin(), isTrue);
    await settle();
    expect(admitted, maxUncheckedJoinsPerMinute + 2);
    await slow.close();
  });

  test('half-open connections cannot pile up', () async {
    // Silent sockets that never finish a handshake.
    final silent = [for (var i = 0; i < maxHandshakes; i++) wire.connect()];
    for (final c in silent) {
      c.messages.listen((_) {});
    }
    await settle();
    final late = wire.connect();
    final done = Completer<void>();
    late.messages.listen((_) {}, onDone: done.complete);
    await done.future.timeout(const Duration(seconds: 1));
  });

  test('host keys survive saving and loading', () async {
    final back = await HostKeys.fromJson(await keys.toJson());
    expect(back.publicKey, keys.publicKey);
    expect(back.roomSecret, keys.roomSecret);
  });
}
