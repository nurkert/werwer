import 'dart:async';
import 'dart:math';

import 'package:game_core/game_core.dart';
import 'package:game_host/game_host.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

/// Connections that came in encrypted but without the QR code's secret, on
/// both ends (the host sees them unverified, so does the player).
class _Unchecked implements Transport {
  final _inner = MemoryTransport();

  @override
  Stream<Connection> get connections => _inner.connections.map(_Side.new);

  Connection connect() => _Side(_inner.connect());

  @override
  Future<void> close() => _inner.close();
}

class _Side implements Connection, PeerTrust {
  _Side(this._raw, {this.onClose});
  final Connection _raw;
  final void Function()? onClose;

  @override
  bool get verified => false;

  @override
  List<int> get checkCode => const [4, 2, 7, 1];

  @override
  List<int>? get peerKey => List.filled(32, 9);

  @override
  Stream<String> get messages => _raw.messages;

  @override
  void send(String message) => _raw.send(message);

  @override
  Future<void> close() {
    onClose?.call();
    return _raw.close();
  }
}

/// Timers that only fire when told to.
class _Timers {
  final pending = <(Duration, void Function())>[];

  void Function() start(Duration after, void Function() callback) {
    final entry = (after, callback);
    pending.add(entry);
    return () => pending.remove(entry);
  }

  void fire(Duration after) {
    for (final entry in [...pending]) {
      if (entry.$1 == after && pending.remove(entry)) entry.$2();
    }
  }
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late GameHost host;
  late _Unchecked open;
  late _Timers timers;

  setUp(() {
    timers = _Timers();
    host = GameHost(
      settings: const GameSettings(),
      roomCode: '1234',
      random: Random(3),
      roomSecret: List.filled(32, 5),
      startTimer: timers.start,
    );
    open = _Unchecked();
    host.serve(open);
  });

  tearDown(() => host.close());

  PlayerLink join({void Function(List<int>, List<int>)? onRoomKeys}) =>
      PlayerLink(
        name: 'Ada',
        roomCode: '1234',
        dial: () async => open.connect(),
        onRoomKeys: onRoomKeys,
        startTimer: timers.start,
        random: Random(1),
      );

  test('without the QR code nothing from the host counts before the player '
      'confirmed the check code', () async {
    final owner = PlayerLink(
      name: 'Owner',
      roomCode: '1234',
      dial: () async => host.connectOwner(),
      startTimer: timers.start,
      random: Random(2),
    );
    List<int>? savedKey;
    final ada = join(onRoomKeys: (key, _) => savedKey = key);
    await settle();
    expect(ada.needsCodeConfirmation, isTrue);
    expect(ada.waitingForHost, isTrue);
    expect(ada.checkCode, [4, 2, 7, 1]);
    expect(ada.hostSaysAdmitted, isFalse);

    // The owner lets her in; the welcome arrives but waits for her check.
    owner.send(AdmitIntent(owner.pending.single.id, admit: true));
    await settle();
    expect(ada.hostSaysAdmitted, isTrue);
    expect(ada.view, isNull);
    expect(savedKey, isNull, reason: 'no keys before the code is confirmed');

    ada.confirmCheckCode();
    await settle();
    expect(ada.needsCodeConfirmation, isFalse);
    expect(ada.hostSaysAdmitted, isFalse);
    expect(ada.view!.seats.map((s) => s.name), ['Owner', 'Ada']);
    expect(savedKey, List.filled(32, 9));
    owner.close();
    ada.close();
  });

  test('a welcome that skips the waiting step is held all the same', () async {
    // Someone in the middle answers at once, as if the host had let her in.
    final fake = MemoryTransport();
    fake.connections.listen((c) {
      unawaited(
        c.messages.first.then((_) {
          c.send(
            Welcome(
              token: 'a' * tokenLength,
              you: const PlayerId('p9'),
            ).encode(),
          );
        }),
      );
    });
    List<int>? savedKey;
    final ada = PlayerLink(
      name: 'Ada',
      roomCode: '1234',
      dial: () async => _Side(fake.connect()),
      onRoomKeys: (key, _) => savedKey = key,
      startTimer: timers.start,
      random: Random(1),
    );
    await settle();
    await settle();
    expect(ada.needsCodeConfirmation, isTrue);
    expect(ada.status, isNot(LinkStatus.connected));
    expect(savedKey, isNull);
    ada.close();
  });

  test('an unchecked host cannot flood a player waiting at the code', () async {
    final fake = MemoryTransport();
    fake.connections.listen((c) {
      unawaited(
        c.messages.first.then((_) {
          // Answers with endless welcomes.
          for (var i = 0; i < 200; i++) {
            c.send(
              Welcome(
                token: 'a' * tokenLength,
                you: const PlayerId('p9'),
              ).encode(),
            );
          }
        }),
      );
    });
    var hungUp = false;
    final ada = PlayerLink(
      name: 'Ada',
      roomCode: '1234',
      dial: () async => _Side(fake.connect(), onClose: () => hungUp = true),
      startTimer: timers.start,
      random: Random(1),
    );
    for (var i = 0; i < 20; i++) {
      await settle();
    }
    expect(hungUp, isTrue, reason: 'past the limit the link hangs up');
    expect(ada.view, isNull);
    ada.close();
  });

  test('waiting for the owner is not taken for a dead connection', () async {
    final ada = join();
    await settle();
    expect(ada.waitingForHost, isTrue);
    // However long the owner takes, the link stays and so does its code.
    timers.fire(const LinkConfig().answer);
    await settle();
    expect(ada.status, isNot(LinkStatus.ended));
    expect(ada.waitingForHost, isTrue);
    expect(ada.needsCodeConfirmation, isTrue);
    ada.close();
  });

  test(
    'a player in another version is told which one the host speaks',
    () async {
      final raw = open.connect();
      final got = <String>[];
      final done = Completer<void>();
      raw.messages.listen(got.add, onDone: done.complete);
      raw.send(
        '{"v":${protocolVersion - 1},"type":"hello",'
        '"name":"Ada","room":"1234"}',
      );
      await done.future.timeout(const Duration(seconds: 2));
      expect(got, [encodeVersionNotice()]);
      expect(parseVersionNotice(got.single), protocolVersion);
    },
  );

  test('a host in another version ends the link with a clear reason', () async {
    final fake = MemoryTransport();
    fake.connections.listen((c) {
      unawaited(
        c.messages.first.then(
          (_) => c.send('{"v":${protocolVersion + 1},"type":"version"}'),
        ),
      );
    });
    final ada = PlayerLink(
      name: 'Ada',
      roomCode: '1234',
      dial: () async => fake.connect(),
      startTimer: timers.start,
      random: Random(1),
    );
    await settle();
    await settle();
    expect(ada.status, LinkStatus.ended);
    expect(ada.byeReason, ByeReason.version);
    expect(ada.hostVersion, protocolVersion + 1);
  });

  test('a version notice is strict', () {
    expect(parseVersionNotice('{"v":3,"type":"version"}'), 3);
    expect(parseVersionNotice('{"v":3,"type":"bye"}'), isNull);
    expect(parseVersionNotice('{"v":"3","type":"version"}'), isNull);
    expect(parseVersionNotice('x' * 100), isNull);
    expect(parseVersionNotice('[]'), isNull);
  });
}
