import 'dart:async';
import 'dart:math';

import 'package:game_core/game_core.dart';
import 'package:game_host/game_host.dart';
import 'package:game_host/lan.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

const room = '4711';

/// A player's app as seen through the protocol.
class Player {
  Player(this.connection) {
    connection.messages.listen((raw) {
      final message = HostMessage.parse(raw);
      received.add(message);
      switch (message) {
        case Welcome(:final token, :final you):
          this.token = token;
          id = you;
        case StateMessage():
          last = message;
        case Bye():
          bye = message.reason;
        case Refused():
          refused.add(message.reason);
      }
    }, onDone: () => closed = true);
  }

  final Connection connection;
  final received = <HostMessage>[];
  final refused = <Violation>[];
  String? token;
  PlayerId? id;
  StateMessage? last;
  ByeReason? bye;
  bool closed = false;

  PlayerView get view => last!.view;

  void send(ClientMessage message) => connection.send(message.encode());
}

/// Test timers that fire only when told to.
class FakeTimers {
  final pending = <(Duration, void Function())>[];
  int now = 0;

  void Function() start(Duration after, void Function() callback) {
    final entry = (after, callback);
    pending.add(entry);
    return () => pending.remove(entry);
  }

  /// Fires every pending timer that is at least [after] long.
  void fire(Duration after) {
    for (final entry in [...pending]) {
      if (entry.$1 == after && pending.remove(entry)) entry.$2();
    }
  }
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late GameHost host;
  late MemoryTransport transport;
  late FakeTimers timers;

  setUp(() {
    timers = FakeTimers();
    host = GameHost(
      roomCode: room,
      random: Random(9),
      startTimer: timers.start,
      clock: () => timers.now,
    );
    transport = MemoryTransport();
    host.serve(transport);
  });

  tearDown(() => host.close());

  Future<Player> join(String name, {bool owner = false}) async {
    final player = Player(owner ? host.connectOwner() : transport.connect())
      ..send(Hello(name: name, room: room));
    await settle();
    return player;
  }

  Future<List<Player>> table(int count) async => [
    await join('Owner', owner: true),
    for (var i = 1; i < count; i++) await join('P$i'),
  ];

  Future<void> start(List<Player> players) async {
    players.first.send(const StartGameIntent());
    await settle();
    for (final p in players) {
      p.send(const ConfirmRoleIntent());
    }
    await settle();
  }

  test('players join the lobby and see each other', () async {
    final players = await table(3);
    for (final p in players) {
      expect(p.token, hasLength(tokenLength));
      expect(p.view.seats.map((s) => s.name), ['Owner', 'P1', 'P2']);
    }
    expect(players.first.last!.isOwner, isTrue);
    expect(players[1].last!.isOwner, isFalse);
  });

  test('only the owner may start; night falls after confirming', () async {
    final players = await table(5);
    players[1].send(const StartGameIntent());
    await settle();
    expect(players[1].refused, [Violation.notYourAction]);
    await start(players);
    for (final p in players) {
      expect(p.view.phase, Phase.night);
      expect(p.view.yourRole, isNotNull);
    }
    expect(timers.pending.single.$1, const HostConfig().nightTime);
  });

  test('a whole game over the protocol, and nobody learns too much', () async {
    final players = await table(5);
    await start(players);
    final wolf = players.firstWhere((p) => p.view.yourRole == Role.werewolf);
    final others = players.where((p) => p != wolf).toList();

    // Night: the wolf takes the first other player; everyone else picks the
    // wolf (the seer inspects, villagers decoy) with the same message.
    final victim = others.first;
    wolf.send(NightIntent(victim.id!));
    for (final p in others) {
      p.send(NightIntent(wolf.id!));
    }
    await settle();
    expect(wolf.view.phase, Phase.day);
    expect(victim.view.yourSeat.isAlive, isFalse);

    // Day: the owner ends the discussion; all living players vote the wolf.
    players.first.send(const EndDiscussionIntent());
    await settle();
    final voter = others.last;
    for (final p in players.where((p) => p.view.yourSeat.isAlive)) {
      p.send(VoteIntent(p == wolf ? voter.id : wolf.id));
    }
    await settle();
    expect(players.first.view.phase, Phase.ended);
    expect(players.first.view.winner, Faction.village);

    // No player ever received another living player's hidden role.
    for (final p in players) {
      for (final message in p.received.whereType<StateMessage>()) {
        final view = message.view;
        if (view.phase == Phase.ended) continue;
        for (final seat in view.seats) {
          if (seat.id == p.id || !seat.isAlive) continue;
          final bothWolves =
              view.yourRole == Role.werewolf && seat.role == Role.werewolf;
          if (!bothWolves) expect(seat.role, isNull);
        }
      }
    }
  });

  test('a player comes back with the token and keeps the role', () async {
    final players = await table(4);
    await start(players);
    final leaver = players[2];
    final role = leaver.view.yourRole;
    await leaver.connection.close();
    await settle();

    final back = Player(transport.connect())
      ..send(Hello(name: 'whatever', room: room, token: leaver.token));
    await settle();
    expect(back.id, leaver.id);
    expect(back.view.yourRole, role);
    expect(back.view.phase, Phase.night);
  });

  test('a second connection with the same token replaces the first', () async {
    final players = await table(3);
    final twin = Player(transport.connect())
      ..send(Hello(name: 'x', room: room, token: players[1].token));
    await settle();
    expect(players[1].bye, ByeReason.replaced);
    expect(twin.id, players[1].id);
  });

