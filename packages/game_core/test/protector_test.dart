import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  const roles = [
    Role.werewolf,
    Role.protector,
    Role.witch,
    Role.villager,
    Role.villager,
  ];
  final settings = const GameSettings().copyWith(
    roles: {Role.protector, Role.witch},
  );

  /// Everyone picks in Whowolf's hunt: the wolf takes [prey], the
  /// protector shields [guard], the rest decoy.
  GameState hunt(GameState state, {required int prey, required int guard}) {
    var next = state;
    for (final p in state.alive) {
      final other = state.alive.firstWhere((o) => o.id != p.id).id;
      final pick = switch (nightTask(next, p.id)) {
        NightAbility.hunt => id(prey),
        NightAbility.protect => id(guard),
        _ => other,
      };
      next = apply(next, nightAction(next, p.id, [pick])).state;
    }
    return huntOver(next);
  }

  test('the shielded victim lives, and the witch does not even see them', () {
    final brew = hunt(night(roles, settings: settings), prey: 3, guard: 3);
    expect(brew.nightStep, NightStep.brew);
    expect(viewFor(brew, id(2)).victim, isNull);
    final morning = apply(brew, const PhaseTimeout()).state;
    expect(morning.phase, Phase.day);
    expect(morning.player(id(3))!.isAlive, isTrue);
    expect(morning.deaths, isEmpty);
    expect(
      morning.chronicle.where((e) => e.kind == ChronicleKind.protect).single,
      isA<ChronicleEntry>()
          .having((e) => e.target, 'target', id(3))
          .having((e) => e.actor, 'actor', id(1)),
    );
    expectNoLeaks(morning);
  });

  test('a shield elsewhere does not help', () {
    final brew = hunt(night(roles, settings: settings), prey: 3, guard: 4);
    expect(viewFor(brew, id(2)).victim, id(3));
    final morning = apply(brew, const PhaseTimeout()).state;
    expect(morning.player(id(3))!.isAlive, isFalse);
  });

  test('himself is fine, the same player two nights in a row is not', () {
    final brew = hunt(night(roles, settings: settings), prey: 3, guard: 1);
    final day = apply(brew, const PhaseTimeout()).state;
    final next = voteOut(day, 4).state;
    expect(next.phase, Phase.night);
    expect(viewFor(next, id(1)).guardedBefore, id(1));
    expect(viewFor(next, id(3)).guardedBefore, isNull, reason: 'only his');
    expect(
      () => apply(next, nightAction(next, id(1), [id(1)])),
      refuses(Violation.invalidTarget),
    );
    apply(next, nightAction(next, id(1), [id(2)]));
  });

  test('in the called night he is called before the werewolves', () {
    final called = Preset.classic.settings.copyWith(
      roles: {Role.protector, Role.witch},
    );
    var state = night(roles, settings: called);
    expect(calledSteps(state), [
      NightStep.protect,
      NightStep.hunt,
      NightStep.brew,
    ]);
    expect(state.nightStep, NightStep.protect);
    expect(nightTask(state, id(1)), NightAbility.protect);
    expect(nightTask(state, id(0)), isNull);
    state = apply(state, nightAction(state, id(1), [id(3)])).state;
    state = apply(state, const PhaseTimeout()).state;
    expect(state.nightStep, NightStep.hunt);
    state = apply(state, nightAction(state, id(0), [id(3)])).state;
    state = apply(state, const PhaseTimeout()).state;
    expect(viewFor(state, id(2)).victim, isNull);
    state = apply(state, const PhaseTimeout()).state;
    expect(state.phase, Phase.day);
    expect(state.player(id(3))!.isAlive, isTrue);
  });
}
