// Whole games in which the host goes away and another player takes over:
// successor and witness, the witness's own vote, a host that leaves on
// purpose, and a host that comes back after it was replaced.
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:game_core/game_core.dart';
import 'package:game_host/game_host.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

/// Not cryptography: stands in for the libsodium sealer (tested in
/// secure_channel) and only checks that the right key opens the room.
class FakeSealer implements RoomSealer {
  FakeSealer(this._random);

  final Random _random;

  /// While set, sealing waits for it: the successor's copy falls behind.
  Completer<void>? hold;

  @override
  List<int> newKey() => List.generate(32, (_) => _random.nextInt(256));

  @override
  Future<String> seal(String room, List<int> key, {required int epoch}) async {
    await hold?.future;
    return _seal(room, key, epoch: epoch);
  }

  String _seal(String room, List<int> key, {required int epoch}) =>
      base64Url.encode(
        utf8.encode(
          jsonEncode({'k': base64Url.encode(key), 'e': epoch, 'r': room}),
        ),
      );

  @override
  Future<String?> open(
    String sealed,
    List<int> key, {
    required int epoch,
  }) async {
    final json =
        jsonDecode(utf8.decode(base64Url.decode(sealed)))
            as Map<String, Object?>;
    if (json['k'] != base64Url.encode(key) || json['e'] != epoch) return null;
    return json['r']! as String;
  }
}

const fast = LinkConfig(
  ping: Duration(milliseconds: 100),
  resend: Duration(milliseconds: 100),
  answer: Duration(seconds: 2),
  firstRetry: Duration(milliseconds: 10),
  maxRetry: Duration(milliseconds: 60),
);

/// The Wi-Fi: wherever the room is hosted right now, and the candidates'
/// entrances (reachable only with the right secret, like the real
/// handshake).
class Lan {
  MemoryTransport? room;
  final entrances = <String, (Candidate, MemoryTransport)>{};

  Future<Connection> dialRoom() async {
    final room = this.room;
    if (room == null) throw StateError('no host');
    return room.connect();
  }

  Future<Connection> dialCandidate(Candidate c) async {
    final found = entrances[base64Url.encode(c.key)];
    if (found == null ||
        base64Url.encode(found.$1.secret) != base64Url.encode(c.secret)) {
      throw StateError('no such candidate');
    }
    return found.$2.connect();
  }
}

/// An entrance that withdraws itself when closed.
class Entrance implements Transport {
  Entrance(this.lan, this.candidate) {
    lan.entrances[base64Url.encode(candidate.key)] = (candidate, inner);
  }

  final Lan lan;
  final Candidate candidate;
  final inner = MemoryTransport();

  @override
  Stream<Connection> get connections => inner.connections;

  @override
  Future<void> close() async {
    lan.entrances.remove(base64Url.encode(candidate.key));
    await inner.close();
  }
}

/// One phone at the table: its link, its part in a takeover, and the host
/// it runs once it took over.
class Phone {
  Phone(this.table, String name, {this.canHost = true}) {
    final r = Random(name.hashCode);
    candidate = canHost
        ? Candidate(
            key: List.generate(32, (_) => r.nextInt(256)),
            secret: List.generate(32, (_) => r.nextInt(256)),
          )
        : null;
    link = PlayerLink(
      name: name,
      roomCode: table.code,
      dial: table.lan.dialRoom,
      candidate: candidate,
      config: fast,
      random: Random(name.hashCode + 1),
    );
    succession = Succession(
      link: link,
      sealer: table.sealer,
      openEntrance: () async => Entrance(table.lan, candidate!),
      dialSuccessor: table.lan.dialCandidate,
      becomeHost: _becomeHost,
      after: const Duration(milliseconds: 300),
      retry: const Duration(milliseconds: 50),
    );
  }

  final Table table;
  final bool canHost;
  late final Candidate? candidate;
  late final PlayerLink link;
  late final Succession succession;
  GameHost? hosting;

