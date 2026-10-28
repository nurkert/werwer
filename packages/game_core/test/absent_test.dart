import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

/// Someone whose phone is gone never holds a game up: every step a player
/// would act in has a time limit, and when it runs out the game goes on.
void main() {
  const table = [
    Role.werewolf,
    Role.seer,
    Role.witch,
    Role.cupid,
    Role.villager,
    Role.hunter,
    Role.villager,
  ];

  /// Times out [state] once and checks that something moved on.
  GameState runOut(GameState state, String what) {
    expect(timeLimit(state), isNotNull, reason: '$what has a time limit');
    final next = apply(state, const PhaseTimeout()).state;
    expect(
      (next.phase, next.nightStep, next.round),
      isNot((state.phase, state.nightStep, state.round)),
      reason: '$what goes on after its time',
    );
    return next;
  }

  for (final mode in NightMode.values) {
    test('in the ${mode.name} night every step goes on without the absent', () {
      final settings = const GameSettings().copyWith(
        nightMode: mode,
        roles: {Role.seer, Role.witch, Role.hunter, Role.cupid},
      );
      var state = night(table, settings: settings);
      // Nobody acts at all: cupid, the werewolves, the seer and the witch
      // all miss their step.
      for (var i = 0; i < 6 && state.phase == Phase.night; i++) {
        state = runOut(state, 'the ${state.nightStep.name} step');
      }
      expect(state.phase, Phase.day);
    });
  }

  test('a vote nobody finishes is counted when its time is up', () {
    final day = playNight(night(table), {0: 4}).state;
    expect(day.phase, Phase.day);
    final vote = apply(day, const EndDiscussion()).state;
    expect(runOut(vote, 'the vote').phase, isNot(Phase.vote));
  });

  test('a hunter who does not shoot lets the game go on', () {
    final shot = playNight(night(table), {0: 5}).state;
    expect(shot.phase, Phase.hunterShot);
    expect(runOut(shot, "the hunter's shot").phase, isNot(Phase.hunterShot));
  });
}