  test('wrong room, unknown token and late joiners are turned away', () async {
    final players = await table(3);
    final wrong = Player(transport.connect())
      ..send(const Hello(name: 'X', room: '0000'));
    final unknown = Player(transport.connect())
      ..send(
        const Hello(
          name: 'X',
          room: room,
          token: '00000000000000000000000000000000',
        ),
      );
    await settle();
    expect(wrong.bye, ByeReason.wrongRoom);
    expect(unknown.bye, ByeReason.unknownSession);

    await start(players);
    final late = await join('Late');
    expect(late.bye, ByeReason.gameRunning);
  });

  test('a taken name can be changed without reconnecting', () async {
    await table(2);
    final twin = Player(transport.connect())
      ..send(const Hello(name: 'p1', room: room));
    await settle();
    expect(twin.refused, [Violation.invalidName]);
    expect(twin.bye, isNull);
    twin.send(const Hello(name: 'Other', room: room));
    await settle();
    expect(twin.id, isNotNull);
    expect(twin.view.seats.map((s) => s.name), ['Owner', 'P1', 'Other']);
  });

  test('the owner kicks a player from the lobby', () async {
    final players = await table(3);
    players.first.send(KickIntent(players[2].id!));
    await settle();
    expect(players[2].bye, ByeReason.kicked);
    expect(players.first.view.seats, hasLength(2));
    // The kicked token is dead.
    final back = Player(transport.connect())
      ..send(Hello(name: 'x', room: room, token: players[2].token));
    await settle();
    expect(back.bye, ByeReason.unknownSession);
  });

  test('silent, noisy and malformed connections are dropped', () async {
    final silent = Player(transport.connect());
    await settle();
    timers.fire(const HostConfig().helloTimeout);
    await settle();
    expect(silent.closed, isTrue);

    final garbage = Player(transport.connect());
    for (var i = 0; i < 4; i++) {
      garbage.connection.send('{nope');
    }
    await settle();
    expect(garbage.bye, ByeReason.misbehaved);

    final noisy = await join('Noisy');
    for (var i = 0; i < 25; i++) {
      noisy.send(const ConfirmRoleIntent());
    }
    await settle();
    expect(noisy.bye, ByeReason.misbehaved);

    final rude = Player(transport.connect())..send(const StartGameIntent());
    await settle();
    expect(rude.bye, ByeReason.misbehaved);
  });

  test('the night timer resolves an unfinished night', () async {
    final players = await table(4);
    await start(players);
    timers
      ..now = 5000
      ..fire(const HostConfig().nightTime);
    await settle();
    expect(players.first.view.phase, Phase.day);
    expect(players.first.last!.phaseEndsInMs, isNotNull);
  });

  test('rematch keeps the players and returns to the lobby', () async {
    final players = await table(3);
    await start(players);
    // End quickly: everyone votes out the wolf after a quiet night.
    timers.fire(const HostConfig().nightTime);
    await settle();
    players.first.send(const EndDiscussionIntent());
    await settle();
    final wolf = players.firstWhere((p) => p.view.yourRole == Role.werewolf);
    for (final p in players) {
      p.send(
        VoteIntent(
          p == wolf ? players.firstWhere((o) => o != wolf).id : wolf.id,
        ),
      );
    }
    await settle();
    expect(players.first.view.phase, Phase.ended);
    players.first.send(const RematchIntent());
    await settle();
    expect(players[1].view.phase, Phase.lobby);
    expect(players[1].view.seats, hasLength(3));
    expect(players[1].view.yourRole, isNull);
  });

  test('after a host crash the room is restored from its snapshot', () async {
    String? saved;
    host.onSnapshot = (snapshot) => saved = snapshot;
    final players = await table(4);
    await start(players);
    final wolf = players.firstWhere((p) => p.view.yourRole == Role.werewolf);
    final victim = players.firstWhere((p) => p != wolf);
    wolf.send(NightIntent(victim.id!));
    await settle();
    final roles = {for (final p in players) p.id: p.view.yourRole};
    expect(saved, isNotNull);

    // The host app dies; a new one starts from the saved snapshot.
    await host.close();
    final restored = GameHost.restore(
      saved!,
      random: Random(1),
      startTimer: timers.start,
      clock: () => timers.now,
    );
    final again = MemoryTransport();
    restored.serve(again);
    expect(restored.roomCode, room);
    expect(restored.ownerToken, players.first.token);

    final back = <Player>[];
    for (final p in players) {
      back.add(
        Player(
          p == players.first ? restored.connectOwner() : again.connect(),
        )..send(Hello(name: 'x', room: room, token: p.token)),
      );
    }
    await settle();
    for (var i = 0; i < players.length; i++) {
      expect(back[i].id, players[i].id);
      expect(back[i].view.yourRole, roles[players[i].id]);
      expect(back[i].view.phase, Phase.night);
    }
    expect(back.first.last!.isOwner, isTrue);
    // The wolf's pick survived; the night goes on from there.
    final backWolf = back[players.indexOf(wolf)];
    expect(backWolf.view.yourNightChoice, victim.id);
    await restored.close();
  });

  test('a broken snapshot is refused', () {
    expect(
      () => GameHost.restore('{"v":1}', random: Random(1)),
      throwsA(isA<ProtocolError>()),
    );
    expect(
      () => GameHost.restore('nonsense', random: Random(1)),
      throwsA(isA<ProtocolError>()),
    );
  });

  test('a real WebSocket on localhost carries a lobby', () async {
    final lan = await LanTransport.bind(port: 0);
    host.serve(lan);
    final player = Player(await dialHost('127.0.0.1', lan.port))
      ..send(const Hello(name: 'Net', room: room));
    final welcomed = Completer<void>();
    Timer.periodic(const Duration(milliseconds: 20), (t) {
      if (player.last != null) {
        t.cancel();
        welcomed.complete();
      }
    });
    await welcomed.future.timeout(const Duration(seconds: 5));
    expect(player.view.seats.single.name, 'Net');
  });
}
