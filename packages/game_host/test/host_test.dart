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
        case Ack(:final seq):
          acks.add(seq);
        case Pong():
          break;
        case Waiting():
          waiting = true;
        case Custody() || Witness():
          break;
      }
    }, onDone: () => closed = true);
  }

  final Connection connection;
  final received = <HostMessage>[];
  final refused = <Violation>[];
  final acks = <int>[];
  String? token;
  PlayerId? id;
  StateMessage? last;
  ByeReason? bye;
  bool closed = false;
  bool waiting = false;

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

/// A connection that came in encrypted but without the QR code's secret.
class UnverifiedTransport implements Transport {
  final _inner = MemoryTransport();

  @override
  Stream<Connection> get connections => _inner.connections.map(_Unverified.new);

  Connection connect() => _inner.connect();

  @override
  Future<void> close() => _inner.close();
}

class _Unverified implements Connection, PeerTrust {
  _Unverified(this._raw);
  final Connection _raw;

  @override
  bool get verified => false;

  @override
  List<int> get checkCode => const [1, 2, 3];

  @override
  List<int>? get peerKey => null;

  @override
  Stream<String> get messages => _raw.messages;

  @override
  void send(String message) => _raw.send(message);

  @override
  Future<void> close() => _raw.close();
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late GameHost host;
  late MemoryTransport transport;
  late FakeTimers timers;

