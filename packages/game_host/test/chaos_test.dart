// Chaos tests (docs/tasks/002-stabiles-netz.md): whole games over a network
// that loses, delays, doubles and reorders messages and drops connections,
// with the host crashing at random points and coming back from its last
// snapshot. Players are bots on the real PlayerLink. Time is virtual, so
// hundreds of games run in seconds; every case has a fixed seed.
//
//   CHAOS_SEEDS=1000 dart test test/chaos_test.dart   # more cases
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:game_core/game_core.dart';
import 'package:game_host/game_host.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

/// Virtual time: events run in time order, nothing waits for real.
class Sim {
  int now = 0;
  int _order = 0;
  final _events = SplayTreeMap<(int, int), void Function()>(
    (a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2),
  );

  void Function() start(Duration after, void Function() callback) {
    final key = (now + after.inMilliseconds, _order++);
    _events[key] = callback;
    return () => _events.remove(key);
  }

  int clock() => now;

  /// Runs events until [until] (virtual ms) or until [done] holds.
  Future<void> run(int until, {bool Function()? done}) async {
    while (now <= until && !(done?.call() ?? false)) {
      if (_events.isEmpty) {
        // Async work (dials, stream deliveries) may still schedule events.
        await Future<void>.delayed(Duration.zero);
        if (_events.isEmpty) return;
        continue;
      }
      final key = _events.firstKey()!;
      final event = _events.remove(key)!;
      now = max(now, key.$1);
      event();
      // Let stream deliveries and async continuations happen.
      await Future<void>.delayed(Duration.zero);
    }
  }
}

/// How rough the network is.
class Weather {
  const Weather({
    this.loss = 0.05,
    this.duplicate = 0.05,
    this.maxDelayMs = 400,
    this.dropEveryMs = 40000,
  });

  static const calm = Weather(
    loss: 0,
    duplicate: 0,
    maxDelayMs: 20,
    dropEveryMs: 0,
  );

  final double loss;
  final double duplicate;
  final int maxDelayMs;

  /// Average time between connection drops per connection (0 = never).
  final int dropEveryMs;
}

/// A network between players and the current host.
class ChaosNet implements Transport {
  ChaosNet(this.sim, this.random);

  final Sim sim;
  final Random random;
  Weather weather = const Weather();
  final _incoming = StreamController<Connection>();
  final _open = <_End>[];

  @override
  Stream<Connection> get connections => _incoming.stream;

  /// A player's new connection; the host gets the other end.
  Connection connect() {
    final player = _End(this);
    final host = _End(this);
    player.peer = host;
    host.peer = player;
    _open.addAll([player, host]);
    _incoming.add(host);
    _scheduleDrop(player);
    return player;
  }

  void _scheduleDrop(_End end) {
    final every = weather.dropEveryMs;
    if (every == 0) return;
    final after = (random.nextDouble() * 2 * every).round();
    sim.start(Duration(milliseconds: after), () {
      if (!end.closed) unawaited(end.close());
    });
  }

  void _deliver(_End to, String message) {
    final w = weather;
    if (random.nextDouble() < w.loss) return;
    final copies = random.nextDouble() < w.duplicate ? 2 : 1;
    for (var i = 0; i < copies; i++) {
      // Independent delays reorder messages.
      final delay = random.nextInt(w.maxDelayMs + 1);
      sim.start(Duration(milliseconds: delay), () => to._receive(message));
    }
  }

  /// The host machine dies: every connection breaks, nothing more is said.
  void cutAll() {
    for (final end in [..._open]) {
      unawaited(end.close());
    }
  }

  @override
  Future<void> close() async => cutAll();
}

class _End implements Connection {
  _End(this.net);

  final ChaosNet net;
  late _End peer;
  final _messages = StreamController<String>();
  bool closed = false;

  @override
  Stream<String> get messages => _messages.stream;

  @override
  void send(String message) {
    if (!closed) net._deliver(peer, message);
  }

