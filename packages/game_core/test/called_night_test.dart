// The night everyone knows: eyes closed, the narrator calls one role after
// another, and only whoever is called acts.
import 'dart:math';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final called = Preset.classic.settings.copyWith(
    roles: {Role.seer, Role.witch, Role.hunter, Role.cupid},
  );
  const table = [
    Role.werewolf,
    Role.seer,
    Role.witch,
    Role.cupid,
    Role.villager,
    Role.hunter,
  ];

  List<int> tasks(GameState state) => [
    for (final p in state.alive)
      if (nightTask(state, p.id) != null) seatOf(p.id),
  ];

  test('the classic preset calls the roles', () {
    expect(Preset.classic.settings.nightMode, NightMode.called);
    expect(Preset.classic.settings.narratorVoice, isTrue);
    expect(Preset.whowolf.settings.nightMode, NightMode.together);
  });

  test('cupid, the werewolves, the seer and the witch, one after another', () {
    var state = night(table, settings: called);
    expect(calledSteps(state), [
      NightStep.link,
      NightStep.hunt,
      NightStep.inspect,
      NightStep.brew,
    ]);
    // Cupid first; everyone else has their eyes closed.
    expect(state.nightStep, NightStep.link);
    expect(tasks(state), [3]);
    expect(viewFor(state, id(4)).yourNightTask, isNull);
    expect(
      () => apply(state, nightAction(state, id(0), [id(4)])),
      refuses(Violation.notYourAction),
    );
    state = apply(state, nightAction(state, id(3), [id(4), id(5)])).state;
    // The step ends by its time, never right after the pick.
    expect(state.nightStep, NightStep.link);
    expect(calledStepPending(state), isFalse);
    expect(timeLimit(state), calledStepTime);
    state = apply(state, const PhaseTimeout()).state;
    expect(state.lovers, [id(4), id(5)]);

    expect(state.nightStep, NightStep.hunt);
    expect(tasks(state), [0]);
    state = apply(state, nightAction(state, id(0), [id(1)])).state;
    state = apply(state, const PhaseTimeout()).state;

    expect(state.nightStep, NightStep.inspect);
    expect(tasks(state), [1]);
    final update = apply(state, nightAction(state, id(1), [id(0)]));
    expect(
      update.events.whereType<SeerSaw>().single.result.role,
      Role.werewolf,
    );
    state = apply(update.state, const PhaseTimeout()).state;

    expect(state.nightStep, NightStep.brew);
    expect(tasks(state), [2]);
    expect(viewFor(state, id(2)).victim, id(1));
    // The witch saves the seer.
    state = apply(state, nightAction(state, id(2), [id(1)])).state;
    state = apply(state, const PhaseTimeout()).state;
    expect(state.phase, Phase.day);
    expect(state.alive, hasLength(6));
  });

  test('the second night has no cupid step', () {
    final first = playNight(night(table, settings: called), {0: 4});
    var state = first.state;
    expect(state.phase, Phase.day);
    state = voteOut(state, 2).state; // the witch goes
    expect(state.phase, Phase.night);
    expect(state.round, 2);
    expect(state.nightStep, NightStep.hunt);
  });

  test('a dead role is still called, for a while, so nobody hears who is '
      'gone', () {
    final plain = called.copyWith(roles: {Role.seer, Role.witch});
    var state = night(const [
      Role.werewolf,
      Role.seer,
      Role.witch,
      Role.villager,
      Role.villager,
      Role.villager,
    ], settings: plain);
    state = playNight(state, {0: 3}).state;
    state = voteOut(state, 1).state; // the seer goes
    expect(state.phase, Phase.night);
    expect(state.nightStep, NightStep.hunt);
    state = apply(state, nightAction(state, id(0), [id(4)])).state;
    state = apply(state, const PhaseTimeout()).state;
    // The seer's step comes all the same, with nobody to call, and lasts
    // as long as a quick living seer's would.
    expect(state.nightStep, NightStep.inspect);
    expect(tasks(state), isEmpty);
    expect(timeLimit(state), calledStepTime);
    state = apply(state, const PhaseTimeout()).state;
    expect(state.nightStep, NightStep.brew);
  });

  test('the pack must agree before its step can end', () {
    var state = night(const [
      Role.werewolf,
      Role.werewolf,
      Role.seer,
      Role.villager,
      Role.villager,
      Role.villager,
      Role.villager,
    ], settings: called.copyWith(roles: {Role.seer}));
    expect(state.nightStep, NightStep.hunt);
    state = apply(state, nightAction(state, id(0), [id(3)])).state;
    state = apply(state, nightAction(state, id(1), [id(4)])).state;
    // They disagree: the step goes on and the time stays the full one.
    expect(calledStepPending(state), isTrue);
    expect(timeLimit(state), called.nightTime);
    state = apply(state, nightAction(state, id(1), [id(3)])).state;
    expect(calledStepPending(state), isFalse);
    state = apply(state, const PhaseTimeout()).state;
    expect(state.nightVictim, id(3));
  });

  test('nobody learns how many wolves are picking', () {
    var state = night(table, settings: called);
    state = apply(state, nightAction(state, id(3), [id(4), id(5)])).state;
    state = apply(state, const PhaseTimeout()).state;
    expect(viewFor(state, id(4)).waitingFor, 0);
    state = apply(state, nightAction(state, id(0), [id(1)])).state;
    expect(viewFor(state, id(4)).waitingFor, 0);
  });

  test('whole called games always end by the rules', () {
    for (var seed = 0; seed < 60; seed++) {
      final random = Random(seed);
      var state = apply(
        lobby(7, settings: called),
        StartGame(random: random),
      ).state;
      for (final p in state.players) {
        state = apply(state, ConfirmRole(p.id)).state;
      }
      for (var step = 0; step < 400 && state.phase != Phase.ended; step++) {
        final alive = state.alive.toList();
        PlayerId other(PlayerId me) {
          final others = alive.where((p) => p.id != me).toList();
          return others[random.nextInt(others.length)].id;
        }

        GameAction action;
        switch (state.phase) {
          case Phase.night:
            final actors = [
              for (final p in alive)
                if (nightTask(state, p.id) != null) p,
            ];
            if (!calledStepPending(state)) {
              action = const PhaseTimeout();
              break;
            }
            final p = actors.firstWhere(
              (a) => !state.nightChoices.containsKey(a.id),
              orElse: () => actors.first,
            );
            final targets = switch (nightTask(state, p.id)!) {
              NightAbility.link => [p.id, other(p.id)],
              NightAbility.brew => <PlayerId>[],
              NightAbility.hunt => [
                alive.firstWhere((o) => o.role != Role.werewolf).id,
              ],
              _ => [other(p.id)],
            };
            action = nightAction(state, p.id, targets);
          case Phase.day:
            action = const EndDiscussion();
          case Phase.vote:
            final voter = alive.firstWhere(
              (p) => !state.votes.containsKey(p.id),
            );
            action = CastVote(
              voter.id,
              state.runoff.isEmpty
                  ? other(voter.id)
                  : state.runoff.firstWhere((p) => p != voter.id),
            );
          case Phase.hunterShot:
            action = HunterShoot(state.shooter!, null);
          case Phase.lobby || Phase.roleReveal || Phase.ended:
            fail('unexpected ${state.phase}');
        }
        state = apply(state, action).state;
      }
      expect(state.phase, Phase.ended, reason: 'seed $seed');
    }
  });
}
