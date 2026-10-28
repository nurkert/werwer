import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:game_core/game_core.dart';
import 'package:game_host/game_host.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

const room = '4711';
const config = HostConfig();
const settings = GameSettings();

/// A player's app as seen through the protocol.
class Player {
  Player(this.connection) {
    connection.messages.listen((raw) {
      final message = HostMessage.parse(raw);
      switch (message) {
        case Welcome(:final token, :final you):
          this.token = token;
          id = you;
          welcome = message;
        case StateMessage():
          last = message;
        case Bye():
          bye = message.reason;
        case Refused():
          refused.add(message.reason);
        case Ack() || Pong():
          break;
        case Waiting():
          waiting = true;
        case Custody() || Witness():
          break;
      }
    }, onDone: () => closed = true);
  }

  final Connection connection;
  final refused = <Violation>[];
  String? token;
  PlayerId? id;
  Welcome? welcome;
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

  /// Fires every pending phase timer of at most [after]: a restored host
  /// runs a phase timer with the time that was left, so it can be shorter.
  /// (Hello timeouts of a few seconds are not phase timers.)
  void fire(Duration after) {
    for (final entry in [...pending]) {
      if (_phase(entry.$1, after) && pending.remove(entry)) entry.$2();
    }
  }

  bool has(Duration after) => pending.any((e) => _phase(e.$1, after));

  /// A timer of [after] up to [extra] longer (a dead role's called step
  /// gets a few random seconds).
  bool hasAround(Duration after, Duration extra) => pending.any(
    (e) => e.$1 > const HostConfig().helloTimeout && e.$1 <= after + extra,
  );

  static bool _phase(Duration timer, Duration phase) =>
      timer <= phase && timer > const HostConfig().helloTimeout;
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

String viewJson(PlayerView view) => jsonEncode(encodeView(view));

String stateJson(GameState state) => jsonEncode(encodeState(state));

/// The running phase timer's full length, or `null` if none runs (the
/// reveal timer is left alone here).
Duration? phaseTime(GameState state) => timeLimit(state);

/// Phase changes the rules allow (besides staying put).
const Set<(Phase, Phase)> legalSteps = {
  (Phase.lobby, Phase.roleReveal),
  (Phase.roleReveal, Phase.night),
  (Phase.night, Phase.day),
  (Phase.night, Phase.ended),
  (Phase.day, Phase.vote),
  (Phase.vote, Phase.night),
  (Phase.vote, Phase.ended),
  (Phase.night, Phase.hunterShot),
  (Phase.vote, Phase.hunterShot),
  (Phase.hunterShot, Phase.day),
  (Phase.hunterShot, Phase.night),
  (Phase.hunterShot, Phase.ended),
  (Phase.ended, Phase.lobby), // rematch
};

/// The lovers, tonight's victim and the potions only reach whom they
/// concern (until the game is over).
void expectOwnSecretsOnly(PlayerView view, String reason) {
  if (view.phase == Phase.ended) return;
  if (view.couple.isNotEmpty) {
    expect(
      view.yourRole == Role.cupid ||
          view.couple.contains(view.you) ||
          view.yourGhostSight != GhostSight.off,
      isTrue,
      reason: '$reason sees the lovers',
    );
  }
  if (view.victim != null || view.potions.isNotEmpty) {
    expect(view.yourRole, Role.witch, reason: '$reason sees the victim');
  }
  if (view.packChoices.isNotEmpty || view.packMark != null) {
    expect(view.yourRole, Role.werewolf, reason: '$reason sees the pack');
    expect(view.yourSeat.isAlive, isTrue, reason: '$reason sees the pack');
  }
  if (view.yourDoorSign != null) {
    expect(view.phase, Phase.night, reason: '$reason keeps a door sign');
    expect(view.yourSeat.isAlive, isTrue, reason: '$reason keeps a sign');
  }
}

/// One room under test: the host can crash and be restored, players can
/// drop and come back with their token.
class Room {
  Room(this.timers) {
    _open(
      GameHost(
        settings: const GameSettings(),
        roomCode: room,
        random: Random(1),
        startTimer: timers.start,
        clock: () => timers.now,
      ),
    );
  }

  final FakeTimers timers;
  late GameHost host;
  late MemoryTransport transport;
  String? saved;

  /// Seat index → the player's current app (null while offline).
  final online = <int, Player>{};
  final tokens = <int, String>{};
  final ids = <int, PlayerId>{};