  setUp(() {
    timers = FakeTimers();
    host = GameHost(
      settings: const GameSettings(),
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

  test(
    'silent phones show at once in the lobby, later only per phase',
    () async {
      final players = await table(4);
      final quiet = players[2]..send(const SilentIntent(silent: true));
      await settle();
      for (final p in players) {
        expect(p.last!.silent, [quiet.id], reason: p.id?.value);
      }
      await start(players);
      expect(players.first.last!.silent, [quiet.id]);
      // Unmuting in the middle of a phase changes nothing until the next.
      quiet.send(const SilentIntent(silent: false));
      players[1].send(const SilentIntent(silent: true));
      await settle();
      expect(players.first.last!.silent, [quiet.id]);
    },
  );

  test('who plays in a browser shows only in the lobby', () async {
    final owner = await join('Owner', owner: true);
    final web = Player(transport.connect())
      ..send(const Hello(name: 'Web', room: room, web: true));
    await settle();
    final app = await join('App');
    for (final p in [owner, web, app]) {
      expect(p.last!.inBrowser, [web.id], reason: p.id?.value);
    }
    await start([owner, web, app]);
    for (final p in [owner, web, app]) {
      expect(p.last!.inBrowser, isEmpty);
    }
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
    expect(timers.pending.single.$1, const GameSettings().nightTime);
  });

  test('only the owner skips the intro, once, only during the roles', () async {
    final players = await table(5);
    players.first.send(const SkipIntroIntent());
    await settle();
    expect(players.first.refused, [Violation.wrongPhase]);
    players.first.send(const StartGameIntent());
    await settle();
    expect(players.first.last!.introSkippedAt, isNull);
    players[1].send(const SkipIntroIntent());
    await settle();
    expect(players[1].refused, [Violation.notYourAction]);
    timers.now = 4200;
    players.first.send(const SkipIntroIntent());
    await settle();
    for (final p in players) {
      expect(p.last!.introSkippedAt, 4200);
    }
    players.first.send(const SkipIntroIntent());
    await settle();
    expect(players.first.refused, [Violation.wrongPhase, Violation.wrongPhase]);
    for (final p in players) {
      p.send(const ConfirmRoleIntent());
    }
    await settle();
    expect(players.first.view.phase, Phase.night);
    expect(players.first.last!.introSkippedAt, isNull);
  });

  Future<List<Player>> toDay() async {
    final players = await table(5);
    await start(players);
    final wolf = players.firstWhere((p) => p.view.yourRole == Role.werewolf);
    final others = players.where((p) => p != wolf).toList();
    wolf.send(NightIntent(others.last.id!));
    for (final p in others) {
      p.send(NightIntent(wolf.id!));
    }
    await settle();
    expect(players.first.view.phase, Phase.day);
    return players;
  }

  test('when most of the living are ready, the vote comes after a short '
      'warning', () async {
    final players = await toDay();
    final living = players.where((p) => p.view.yourSeat.isAlive).toList();
    expect(living, hasLength(4));
    living[0].send(const ReadyIntent(ready: true));
    living[1].send(const ReadyIntent(ready: true));
    await settle();
    expect(players.first.last!.ready, hasLength(2));
    expect(timers.pending.any((t) => t.$1 == GameHost.voteWarning), isFalse);
    living[2].send(const ReadyIntent(ready: true));
    await settle();
    expect(timers.pending.any((t) => t.$1 == GameHost.voteWarning), isTrue);
    timers.fire(GameHost.voteWarning);
    await settle();
    expect(players.first.view.phase, Phase.vote);
    expect(players.first.last!.ready, isEmpty);
  });

  test('the dead cannot say they are ready', () async {
    final players = await toDay();
    final dead = players.firstWhere((p) => !p.view.yourSeat.isAlive)
      ..send(const ReadyIntent(ready: true));
    await settle();
    expect(dead.refused, [Violation.notYourAction]);
    expect(players.first.last!.ready, isEmpty);
  });

  test('only the game leader controls the clock: pause, resume, more time, '
      'end', () async {
    final players = await toDay();
    final owner = players.first;
    final other = players[1]..send(const LeaderIntent(LeaderAction.pause));
    await settle();
    expect(other.refused, [Violation.notYourAction]);
    expect(other.last!.paused, isFalse);

    owner.send(const LeaderIntent(LeaderAction.pause));
    await settle();
    expect(other.last!.paused, isTrue);
    expect(other.last!.phaseEndsInMs, isNull);
    expect(
      timers.pending.where((t) => t.$1 == const GameSettings().dayTime),
      isEmpty,
    );

    owner.send(const LeaderIntent(LeaderAction.resume));
    await settle();
    expect(other.last!.paused, isFalse);
    final left = other.last!.phaseEndsInMs!;

    owner.send(const LeaderIntent(LeaderAction.extend));
    await settle();
    expect(other.last!.phaseEndsInMs, left + 30000);

    owner.send(const LeaderIntent(LeaderAction.end));
    await settle();
    expect(other.view.phase, Phase.vote);
  });

  test('who is not connected shows by day, never at night', () async {
    final night = await table(5);
    await start(night);
    await night.last.connection.close();
    // Someone acts, so a fresh state goes out at night.
    night.first.send(NightIntent(night[1].id!));
    await settle();
    expect(night.first.last!.offline, isEmpty);
    await host.close();
    timers = FakeTimers();
    host = GameHost(
      settings: const GameSettings(),
      roomCode: room,
      random: Random(9),
      startTimer: timers.start,
      clock: () => timers.now,
    );
    transport = MemoryTransport();
    host.serve(transport);
    final players = await toDay();
    final gone = players.last;
    await gone.connection.close();
    await settle();
    expect(players.first.last!.offline, [gone.id]);
  });

  group('handing a seat to another device', () {
    const code = 'a1b2c3d4e5f60718293a4b5c6d7e8f90';

    test('the new device gets the seat, the old one is let go, the code '
        'works once', () async {
      final players = await toDay();
      final owner = players.first;
      final old = players[2];
      final oldToken = old.token;
      owner.send(HandoverIntent(old.id!, code));
      await settle();
      expect(owner.refused, isEmpty);

      final fresh = Player(transport.connect())
        ..send(const Hello(name: 'X', room: room, handover: code));
      await settle();
      expect(fresh.id, old.id);
      expect(fresh.token, isNot(oldToken));
      expect(fresh.view.yourRole, old.view.yourRole);
      expect(old.bye, ByeReason.replaced);

      // The old token no longer works, nor does the code a second time.
      final back = Player(transport.connect())
        ..send(Hello(name: 'Y', room: room, token: oldToken));
      final again = Player(transport.connect())
        ..send(const Hello(name: 'Z', room: room, handover: code));
      await settle();
      expect(back.bye, ByeReason.unknownSession);
      expect(again.bye, ByeReason.unknownSession);
    });

    test('only the game leader can make a code, and it runs out', () async {
      final players = await toDay();
      players[1].send(HandoverIntent(players[2].id!, code));
      await settle();
      expect(players[1].refused, [Violation.notYourAction]);

      players.first.send(HandoverIntent(players[2].id!, code));
      await settle();
      timers.now += GameHost.handoverTime.inMilliseconds + 1;
      final late = Player(transport.connect())
        ..send(const Hello(name: 'X', room: room, handover: code));
      await settle();
      expect(late.bye, ByeReason.unknownSession);
      expect(players[2].bye, isNull, reason: 'the seat stays where it was');
    });

    test('a code over an unchecked channel is refused', () async {
      final players = await toDay();
      players.first.send(HandoverIntent(players[2].id!, code));
      await settle();
      final unchecked = UnverifiedTransport();
      host.serve(unchecked);
      final stranger = Player(unchecked.connect())
        ..send(const Hello(name: 'X', room: room, handover: code));
      await settle();
      expect(stranger.bye, ByeReason.unknownSession);
    });
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
        // Ghosts see all roles, but only the dead are ghosts.
        if (view.yourGhostSight != GhostSight.off) {
          expect(view.yourSeat.isAlive, isFalse);
          continue;
        }
        for (final seat in view.seats) {
          if (seat.id == p.id || !seat.isAlive) continue;
          final bothWolves =
              view.yourRole == Role.werewolf && seat.role == Role.werewolf;
          if (!bothWolves) expect(seat.role, isNull);
        }
      }
    }
  });

  test('only the owner changes the settings, only in the lobby, and '
      'everyone sees them', () async {
    final players = await table(5);
    players[1].send(SettingsIntent(Preset.classic.settings));
    await settle();
    expect(players[1].refused, [Violation.notYourAction]);
    players.first.send(
      SettingsIntent(
        Preset.classic.settings.copyWith(nightTime: const Duration(seconds: 5)),
      ),
    );
    await settle();
    expect(players.first.refused, [Violation.outOfRange]);
    players.first.send(SettingsIntent(Preset.classic.settings));
    await settle();
    for (final p in players) {
      expect(p.view.settings.preset, Preset.classic);
    }
    await start(players);
    players.first.send(SettingsIntent(Preset.fullStage.settings));
    await settle();
    expect(players.first.refused.last, Violation.wrongPhase);
    expect(host.state.settings.preset, Preset.classic);
  });

  test(
    "the witch's step and the hunter's shot run on their own timers",
    () async {
      final players = await table(6);
      players.first.send(SettingsIntent(Preset.fullStage.settings));
      await settle();
      await start(players);
      Player holder(Role role) =>
          players.firstWhere((p) => p.view.yourRole == role);
      final wolf = holder(Role.werewolf);
      final hunter = holder(Role.hunter);
      final witch = holder(Role.witch);
      expect(holder(Role.cupid).view.yourNightTask, NightAbility.link);
      expect(timers.pending.single.$1, Preset.fullStage.settings.nightTime);

      wolf.send(NightIntent(hunter.id!));
      await settle();
      timers.fire(Preset.fullStage.settings.nightTime);
      await settle();
      expect(timers.pending.single.$1, brewTime);
      for (final p in players) {
        expect(p.view.nightStep, NightStep.brew);
        expect(p.view.victim, p == witch ? hunter.id : null);
      }
      expect(witch.view.yourNightTask, NightAbility.brew);
      expect(witch.last!.phaseEndsInMs, brewTime.inMilliseconds);

      timers.fire(brewTime);
      await settle();
      expect(timers.pending.single.$1, shotTime);
      for (final p in players) {
        expect(p.view.phase, Phase.hunterShot);
        expect(p.view.shooter, hunter.id);
      }
      wolf.send(ShootIntent(hunter.id));
      await settle();
      expect(wolf.refused, [Violation.notYourAction]);
      hunter.send(ShootIntent(wolf.id));
      await settle();
      expect(players.first.view.phase, Phase.ended);
      expect(players.first.view.winner, Faction.village);
    },
  );

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

  test(
    'without the QR secret, the host lets people in after a check',
    () async {
      final owner = await join('Owner', owner: true);
      final open = UnverifiedTransport();
      host.serve(open);
      final eve = Player(open.connect())
        ..send(const Hello(name: 'Eve', room: room));
      final mallory = Player(open.connect())
        ..send(const Hello(name: 'Mallory', room: room));
      await settle();
      expect(eve.waiting, isTrue);
      expect(eve.id, isNull);
      final pending = owner.last!.pending;
      expect(pending.map((p) => p.name), ['Eve', 'Mallory']);
      expect(pending.first.checkCode, [1, 2, 3]);
      expect(owner.view.seats, hasLength(1));

      owner
        ..send(AdmitIntent(pending.first.id, admit: true))
        ..send(AdmitIntent(pending.last.id, admit: false));
      await settle();
      expect(eve.id, isNotNull);
      expect(mallory.bye, ByeReason.refused);
      expect(owner.view.seats.map((s) => s.name), ['Owner', 'Eve']);
      expect(owner.last!.pending, isEmpty);

      // Only the owner may let people in.
      final sneaky = Player(open.connect())
        ..send(const Hello(name: 'Sneaky', room: room));
      await settle();
      eve.send(AdmitIntent(owner.last!.pending.single.id, admit: true));
      await settle();
      expect(eve.refused, [Violation.notYourAction]);
      expect(sneaky.id, isNull);
    },
  );

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
      ..fire(const GameSettings().nightTime);
    await settle();
    expect(players.first.view.phase, Phase.day);
    expect(players.first.last!.phaseEndsInMs, isNotNull);
  });

  test('rematch keeps the players and returns to the lobby', () async {
    final players = await table(3);
    await start(players);
    // End quickly: everyone votes out the wolf after a quiet night.
    timers.fire(const GameSettings().nightTime);
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

  test('random and broken messages never crash the host or leak', () async {
    for (var seed = 0; seed < 20; seed++) {
      final random = Random(seed);
      final players = await table(5);
      final ids = [for (final p in players) p.id!, const PlayerId('p99')];
      PlayerId anyId() => ids[random.nextInt(ids.length)];
      ClientMessage anyIntent() => switch (random.nextInt(16)) {
        14 => MarkIntent(anyId(), [
          for (var i = 0; i < doorSignLength; i++)
            random.nextInt(doorSignSymbols),
        ]),
        11 => ShootIntent(random.nextBool() ? null : anyId()),
        12 => SettingsIntent(
          Preset.values[random.nextInt(Preset.values.length)].settings,
        ),
        13 => NightIntent.of([anyId(), anyId()]),
        0 => const StartGameIntent(),
        1 => const ConfirmRoleIntent(),
        2 => NightIntent(anyId()),
        3 => VoteIntent(random.nextBool() ? null : anyId()),
        4 => const EndDiscussionIntent(),
        5 => KickIntent(anyId()),
        6 => SheepIntent(random.nextInt(60) - 10),
        7 => PersonaIntent(Persona.values[random.nextInt(11)]),
        8 => SwapSeatsIntent(anyId(), anyId()),
        9 => AdmitIntent(random.nextInt(5), admit: random.nextBool()),
        10 => const RematchIntent(),
        _ => Hello(name: 'X${random.nextInt(9)}', room: room),
      };
      for (var step = 0; step < 300; step++) {
        final p = players[random.nextInt(players.length)];
        if (random.nextInt(10) == 0) {
          // Raw garbage straight onto the wire.
          p.connection.send(
            String.fromCharCodes([
              for (var i = 0; i < random.nextInt(40); i++)
                32 + random.nextInt(90),
            ]),
          );
        } else {
          p.send(anyIntent());
        }
        if (step % 25 == 0) {
          timers
            ..fire(const GameSettings().nightTime)
            ..fire(const GameSettings().dayTime)
            ..fire(const GameSettings().voteTime)
            ..fire(const GameSettings().voteTime ~/ 2) // a runoff
            ..fire(brewTime)
            ..fire(shotTime)
            ..now += 2000; // keep the rate limit happy
        }
        await settle();
      }
      // Whatever happened, the rules held and no one saw a hidden role.
      final state = host.state;
      expect(state.players.length, inInclusiveRange(0, maxPlayers));
      for (final p in players.where((p) => p.last != null)) {
        final view = p.view;
        if (view.phase == Phase.ended) continue;
        // Ghosts see all roles, but only the dead are ghosts.
        if (view.yourGhostSight != GhostSight.off) {
          expect(view.yourSeat.isAlive, isFalse, reason: 'seed $seed ghost');
          continue;
        }
        for (final seat in view.seats) {
          if (seat.id == p.id || !seat.isAlive || seat.role == null) continue;
          expect(
            view.yourRole == Role.werewolf && seat.role == Role.werewolf,
            isTrue,
            reason: 'seed $seed: ${p.id} sees ${seat.id}',
          );
        }
      }
      await host.close();
      host = GameHost(
        settings: const GameSettings(),
        roomCode: room,
        random: Random(seed + 100),
        startTimer: timers.start,
        clock: () => timers.now,
      );
      transport = MemoryTransport();
      host.serve(transport);
    }
  });

  test('a door mark acts for the sender only, once per night', () async {
    final players = await table(6);
    players.first.send(
      SettingsIntent(Preset.whowolf.settings.copyWith(werewolves: 2)),
    );
    await settle();
    await start(players);
    final wolves = [
      for (final p in players)
        if (p.view.yourRole == Role.werewolf) p,
    ];
    expect(wolves, hasLength(2));
    final villagers = players.where((p) => !wolves.contains(p)).toList();
    final target = villagers.first;
    final sign = target.view.yourDoorSign!;
    expect(sign, doorSignFor(host.state, target.id!));
    // Nobody else ever gets this sign; only wolves see the pack's mark.
    for (final p in players.where((p) => p != target)) {
      expect(p.view.yourDoorSign, doorSignFor(host.state, p.id!));
    }

    // A villager cannot mark, whatever the message says.
    villagers.last.connection.send(MarkIntent(target.id!, sign).encode(seq: 1));
    await settle();
    expect(villagers.last.refused, [Violation.notYourAction]);
    expect(villagers.last.acks, [1]);
    expect(host.state.packMark, isNull);

    wolves.first.connection.send(MarkIntent(target.id!, sign).encode(seq: 1));
    await settle();
    expect(wolves.first.acks, [1]);
    expect(host.state.packMark, (target: target.id!, correct: true));
    for (final p in players) {
      expect(
        p.view.packMark,
        wolves.contains(p) ? host.state.packMark : isNull,
        reason: '${p.id}',
      );
      expect(p.view.youActed, isFalse);
    }
    // A resend is confirmed again, never applied twice; a second try by the
    // pack is refused.
    wolves.first.connection.send(MarkIntent(target.id!, sign).encode(seq: 1));
    wolves.last.send(MarkIntent(villagers.last.id!, const [0, 0, 0]));
    await settle();
    expect(wolves.first.acks, [1, 1]);
    expect(wolves.first.refused, isEmpty);
    expect(wolves.last.refused, [Violation.markUsed]);
    expect(host.state.packMark!.target, target.id);

    // The attempt survives a restart of the host.
    final restored = GameHost.restore(
      host.snapshot(),
      random: Random(1),
      startTimer: timers.start,
    );
    expect(restored.state.packMark, host.state.packMark);
    await restored.close();
  });

  test('a numbered intent is applied exactly once and confirmed', () async {
    final players = await table(4);
    await start(players);
    final bo = players[1];
    final target = players[2].id!;
    // Sent three times (resends after reconnects, doubled on the way).
    for (var i = 0; i < 3; i++) {
      bo.connection.send(NightIntent(target).encode(seq: 1));
    }
    await settle();
    expect(bo.acks, [1, 1, 1]);
    expect(host.state.nightChoices[bo.id], [target]);
    // A gap (seq 3 before 2) is not applied; the player resends in order.
    bo.connection.send(NightIntent(const PlayerId('p1')).encode(seq: 3));
    await settle();
    expect(bo.acks, [1, 1, 1]);
    expect(host.state.nightChoices[bo.id], [target]);
    // Another session's numbers are its own.
    players[3].connection.send(NightIntent(players[1].id!).encode(seq: 1));
    await settle();
    expect(players[3].acks, [1]);
  });

  test('a restored host goes on with the time the phase had left', () async {
    String? saved;
    host.onSnapshot = (s) => saved = s;
    final players = await table(4);
    await start(players);
    timers.now += 60000;
    players.first.send(const PersonaIntent(Persona.smith)); // any broadcast
    players[1].send(NightIntent(players[2].id!));
    await settle();
    await host.close();
    final timersAfter = FakeTimers();
    final restored = GameHost.restore(
      saved!,
      random: Random(2),
      startTimer: timersAfter.start,
      clock: () => timersAfter.now,
    );
    final left = timersAfter.pending.map((e) => e.$1).toList();
    expect(left, [const Duration(seconds: 30)]);
    await restored.close();
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

  test(
    'strangers cannot fill the waiting list or keep their place forever',
    () async {
      final owner = await join('Owner', owner: true);
      final open = UnverifiedTransport();
      host.serve(open);
      final waiting = [
        for (var i = 0; i < 6; i++)
          Player(open.connect())..send(Hello(name: 'W$i', room: room)),
      ];
      final extra = Player(open.connect())
        ..send(const Hello(name: 'Extra', room: room));
      await settle();
      expect(owner.last!.pending, hasLength(6));
      expect(extra.bye, ByeReason.refused);
      // Renaming does not restart the clock: the wait still ends on time.
      waiting.first.send(const Hello(name: 'Renamed', room: room));
      await settle();
      expect(owner.last!.pending.first.name, 'Renamed');
      timers.fire(const HostConfig().renameTimeout);
      await settle();
      expect(owner.last!.pending, isEmpty);
      expect(waiting.every((p) => p.closed), isTrue);
    },
  );
}