  Future<void> _becomeHost(String room) async {
    final host = table.takeOver(
      room,
      newOwner: link.you!,
      oldClockAhead: link.clock.offset,
    );
    hosting = host;
    link.redirect(() async => host.connectOwner());
  }

  void close() {
    succession.close();
    link.close();
  }
}

class Table {
  Table();

  final code = '4711';
  final lan = Lan();
  final sealer = FakeSealer(Random(5));
  late GameHost host;
  late PlayerLink owner;
  final phones = <Phone>[];
  final hosts = <GameHost>[];

  CustodyConfig get custody =>
      CustodyConfig(sealer: sealer, room: (snapshot) => snapshot);

  void open(int players) {
    host = GameHost(
      settings: const GameSettings(),
      roomCode: code,
      random: Random(1),
    )..custody = custody;
    hosts.add(host);
    final transport = MemoryTransport();
    host.serve(transport);
    lan.room = transport;
    owner = PlayerLink(
      name: 'Owner',
      roomCode: code,
      dial: () async => host.connectOwner(),
      config: fast,
      random: Random(99),
    );
    for (var i = 0; i < players; i++) {
      phones.add(Phone(this, 'P$i'));
    }
  }

  GameHost takeOver(
    String room, {
    required PlayerId newOwner,
    int? oldClockAhead,
  }) {
    final next = GameHost.restore(
      room,
      random: Random(hosts.length + 10),
      takeOver: true,
      newOwner: newOwner,
      oldClockAhead: oldClockAhead,
    )..custody = custody;
    hosts.add(next);
    final transport = MemoryTransport();
    next.serve(transport);
    lan.room = transport;
    host = next;
    return next;
  }

  /// The host's phone dies: no goodbye, nothing more from it.
  Future<void> crash() async {
    lan.room = null;
    owner.close();
    await host.close(quietly: true);
  }

  Iterable<PlayerLink> get links => [
    if (!ownerGone) owner,
    for (final p in phones) p.link,
  ];
  bool ownerGone = false;

  Future<void> close() async {
    for (final p in phones) {
      p.close();
    }
    owner.close();
    for (final h in hosts) {
      await h.close();
    }
  }
}