  void _receive(String message) {
    if (!closed) _messages.add(message);
  }

  @override
  Future<void> close() async {
    if (closed) return;
    closed = true;
    net._open.remove(this);
    unawaited(_messages.close());
    unawaited(peer.close());
  }
}

/// A player who acts on what it sees, a little randomly.
class Bot {
  Bot(this.name, this.random, this.table, {this.settings, this.peek});

  /// For one cheating bot: reads a door sign off the host, so that right
  /// marks happen too. Honest bots can only guess.
  final List<int> Function(PlayerId player)? peek;

  /// What the owner plays with (the others leave it alone).
  final GameSettings? settings;

  /// How many players were invited to the table.
  final int table;

  final String name;
  final Random random;
  late PlayerLink link;
  int accepted = 0;
  final _done = <String>{};
  final seen = <PlayerView>[];

  void send(String key, ClientMessage intent) {
    if (!_done.add(key)) return;
    if (link.send(intent)) accepted++;
  }

  void act(Sim sim) {
    final v = link.view;
    if (v == null) return;
    seen.add(v);
    final me = v.yourSeat;
    final others = v.seats.where((s) => s.isAlive && s.id != v.you).toList();
    if (others.isEmpty) return;
    PlayerId pick() => others[random.nextInt(others.length)].id;
    switch (v.phase) {
      case Phase.lobby:
        final everyone = v.seats.length >= table;
        final waited = sim.now > 120000 && v.seats.length >= 5;
        final wanted = settings;
        if (link.isOwner && wanted != null) {
          send('settings', SettingsIntent(wanted));
        }
        if (link.isOwner && (everyone || waited)) {
          send('start', const StartGameIntent());
        }
      case Phase.roleReveal:
        send('confirm${v.round}', const ConfirmRoleIntent());
      case Phase.night when me.isAlive:
        if (v.yourFlock case final flock?) {
          send('sheep${v.round}', SheepIntent(random.nextInt(flock + 1)));
        }
        final key = 'night${v.round}${v.nightStep.name}';
        final victim = v.victim;
        switch (v.yourNightTask) {
          case NightAbility.hunt:
            final prey = others.where((s) => s.role != Role.werewolf).toList();
            if (prey.isEmpty) return;
            final door = prey[random.nextInt(prey.length)].id;
            if (v.settings.doorSigns &&
                v.packMark == null &&
                random.nextInt(3) == 0) {
              send(
                'mark${v.round}',
                MarkIntent(
                  door,
                  peek?.call(door) ??
                      [
                        for (var i = 0; i < doorSignLength; i++)
                          random.nextInt(doorSignSymbols),
                      ],
                ),
              );
            }
            send(key, NightIntent(prey[random.nextInt(prey.length)].id));
          case NightAbility.link:
            send(key, NightIntent.of([v.you, pick()]));
          case NightAbility.brew:
            final poison = others.where((s) => s.id != victim).toList();
            send(
              key,
              NightIntent.of([
                if (victim != null &&
                    v.potions.contains(Potion.heal) &&
                    random.nextBool())
                  victim,
                if (v.potions.contains(Potion.poison) &&
                    poison.isNotEmpty &&
                    random.nextInt(3) == 0)
                  poison[random.nextInt(poison.length)].id,
              ]),
            );
          case NightAbility.inspect || NightAbility.decoy:
            send(key, NightIntent(pick()));
          case null:
            break;
        }
      case Phase.hunterShot when v.shooter == v.you:
        send(
          'shot${v.round}',
          ShootIntent(random.nextInt(4) == 0 ? null : pick()),
        );
      case Phase.day when link.isOwner:
        send('end${v.round}', const EndDiscussionIntent());
      case Phase.vote when me.isAlive:
        send(
          'vote${v.round}',
          VoteIntent(random.nextInt(5) == 0 ? null : pick()),
        );
      case Phase.night ||
          Phase.day ||
          Phase.vote ||
          Phase.hunterShot ||
          Phase.ended:
        break;
    }
  }
}

