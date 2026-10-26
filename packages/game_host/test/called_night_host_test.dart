import 'dart:math';

import 'package:game_core/game_core.dart';
import 'package:game_host/game_host.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

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
  });
}