Future<void> until(bool Function() condition, {int ms = 4000}) async {
  final end = DateTime.now().add(Duration(milliseconds: ms));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('timed out');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

/// Plays every link a step further, once per phase and round.
class Bots {
  Bots(this.random);

  final Random random;
  final _done = <PlayerLink, Set<String>>{};

  void act(Iterable<PlayerLink> links) {
    for (final link in links) {
      final v = link.view;
      if (v == null || link.status != LinkStatus.connected) continue;
      final done = _done.putIfAbsent(link, () => {});
      void send(String key, ClientMessage intent) {
        if (done.add('$key${v.round}${v.nightStep.name}')) link.send(intent);
      }

      final others = v.seats.where((s) => s.isAlive && s.id != v.you).toList();
      if (others.isEmpty) continue;
      PlayerId pick() => others[random.nextInt(others.length)].id;
      switch (v.phase) {
        case Phase.roleReveal:
          send('confirm', const ConfirmRoleIntent());
        case Phase.night when v.yourSeat.isAlive:
          switch (v.yourNightTask) {
            case NightAbility.hunt:
              final prey = others.where((s) => s.role != Role.werewolf);
              if (prey.isNotEmpty) send('night', NightIntent(prey.first.id));
            case NightAbility.brew:
              send('night', NightIntent.of(const []));
            case NightAbility.link:
              send('night', NightIntent.of([v.you, pick()]));
            case NightAbility.inspect || NightAbility.decoy:
              send('night', NightIntent(pick()));
            case null:
              break;
          }
        case Phase.hunterShot when v.shooter == v.you:
          send('shot', const ShootIntent(null));
        case Phase.day when link.isOwner:
          send('end', const EndDiscussionIntent());
        case Phase.vote when v.yourSeat.isAlive && v.runoff.isNotEmpty:
          send('runoff', VoteIntent(v.runoff.firstWhere((p) => p != v.you)));
        case Phase.vote when v.yourSeat.isAlive:
          send('vote', VoteIntent(pick()));
        case Phase.lobby ||
            Phase.night ||
            Phase.day ||
            Phase.vote ||
            Phase.hunterShot ||
            Phase.ended:
          break;
      }
    }
  }
}

Future<void> playUntil(
  Table table,
  Bots bots,
  bool Function() done, {
  int ms = 8000,
}) async {
  final end = DateTime.now().add(Duration(milliseconds: ms));
  while (!done()) {
    if (DateTime.now().isAfter(end)) fail('game got stuck');
    bots.act(table.links);
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  late Table table;

  setUp(() => table = Table());
  tearDown(() => table.close());

  Future<void> startGame(int players) async {
    table.open(players);
    await until(() => table.owner.view?.seats.length == players + 1);
    table.owner.send(const StartGameIntent());
    await until(
      () => table.links.every((l) => l.view?.phase == Phase.roleReveal),
    );
  }

  Phone holder(bool Function(PlayerLink) has) =>
      table.phones.firstWhere((p) => has(p.link));

  test('the host chooses a successor and a witness, and only them', () async {
    await startGame(4);
    await until(
      () =>
          table.phones.where((p) => p.link.custody != null).length == 1 &&
          table.phones.where((p) => p.link.witness != null).length == 1,
    );
    final successor = holder((l) => l.custody != null);
    final witness = holder((l) => l.witness != null);
    expect(successor, isNot(same(witness)));
    // In seat order: the first two players who can host.
    expect(successor.link.view!.yourSeat.name, 'P0');
    expect(witness.link.view!.yourSeat.name, 'P1');
    expect(witness.link.witness!.successor.key, successor.candidate!.key);
    expect(table.owner.custody, isNull);
    expect(table.owner.witness, isNull);
  });

  test('the host crashes at night: the successor takes over and the same '
      'game goes on to its end', () async {
    await startGame(5);
    final bots = Bots(Random(3));
    await playUntil(
      table,
      bots,
      () => table.phones.first.link.view?.phase == Phase.night,
    );
    await until(() => table.phones.first.link.custody != null);
    final before = table.host.state;
    final ownerToken = table.owner.token;
    await table.crash();
    table.ownerGone = true;

    final successor = table.phones.first;
    await until(() => successor.hosting != null, ms: 5000);
    await until(
      () => table.phones.every(
        (p) => p.link.status == LinkStatus.connected && p.link.epoch == 1,
      ),
    );
    final now = successor.hosting!.state;
    expect(now.round, before.round);
    expect(
      [for (final p in now.players) p.role],
      [
        for (final p in before.players) p.role,
      ],
    );
    // The new host's player runs the table now.
    await until(() => successor.link.isOwner);
    expect(table.phones.skip(1).every((p) => !p.link.isOwner), isTrue);

    // The old host's phone comes back and sits down as a plain player.
    table
      ..owner = PlayerLink(
        name: 'Owner',
        roomCode: table.code,
        token: ownerToken,
        dial: table.lan.dialRoom,
        config: fast,
        random: Random(98),
      )
      ..ownerGone = false;
    await until(() => table.owner.status == LinkStatus.connected);
    expect(table.owner.isOwner, isFalse);
    expect(table.owner.view!.yourRole, before.players.first.role);

    await playUntil(
      table,
      bots,
      () => table.phones.every((p) => p.link.view?.phase == Phase.ended),
    );
    for (final p in table.phones) {
      expect(p.link.view!.seats, hasLength(6));
    }
  });

  test('the witness keeps the key while it still reaches the host', () async {
    await startGame(4);
    await until(() => table.phones[1].link.witness != null);
    final successor = table.phones.first;
    // Only the successor loses the host (its Wi-Fi drops); the witness and
    // everyone else still play with it.
    final room = table.lan.room!;
    table.lan.room = null;
    successor.link.redirect(table.lan.dialRoom);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    expect(successor.hosting, isNull);
    expect(successor.succession.tookOver, isFalse);
    // Back on the Wi-Fi: it simply rejoins the same host.
    table.lan.room = room;
    await until(() => successor.link.status == LinkStatus.connected);
    expect(successor.link.epoch, 0);
    expect(table.lan.entrances, isEmpty);
  });

  test('a wrong key at the entrance opens nothing', () async {
    await startGame(4);
    await until(() => table.phones.first.link.custody != null);
    final successor = table.phones.first;
    // The witness's phone dies along with the host.
    table.phones[1].close();
    await table.crash();
    await until(() => table.lan.entrances.isNotEmpty, ms: 3000);
    final door = await table.lan.dialCandidate(successor.candidate!);
    door.send(Release(epoch: 0, key: List.filled(32, 7)).encode());
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(successor.hosting, isNull);
  });

  test('a host that leaves on purpose hands over at once', () async {
    await startGame(4);
    await until(
      () =>
          table.phones.first.link.custody != null &&
          table.phones[1].link.witness != null,
    );
    final watch = Stopwatch()..start();
    expect(await table.host.handOver(), isTrue);
    await table.crash();
    table.ownerGone = true;
    await until(() => table.phones.first.hosting != null, ms: 2000);
    // Well before anyone would have waited for a missing host.
    expect(watch.elapsedMilliseconds, lessThan(300));
    await until(
      () => table.phones.every((p) => p.link.status == LinkStatus.connected),
    );
  });

  test(
    'a host that comes back after the takeover cannot win anyone back',
    () async {
      await startGame(4);
      await until(() => table.phones.first.link.custody != null);
      final old = table.host.snapshot();
      await table.crash();
      table.ownerGone = true;
      await until(() => table.phones.first.hosting != null, ms: 5000);
      await until(
        () => table.phones.every((p) => p.link.status == LinkStatus.connected),
      );

      // The old host restores its last save and someone dials it.
      final stale = GameHost.restore(old, random: Random(4));
      table.hosts.add(stale);
      final staleRoom = MemoryTransport();
      stale.serve(staleRoom);
      int? hinted;
      stale.onNewerEpoch = (epoch) => hinted = epoch;
      final straggler = table.phones.last.link;
      final current = table.lan.room!;
      table.lan.room = staleRoom;
      straggler.redirect(table.lan.dialRoom);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(straggler.status, isNot(LinkStatus.connected));
      expect(hinted, 1, reason: 'the stale host hears of the newer epoch');
      table.lan.room = current;
      await until(() => straggler.status == LinkStatus.connected);
      expect(straggler.epoch, 1);
    },
  );

  test('a claimed newer epoch changes nothing on the host by itself', () async {
    await startGame(3);
    int? hinted;
    table.host.onNewerEpoch = (epoch) => hinted = epoch;
    final liar = await table.lan.dialRoom();
    liar.send(const Hello(name: 'Mallory', room: '4711', epoch: 9).encode());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(hinted, 9);
    expect(table.host.epoch, 0);
    expect(table.owner.status, LinkStatus.connected);
    await liar.close();
  });

  test('whoever loses a part is told to forget it', () async {
    await startGame(4);
    await until(() => table.phones[1].link.witness != null);
    final oldKey = table.phones[1].link.witness!.key;
    // The successor leaves the table for good: everyone moves up.
    table.phones.first.close();
    await until(
      () =>
          table.phones[1].link.custody != null &&
          table.phones[1].link.witness == null &&
          table.phones[2].link.witness != null,
    );
    expect(table.phones[2].link.witness!.key, isNot(oldKey));
  });

  test('an intent the old host confirmed counts after a takeover, even if '
      "the successor's copy was older", () async {
    await startGame(4);
    final successor = table.phones.first;
    await until(() => successor.link.custody != null);
    await until(() => table.phones[1].link.witness != null);
    // The successor's copy stops here.
    table.sealer.hold = Completer<void>();
    final late = table.phones[2];
    late.link.send(const ConfirmRoleIntent());
    await until(() => late.link.unconfirmed == 0 && late.link.confirmed > 0);
    await table.crash();
    table.ownerGone = true;
    await until(() => successor.hosting != null, ms: 5000);
    await until(
      () => table.phones.every(
        (p) => p.link.status == LinkStatus.connected && p.link.epoch == 1,
      ),
    );
    await until(
      () => successor.hosting!.state.confirmed.contains(late.link.you),
    );
  });

  test("after a takeover every phone shows the new host's game, even if it "
      'saw newer states from the old one', () async {
    await startGame(4);
    final successor = table.phones.first;
    await until(() => successor.link.custody != null);
    await until(() => table.phones[1].link.witness != null);
    table.sealer.hold = Completer<void>();
    // The table moves on to the night; the successor's copy stays behind
    // in the role reveal, and the owner's own confirmation dies with it.
    for (final link in table.links) {
      link.send(const ConfirmRoleIntent());
    }
    await until(
      () => table.phones.every((p) => p.link.view?.phase == Phase.night),
    );
    await table.crash();
    table.ownerGone = true;
    await until(() => successor.hosting != null, ms: 5000);
    final host = successor.hosting!;
    await until(
      () => table.phones.every(
        (p) =>
            p.link.status == LinkStatus.connected &&
            p.link.epoch == 1 &&
            p.link.view?.phase == host.state.phase &&
            p.link.view?.round == host.state.round,
      ),
    );
  });

  test(
    'a takeover keeps the agreed end of the phase and when it began',
    () async {
      await startGame(4);
      final successor = table.phones.first;
      final player = table.phones[2];
      await until(() => successor.link.custody != null);
      await until(() => table.phones[1].link.witness != null);
      await until(
        () =>
            player.link.phaseEndsAtMs != null &&
            player.link.phaseStartedAtMs != null,
      );
      final endsAt = player.link.phaseEndsAtMs!;
      final startedAt = player.link.phaseStartedAtMs!;
      // The successor's copy is made now; the host dies a while later.
      table.sealer.hold = Completer<void>();
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      await table.crash();
      table.ownerGone = true;
      await until(() => successor.hosting != null, ms: 5000);
      await until(
        () =>
            player.link.status == LinkStatus.connected &&
            player.link.epoch == 1 &&
            player.link.version >= 0 &&
            player.link.phaseStartedAtMs != null,
      );
      // Not the time left in the copy from now (1.5 s and more later).
      expect((player.link.phaseEndsAtMs! - endsAt).abs(), lessThan(400));
      expect((player.link.phaseStartedAtMs! - startedAt).abs(), lessThan(400));
    },
  );

  test('a paused phase stays paused after a takeover', () async {
    await startGame(4);
    final successor = table.phones.first;
    await until(() => successor.link.custody != null);
    await until(() => table.phones[1].link.witness != null);
    table.owner.send(const LeaderIntent(LeaderAction.pause));
    await until(() => table.phones.every((p) => p.link.paused));
    // The pause reaches the successor's copy.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await table.crash();
    table.ownerGone = true;
    await until(() => successor.hosting != null, ms: 5000);
    await until(
      () => table.phones.every(
        (p) => p.link.status == LinkStatus.connected && p.link.epoch == 1,
      ),
    );
    await until(() => table.phones.every((p) => p.link.version >= 0));
    expect(table.phones.every((p) => p.link.paused), isTrue);
  });
}