/// One table: a host (crashing now and then) and bots.
class Table {
  Table(this.seed) : random = Random(seed), sim = Sim() {
    net = ChaosNet(sim, Random(seed * 7 + 1));
    _startHost(null);
  }

  final int seed;
  final Random random;
  final Sim sim;
  late ChaosNet net;
  late GameHost host;
  int _generation = 0;
  String? saved;
  final phases = <Phase>[];
  final bots = <Bot>[];
  bool hostUp = true;

  void _startHost(String? snapshot) {
    final generation = ++_generation;
    host = snapshot == null
        ? GameHost(
            settings: const GameSettings(),
            roomCode: '1234',
            random: Random(seed),
            startTimer: sim.start,
            clock: sim.clock,
          )
        : GameHost.restore(
            snapshot,
            random: Random(seed + generation),
            startTimer: sim.start,
            clock: sim.clock,
          );
    host
      ..onSnapshot = (s) {
        // A dead host's leftover timers must not overwrite the save.
        if (generation != _generation) return;
        saved = s;
        final phase = host.state.phase;
        if (phases.isEmpty || phases.last != phase) phases.add(phase);
      }
      ..serve(net);
  }

  /// The owner plays on the host device: its in-process link dies with it.
  Connection? _owner;

  Future<Connection> dialOwner() async {
    if (!hostUp) throw StateError('host is down');
    return _owner = host.connectOwner();
  }

  Future<Connection> dial() async {
    if (!hostUp) throw StateError('host is down');
    return net.connect();
  }

  void addBot(String name, {bool owner = false}) {
    // Every table plays another set of rules: the base game or a preset.
    final rules = [null, for (final p in Preset.values) p.settings];
    final bot = Bot(
      name,
      Random(seed * 31 + bots.length),
      6,
      settings: owner ? rules[seed % rules.length] : null,
      peek: bots.length == 1 ? (p) => doorSignFor(host.state, p) : null,
    );
    bot.link = PlayerLink(
      name: name,
      roomCode: '1234',
      dial: owner ? dialOwner : dial,
      startTimer: sim.start,
      clock: sim.clock,
      random: Random(seed * 13 + bots.length),
      onChange: () => sim.start(
        Duration(milliseconds: 200 + bot.random.nextInt(3000)),
        () => bot.act(sim),
      ),
    );
    bots.add(bot);
  }

  /// The host dies now and comes back from its last save after [downMs].
  void crash(int downMs) {
    if (!hostUp) return; // already down
    hostUp = false;
    _generation++;
    unawaited(_owner?.close());
    net
      ..cutAll()
      ..weather = net.weather;
    final old = net;
    net = ChaosNet(sim, Random(seed * 7 + _generation));
    net.weather = old.weather;
    sim.start(Duration(milliseconds: downMs), () {
      _startHost(saved);
      hostUp = true;
    });
  }
}

const Set<(Phase, Phase)> _legal = {
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
};

String _json(PlayerView v) => jsonEncode(encodeView(v));

