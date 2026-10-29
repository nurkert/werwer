import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  const roles = [
    Role.werewolf,
    Role.villager,
    Role.villager,
    Role.villager,
    Role.villager,
    Role.villager,
  ];
  final settings = const GameSettings().copyWith(roles: {}, mayor: true);

  GameState firstDay() =>
      playNight(night(roles, settings: settings), {0: 5}).state;

  test('the first day elects a mayor openly; their vote counts twice', () {
    var day = firstDay();
    expect(day.electsMayor, isTrue);
    for (final p in day.alive) {
      day = apply(day, BackMayor(p.id, id(1))).state;
    }
    expect(day.mayor, id(1), reason: 'everyone backed 1: elected at once');
    expect(day.electsMayor, isFalse);
    expect(viewFor(day, id(3)).mayor, id(1));
    expect(
      () => apply(day, BackMayor(id(2), id(2))),
      refuses(Violation.wrongPhase),
    );
    // 1 (the mayor) and 2 for 3; 3 and 4 for 2: the mayor's two votes win.
    final voted = playVote(day, {1: 3, 2: 3, 3: 2, 4: 2});
    final out = apply(voted.state, const PhaseTimeout()).state;
    expect(out.player(id(3))!.isAlive, isFalse);
  });

  test('a tied ballot leaves the village without a mayor for the day', () {
    var day = firstDay();
    day = apply(day, BackMayor(id(1), id(1))).state;
    day = apply(day, BackMayor(id(2), id(2))).state;
    final vote = apply(day, const EndDiscussion());
    expect(vote.state.phase, Phase.vote);
    expect(vote.state.mayor, isNull);
    expect(vote.state.mayorVotes, isEmpty);
  });

  test('the ballot closes with the talk: a single leader wins', () {
    var day = firstDay();
    day = apply(day, BackMayor(id(1), id(2))).state;
    final vote = apply(day, const EndDiscussion());
    expect(vote.state.mayor, id(2));
    expect(vote.events.whereType<MayorElected>().single.mayor, id(2));
  });

  test('when the mayor dies, the next day elects a new one', () {
    var day = firstDay();
    day = apply(day, BackMayor(id(1), id(2))).state;
    day = apply(day, const EndDiscussion()).state;
    final night2 = voteOut(day.copyWith(phase: Phase.day), 2).state;
    expect(night2.player(id(2))!.isAlive, isFalse);
    final day2 = playNight(night2, {0: 4}).state;
    expect(day2.phase, Phase.day);
    expect(day2.electsMayor, isTrue);
  });

  test('the chronicle tells everyone who became mayor, during the game', () {
    var day = firstDay();
    day = apply(day, BackMayor(id(1), id(2))).state;
    day = apply(day, const EndDiscussion()).state;
    expect(day.settings.openVotes, isFalse);
    for (final p in day.players) {
      final entries = viewFor(day, p.id).chronicle;
      expect(entries, hasLength(1), reason: 'only the public election');
      expect(entries.single.kind, ChronicleKind.mayor);
      expect(entries.single.target, id(2));
      expect(entries.single.round, day.round);
    }
  });

  test('without the setting there is no ballot', () {
    final day = playNight(night(roles), {0: 5}).state;
    expect(day.electsMayor, isFalse);
    expect(
      () => apply(day, BackMayor(id(1), id(1))),
      refuses(Violation.wrongPhase),
    );
  });
}
