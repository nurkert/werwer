import 'dart:math';

import 'package:game_core/game_core.dart';
import 'package:game_host/game_host.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

/// No lead before a new phase: these tests count the phases' own times.
const noLead = HostConfig(switchLead: Duration.zero);

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('a called step lasts its time from its start, whatever happens in it, '
      'and only the called see that time', () async {
    var now = 1000000;
    final timers = <(int, void Function())>[];
    void Function() hostTimer(Duration after, void Function() callback) {
      final entry = (now + after.inMilliseconds, callback);
      timers.add(entry);
      return () => timers.remove(entry);
    }

    // The players' own timers (pings, resends) do not matter here.
    void Function() startTimer(Duration after, void Function() callback) =>
        () {};

    final host = GameHost(
      config: noLead,
      roomCode: '1234',
      random: Random(5),
      settings: Preset.classic.settings.copyWith(roles: {Role.seer}),
      startTimer: hostTimer,
      clock: () => now,
    );
    addTearDown(host.close);
    final memory = MemoryTransport();
    host.serve(memory);
    final links = [
      for (var i = 0; i < 5; i++)
        PlayerLink(
          name: 'P$i',
          roomCode: '1234',
          dial: () async => i == 0 ? host.connectOwner() : memory.connect(),
          startTimer: startTimer,
          clock: () => now,
          random: Random(i),
        ),
    ];
    addTearDown(() {
      for (final l in links) {
        l.close();
      }
    });
    await settle();
    await settle();
    links.first.send(const StartGameIntent());
    await settle();
    for (final l in links) {
      l.send(const ConfirmRoleIntent());
    }
    await settle();
    await settle();
    expect(host.state.phase, Phase.night);
    expect(host.state.nightStep, NightStep.hunt);
    final wolf = links.firstWhere((l) => l.view!.yourRole == Role.werewolf);
    final villager = links.firstWhere(
      (l) => l.view!.yourRole == Role.villager,
    );
    expect(wolf.phaseEndsAtMs, isNotNull);
    expect(villager.phaseEndsAtMs, isNull, reason: 'not called: no clock');

    // Two seconds in, the wolf picks: the step now ends 8 s after its
    // start, not 8 s after the pick and not right away.
    now += 2000;
    final prey = wolf.view!.seats.firstWhere(
      (s) => s.isAlive && s.id != wolf.view!.you,
    );
    wolf.send(NightIntent(prey.id));
    await settle();
    await settle();
    expect(host.state.nightStep, NightStep.hunt);
    final due = timers.map((t) => t.$1).reduce(min);
    expect(due, 1000000 + calledStepTime.inMilliseconds);

    // The seer's step: she looks late, after the step's least time, and
    // still has her moment to take in the vision before eyes close.
    timers.firstWhere((t) => t.$1 == due).$2();
    timers.removeWhere((t) => t.$1 == due);
    await settle();
    await settle();
    expect(host.state.nightStep, NightStep.inspect);
    final seer = links.firstWhere((l) => l.view!.yourRole == Role.seer);
    now += 20000;
    final look = seer.view!.seats.firstWhere(
      (s) => s.isAlive && s.id != seer.view!.you,
    );
    seer.send(NightIntent(look.id));
    await settle();
    await settle();
    expect(host.state.nightStep, NightStep.inspect);
    final ends = timers.map((t) => t.$1).reduce(max);
    expect(ends, now + GameHost.seerLookTime.inMilliseconds);
  });
}