  void _open(GameHost next) {
    host = next..onSnapshot = (s) => saved = s;
    transport = MemoryTransport();
    host.serve(transport);
  }

  Connection _connect(int seat) =>
      seat == 0 ? host.connectOwner() : transport.connect();

  Future<void> seat(int count) async {
    for (var i = 0; i < count; i++) {
      final p = Player(_connect(i))
        ..send(Hello(name: i == 0 ? 'Owner' : 'P$i', room: room));
      await settle();
      online[i] = p;
      tokens[i] = p.token!;
      ids[i] = p.id!;
    }
  }

  Player? player(PlayerId id) =>
      online[ids.entries.firstWhere((e) => e.value == id).key];

  Future<void> drop(int seat) async {
    final p = online.remove(seat);
    if (p != null) await p.connection.close();
  }

  /// Sends the rejoin without waiting for it.
  Player rejoinNow(int seat) {
    final p = Player(_connect(seat))
      ..send(Hello(name: 'x', room: room, token: tokens[seat]));
    online[seat] = p;
    return p;
  }

  /// The host app dies without a goodbye and starts again from its last
  /// snapshot; every app reconnects with its token.
  Future<void> crashAndRestore({bool rejoin = true}) async {
    timers.pending.clear(); // the old process and its timers are gone
    for (final seat in [...online.keys]) {
      await drop(seat);
    }
    await settle();
    _open(
      GameHost.restore(
        saved!,
        random: Random(2),
        startTimer: timers.start,
        clock: () => timers.now,
      ),
    );
    if (!rejoin) return;
    tokens.keys.forEach(rejoinNow);
    await settle();
  }