Future<void> playChaos(int seed) async {
  // The owner plays on the host device (its link is in-process).
  final t = Table(seed)..addBot('Owner', owner: true);
  for (var i = 1; i < 6; i++) {
    t.addBot('P$i');
  }
  bool over() => t.host.state.phase == Phase.ended;
  // Wait for the start, then crash the host at random moments of the game.
  await t.sim.run(
    30 * 60 * 1000,
    done: () => t.host.state.phase != Phase.lobby,
  );
  expect(
    t.host.state.phase,
    isNot(Phase.lobby),
    reason: 'seed $seed: no start',
  );
  for (var i = 0; i < 1 + t.random.nextInt(3); i++) {
    t.sim.start(
      Duration(milliseconds: t.random.nextInt(300000)),
      () => t.crash(2000 + t.random.nextInt(30000)),
    );
  }
  await t.sim.run(t.sim.now + 4 * 3600 * 1000, done: over);
  if (Platform.environment['CHAOS_DEBUG'] != null) {
    final bots = [
      for (final b in t.bots)
        '${b.name}:${b.link.status.name}:${b.link.view?.phase.name}',
    ];
    // Opt-in debugging output for one failing seed.
    // ignore: avoid_print
    print('seed $seed t=${t.sim.now} phase=${t.host.state.phase} $bots');
  }
  expect(over(), isTrue, reason: 'seed $seed: game did not end (${t.phases})');

  // Calm down and let everyone catch up.
  t
    ..net.weather = Weather.calm
    ..sim.start(const Duration(minutes: 3), () {});
  await t.sim.run(t.sim.now + 3 * 60 * 1000);

  // Phases only moved along the rules.
  for (var i = 1; i < t.phases.length; i++) {
    final step = (t.phases[i - 1], t.phases[i]);
    expect(_legal.contains(step), isTrue, reason: 'seed $seed: $step');
  }

  final state = t.host.state;
  final snapshotSeq = {
    for (final s in (jsonDecode(t.host.snapshot()) as Map)['sessions'] as List)
      (s as Map)['player'] as String: s['lastSeq'] as int,
  };
  final seated = [
    for (final bot in t.bots)
      if (bot.link.view case final v? when state.player(v.you) != null) bot,
  ];
  expect(seated.length, greaterThanOrEqualTo(5), reason: 'seed $seed');
  for (final bot in seated) {
    final link = bot.link;
    final view = link.view!;
    // Everyone sees exactly what the host says they may see.
    expect(
      _json(view),
      _json(viewFor(state, view.you)),
      reason:
          'seed $seed: ${bot.name} out of sync '
          '(${link.status.name}, sees ${view.phase.name}, is ${state.phase})',
    );
    // Every intent arrived and was confirmed; the host counted each once.
    expect(link.unconfirmed, 0, reason: 'seed $seed: ${bot.name} unconfirmed');
    expect(link.confirmed, bot.accepted, reason: 'seed $seed: ${bot.name}');
    expect(snapshotSeq[view.you.value], bot.accepted, reason: 'seed $seed');
    // No view ever showed a living player's hidden role.
    for (final v in bot.seen) {
      if (v.phase == Phase.ended) continue;
      for (final seat in v.seats) {
        if (seat.id == v.you || !seat.isAlive || seat.role == null) continue;
        expect(
          v.yourRole == Role.werewolf && seat.role == Role.werewolf,
          isTrue,
          reason: 'seed $seed: ${bot.name} saw ${seat.name}',
        );
      }
      // The lovers, the victim and the potions reach only whom they concern.
      if (v.couple.isNotEmpty) {
        expect(
          v.yourRole == Role.cupid || v.couple.contains(v.you),
          isTrue,
          reason: 'seed $seed: ${bot.name} saw the lovers',
        );
      }
      if (v.victim != null || v.potions.isNotEmpty) {
        expect(v.yourRole, Role.witch, reason: 'seed $seed: ${bot.name}');
      }
      // Door signs are one's own and only at night; the pack's mark only
      // reaches living werewolves.
      if (v.yourDoorSign != null) {
        expect(v.phase, Phase.night, reason: 'seed $seed: ${bot.name}');
        expect(v.yourSeat.isAlive, isTrue, reason: 'seed $seed: ${bot.name}');
      }
      if (v.packMark != null) {
        expect(v.yourRole, Role.werewolf, reason: 'seed $seed: ${bot.name}');
        expect(v.yourSeat.isAlive, isTrue, reason: 'seed $seed: ${bot.name}');
      }
    }
  }
}

void main() {
  final seeds = int.tryParse(Platform.environment['CHAOS_SEEDS'] ?? '') ?? 200;
  for (var seed = 0; seed < seeds; seed++) {
    test('chaos seed $seed', () => playChaos(seed));
  }
}
