import 'dart:async';
import 'dart:convert';

import 'package:game_host/game_host.dart';
import 'package:secure_channel/secure_channel.dart';
import 'package:test/test.dart';

void main() {
  late SodiumSealer sealer;

  setUpAll(() async => sealer = SodiumSealer(await loadSodium()));

  group('sealed room', () {
    const room = '{"snapshot":"every secret of the game"}';

    test('opens with its key and epoch only', () async {
      final key = sealer.newKey();
      expect(key, hasLength(32));
      final sealed = await sealer.seal(room, key, epoch: 2);
      expect(sealed, isNot(contains('secret')));
      expect(await sealer.open(sealed, key, epoch: 2), room);
      expect(await sealer.open(sealed, sealer.newKey(), epoch: 2), isNull);
      expect(await sealer.open(sealed, key, epoch: 3), isNull);
    });

    test('every key is fresh', () {
      final keys = {
        for (var i = 0; i < 20; i++) base64Url.encode(sealer.newKey()),
      };
      expect(keys, hasLength(20));
    });

    test('a changed byte or a malformed copy does not open', () async {
      final key = sealer.newKey();
      final sealed = await sealer.seal(room, key, epoch: 0);
      final parts = sealed.split('.');
      final body = base64Url.decode(parts[1])..[5] ^= 1;
      final tampered = '${parts[0]}.${base64Url.encode(body)}';
      expect(await sealer.open(tampered, key, epoch: 0), isNull);
      for (final bad in ['', 'x', '$sealed.more', parts[0], 'a.b']) {
        expect(await sealer.open(bad, key, epoch: 0), isNull);
      }
      expect(
        await sealer.open(sealed, key.take(16).toList(), epoch: 0),
        isNull,
      );
    });
  });

  group('candidate entrance', () {
    late HostKeys keys;
    late MemoryTransport wire;
    late CandidateEntrance entrance;
    final passed = <Connection>[];

    setUp(() async {
      keys = await HostKeys.generate();
      wire = MemoryTransport();
      entrance = CandidateEntrance(wire, keys);
      passed.clear();
      entrance.connections.listen(passed.add);
    });

    tearDown(() => entrance.close());

    test('lets in whoever shows the candidate secret', () async {
      final witness = await connectSecure(
        wire.connect(),
        hostKey: keys.publicKey,
        roomSecret: keys.roomSecret,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(passed, hasLength(1));
      final got = Completer<String>();
      passed.single.messages.listen(got.complete);
      witness.send('the key');
      expect(await got.future, 'the key');
    });

    test('hangs up on anyone without the secret', () async {
      // Encrypted, but unverified: no way to the successor.
      final stranger = await connectSecure(wire.connect());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(passed, isEmpty);
      final closed = Completer<void>();
      stranger.messages.listen(null, onDone: closed.complete);
      await closed.future.timeout(const Duration(seconds: 2));
    });

    test('a witness cannot be fooled by another candidate', () async {
      // Someone else opens an entrance and waits for the witness, who
      // dials with the real successor's key and secret.
      final elsewhere = MemoryTransport();
      final fake = CandidateEntrance(elsewhere, await HostKeys.generate());
      addTearDown(fake.close);
      await expectLater(
        connectSecure(
          elsewhere.connect(),
          hostKey: keys.publicKey,
          roomSecret: keys.roomSecret,
          timeout: const Duration(seconds: 1),
        ),
        throwsA(isA<SecureChannelError>()),
      );
    });
  });
}