  /// Every connected, welcomed player sees exactly their filtered view.
  void expectViewsCurrent(String reason) {
    for (final MapEntry(key: seat, value: p) in online.entries) {
      if (p.bye != null || p.closed || p.last == null) continue;
      expect(
        viewJson(p.view),
        viewJson(viewFor(host.state, ids[seat]!)),
        reason: '$reason: seat $seat has a stale view',
      );
    }
  }
}

void main() {
  group('simulation', () {
    for (var seed = 0; seed < 30; seed++) {
      test('seed $seed: drops, rejoins, timers and crashes keep the rules', () {
        return _simulate(seed);
      });
    }
  });

  late FakeTimers timers;
  late Room r;

  setUp(() {
    timers = FakeTimers();
    r = Room(timers);
  });

  tearDown(() => r.host.close());

  Future<void> startGame() async {
    r.online[0]!.send(const StartGameIntent());
    await settle();
    for (final p in r.online.values) {
      p.send(const ConfirmRoleIntent());
    }
    await settle();
  }

  int seatOf(Role role) => r.ids.keys.firstWhere(
    (s) => r.host.state.player(r.ids[s]!)!.role == role,
  );

  /// Plays a night: [skip] seats do nothing; wolves hunt [victim] (or the
  /// first non-wolf), everyone else picks someone else.
  Future<void> act(int seat, {PlayerId? target}) async {
    final me = r.ids[seat]!;
    final state = r.host.state;
    final role = state.player(me)!.role!;
    final pick =
        target ??
        state.alive
            .where(
              (p) =>
                  p.id != me &&
                  (role != Role.werewolf ||
                      p.role?.faction != Faction.werewolves),
            )
            .first
            .id;
    r.online[seat]!.send(NightIntent(pick));
    await settle();
    // Whowolf's hunt ends by its time once everyone has picked.
    final now = r.host.state;
    if (now.phase == Phase.night &&
        now.nightStep == NightStep.hunt &&
        now.settings.nightMode != NightMode.called &&
        everyonePicked(now)) {
      timers.fire(togetherHuntTime);
      await settle();
    }
  }

  test('a player who missed the night timer comes back to the day '
      'with the right deadline', () async {
    await r.seat(5);
    await startGame();
    expect(r.host.state.phase, Phase.night);
    final away = r.ids.keys.firstWhere((s) => s != 0);
    await r.drop(away);
    await settle();

    timers
      ..now = 30000
      ..fire(settings.nightTime);
    await settle();
    expect(r.host.state.phase, anyOf(Phase.day, Phase.ended));
    final dayStartedAt = timers.now;

    timers.now += 1000;
    final back = r.rejoinNow(away);
    await settle();
    expect(back.bye, isNull);
    expect(back.id, r.ids[away]);
    expect(viewJson(back.view), viewJson(viewFor(r.host.state, r.ids[away]!)));
    if (r.host.state.phase == Phase.day) {
      expect(
        back.last!.phaseEndsInMs,
        settings.dayTime.inMilliseconds - (timers.now - dayStartedAt),
      );
    }
    r.expectViewsCurrent('after the night timer');
  });

  for (final rejoinFirst in [true, false]) {
    test('a rejoin in the same turn as the phase change '
        '(${rejoinFirst ? 'rejoin first' : 'change first'})', () async {
      await r.seat(5);
      r.online[0]!.send(const StartGameIntent());
      await settle();
      const away = 3;
      for (final s in r.online.keys.where((s) => s != away && s != 0)) {
        r.online[s]!.send(const ConfirmRoleIntent());
      }
      r.online[away]!.send(const ConfirmRoleIntent());
      await settle();
      await r.drop(away);
      await settle();

      // The owner's confirmation flips the room to night; the rejoin lands
      // in the very same event-loop turn.
      final Player back;
      if (rejoinFirst) {
        back = r.rejoinNow(away);
        r.online[0]!.send(const ConfirmRoleIntent());
      } else {
        r.online[0]!.send(const ConfirmRoleIntent());
        back = r.rejoinNow(away);
      }
      await settle();
      expect(r.host.state.phase, Phase.night);
      expect(back.view.phase, Phase.night);
      expect(back.last!.phaseEndsInMs, settings.nightTime.inMilliseconds);
      r.expectViewsCurrent('after the simultaneous rejoin');
    });
  }

  test(
    'a host restored mid-vote keeps the votes and finishes the vote',
    () async {
      await r.seat(5);
      await startGame();
      for (final s in [...r.ids.keys]) {
        if (r.host.state.player(r.ids[s]!)!.isAlive) await act(s);
      }
      if (r.host.state.phase == Phase.ended) return; // nothing left to vote on
      expect(r.host.state.phase, Phase.day);
      r.online[0]!.send(const EndDiscussionIntent());
      await settle();
      expect(r.host.state.phase, Phase.vote);

      final alive = [
        for (final s in r.ids.keys)
          if (r.host.state.player(r.ids[s]!)!.isAlive) s,
      ];
      final out = alive.last;
      final voters = alive.where((s) => s != out).toList();
      // Two votes before the crash.
      for (final s in voters.take(2)) {
        r.online[s]!.send(VoteIntent(r.ids[out]));
      }
      await settle();

      timers.now += 50000;
      await r.crashAndRestore();
      expect(r.host.state.phase, Phase.vote);
      for (final s in voters.take(2)) {
        expect(r.online[s]!.view.yourVote, r.ids[out], reason: 'seat $s');
      }
      // The vote timer goes on with the time it had left when the host
      // last saved (players dropping by day are saved at once).
      final left = r.online[0]!.last!.phaseEndsInMs!;
      expect(left, greaterThan(0));
      expect(left, lessThanOrEqualTo(settings.voteTime.inMilliseconds));
      r.expectViewsCurrent('after restoring the vote');

      for (final s in voters.skip(2)) {
        r.online[s]!.send(VoteIntent(r.ids[out]));
      }
      r.online[out]!.send(VoteIntent(r.ids[voters.first]));
      await settle();
      expect(r.host.state.player(r.ids[out]!)!.isAlive, isFalse);
      expect(r.host.state.phase, anyOf(Phase.night, Phase.ended));
      r.expectViewsCurrent('after the restored vote');
    },
  );

  test('a host restored mid-night keeps the actions taken so far', () async {
    await r.seat(5);
    await startGame();
    final wolf = seatOf(Role.werewolf);
    final seer = seatOf(Role.seer);
    final victim = r.ids.keys.firstWhere(
      (s) => s != wolf && s != seer && s != 0,
    );
    await act(wolf, target: r.ids[victim]);
    await act(seer, target: r.ids[wolf]);
    final seen = r.online[seer]!.view.seerResults;
    expect(seen, hasLength(1));

    await r.crashAndRestore();
    expect(r.host.state.phase, Phase.night);
    expect(timers.has(settings.nightTime), isTrue);
    expect(r.online[wolf]!.view.yourNightChoice, r.ids[victim]);
    expect(r.online[seer]!.view.seerResults, hasLength(1));
    expect(r.online[seer]!.view.seerResults.single.target, r.ids[wolf]);
    // The seer may not look a second time after the restore.
    r.online[seer]!.send(NightIntent(r.ids[victim]!));
    await settle();
    expect(r.online[seer]!.refused, contains(Violation.alreadyActed));

    for (final s in r.ids.keys.where((s) => s != wolf && s != seer)) {
      await act(s);
    }
    expect(r.host.state.phase, anyOf(Phase.day, Phase.ended));
    expect(r.host.state.player(r.ids[victim]!)!.isAlive, isFalse);
    r.expectViewsCurrent('after the restored night');
  });

  test('a token over an unchecked channel is refused and leaves nothing '
      'behind', () async {
    final unverified = UnverifiedTransport();
    r.host.serve(unverified);
    await r.seat(3);
    final owner = r.online[0]!;

    final stranger = Player(unverified.connect())
      ..send(const Hello(name: 'Eve', room: room));
    await settle();
    expect(stranger.waiting, isTrue);
    expect(owner.last!.pending, hasLength(1));
    final pendingId = owner.last!.pending.single.id;

    // The same connection now shows a valid token (seat 2's). Someone in
    // the middle could have read it, so the host does not take it here.
    stranger.send(Hello(name: 'x', room: room, token: r.tokens[2]));
    await settle();
    expect(stranger.bye, ByeReason.unknownSession);
    expect(stranger.id, isNull);
    expect(owner.last!.pending, isEmpty, reason: 'stale pending entry');

    // Even if the owner's app still shows it, admitting adds nobody.
    owner.send(AdmitIntent(pendingId, admit: true));
    await settle();
    expect(r.host.state.players, hasLength(3), reason: 'second session');
  });

  test('a player let in after the check code gets the room secret', () async {
    final secret = [for (var i = 0; i < 32; i++) i];
    final host = GameHost(
      settings: const GameSettings(),
      roomCode: room,
      random: Random(3),
      roomSecret: secret,
      startTimer: timers.start,
      clock: () => timers.now,
    );
    final unverified = UnverifiedTransport();
    final verified = MemoryTransport();
    host
      ..serve(unverified)
      ..serve(verified);
    final owner = Player(host.connectOwner())
      ..send(const Hello(name: 'Owner', room: room));
    final invited = Player(verified.connect())
      ..send(const Hello(name: 'Bo', room: room));
    final stranger = Player(unverified.connect())
      ..send(const Hello(name: 'Eve', room: room));
    await settle();
    owner.send(AdmitIntent(owner.last!.pending.single.id, admit: true));
    await settle();
    expect(stranger.welcome!.roomSecret, secret);
    expect(owner.welcome!.roomSecret, isNull);
    expect(invited.welcome!.roomSecret, isNull);
    await host.close();
  });
}

Future<void> _simulate(int seed) async {
  final random = Random(seed);
  final timers = FakeTimers();
  final r = Room(timers);
  final count = 5 + random.nextInt(4);
  await r.seat(count);
  var games = 0;
  var phase = r.host.state.phase;

  T pick<T>(List<T> list) => list[random.nextInt(list.length)];

  ClientMessage? intentFor(int seat) {
    final me = r.ids[seat]!;
    final state = r.host.state;
    final others = [
      for (final p in state.alive)
        if (p.id != me) p,
    ];
    switch (state.phase) {
      case Phase.lobby:
        if (seat != 0) return null;
        return switch (random.nextInt(6)) {
          0 || 1 => const StartGameIntent(),
          2 => SettingsIntent(pick(Preset.values).settings),
          _ => null,
        };
      case Phase.roleReveal:
        return const ConfirmRoleIntent();
      case Phase.night:
        if (random.nextInt(4) == 0) return SheepIntent(random.nextInt(31));
        if (others.isEmpty) return null;
        // Anyone may try a door (only a werewolf's first try of the night
        // counts); the test reads the host, so half of the signs are right.
        final wolf = nightTask(state, me) == NightAbility.hunt;
        if (random.nextInt(wolf ? 2 : 12) == 0) {
          final door = pick(others).id;
          return MarkIntent(
            door,
            random.nextBool()
                ? doorSignFor(state, door)
                : [
                    for (var i = 0; i < doorSignLength; i++)
                      random.nextInt(doorSignSymbols),
                  ],
          );
        }
        final victim = state.nightVictim;
        final poisonable = [
          for (final p in others)
            if (p.id != victim) p.id,
        ];
        return switch (nightTask(state, me)) {
          null => null,
          NightAbility.hunt => NightIntent(
            pick([
              for (final p in others)
                if (p.role?.faction != Faction.werewolves) p,
            ]).id,
          ),
          NightAbility.link => NightIntent.of([me, pick(others).id]),
          NightAbility.brew => NightIntent.of([
            if (victim != null && random.nextBool()) victim,
            if (poisonable.isNotEmpty && random.nextInt(3) == 0)
              pick(poisonable),
          ]),
          NightAbility.inspect || NightAbility.decoy => NightIntent(
            pick(others).id,
          ),
        };
      case Phase.hunterShot:
        if (state.shooter != me || others.isEmpty) return null;
        return ShootIntent(random.nextInt(4) == 0 ? null : pick(others).id);
      case Phase.day:
        return seat == 0 && random.nextInt(4) == 0
            ? const EndDiscussionIntent()
            : null;
      case Phase.vote:
        if (others.isEmpty) return null;
        return VoteIntent(random.nextInt(6) == 0 ? null : pick(others).id);
      case Phase.ended:
        return seat == 0 && random.nextInt(3) == 0
            ? const RematchIntent()
            : null;
    }
  }

  for (var step = 0; step < 200; step++) {
    timers.now += 100; // stay under the rate limit
    final roll = random.nextInt(100);
    final offline = [
      for (final s in r.tokens.keys)
        if (!r.online.containsKey(s)) s,
    ];
    final what = switch (roll) {
      < 5 when r.online.isNotEmpty => 'drop',
      < 12 when offline.isNotEmpty => 'rejoin',
      < 18 => 'timer',
      < 20 when r.saved != null => 'crash',
      _ => 'intent',
    };
    switch (what) {
      case 'drop':
        await r.drop(pick(r.online.keys.toList()));
      case 'rejoin':
        r.rejoinNow(pick(offline));
      case 'timer':
        final time = phaseTime(r.host.state);
        if (time != null) timers.fire(time);
      case 'crash':
        await r.crashAndRestore();
      default:
        if (r.online.isNotEmpty) {
          final seat = pick(r.online.keys.toList());
          final intent = intentFor(seat);
          if (intent != null) r.online[seat]!.send(intent);
        }
    }
    await settle();
    final where = 'seed $seed step $step ($what)';

    // Everyone online and welcomed holds exactly their current view.
    for (final p in r.online.values) {
      expect(p.bye, isNull, reason: '$where: unexpected bye');
    }
    r.expectViewsCurrent(where);

    // Phases only move along the rules.
    final now = r.host.state.phase;
    if (now != phase) {
      expect(
        legalSteps.contains((phase, now)),
        isTrue,
        reason: '$where: $phase -> $now',
      );
      if (now == Phase.ended) games++;
      phase = now;
    }

    // A running phase always has its timer.
    final time = phaseTime(r.host.state);
    if (time != null) {
      final state = r.host.state;
      final idle =
          state.phase == Phase.night &&
          state.settings.nightMode == NightMode.called &&
          !calledStepPending(state);
      expect(
        idle
            ? timers.hasAround(time, const Duration(seconds: 6))
            : timers.has(time),
        isTrue,
        reason: '$where: no $now timer',
      );
    }

    // The snapshot restores exactly this state.
    final copy = GameHost.restore(
      r.host.snapshot(),
      random: Random(0),
      startTimer: (_, _) => () {},
    );
    expect(stateJson(copy.state), stateJson(r.host.state), reason: where);

    // Nobody sees a hidden role (wolves see wolves; the end reveals all).
    for (final MapEntry(key: seat, value: p) in r.online.entries) {
      if (p.last == null) continue;
      final view = p.view;
      if (view.phase == Phase.ended) continue;
      // Ghosts see all roles, but only the dead are ghosts.
      if (view.yourGhostSight != GhostSight.off) {
        expect(view.yourSeat.isAlive, isFalse, reason: '$where ghost');
        continue;
      }
      for (final seatView in view.seats) {
        if (seatView.id == r.ids[seat] ||
            !seatView.isAlive ||
            seatView.role == null) {
          continue;
        }
        expect(
          view.yourRole == Role.werewolf && seatView.role == Role.werewolf,
          isTrue,
          reason: '$where: ${r.ids[seat]} sees ${seatView.id}',
        );
      }
      expectOwnSecretsOnly(view, '$where: ${r.ids[seat]}');
    }
  }
  printOnFailure('seed $seed: $games games ended');
  await r.host.close();
}
