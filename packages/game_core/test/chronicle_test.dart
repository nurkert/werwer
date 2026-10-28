import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  const roles = [
    Role.werewolf,
    Role.seer,
    Role.witch,
    Role.villager,
    Role.villager,
    Role.villager,
  ];

  test('the chronicle tells the whole game at the end, night by night', () {
    var state = night(roles);
    // The wolf picks p3; the witch saves him and poisons p4.
    state = playNight(state, {0: 3}, brew: [3, 4]).state;
    expectNoLeaks(state);
    expect(viewFor(state, id(3)).chronicle, isEmpty);
    // The village votes out the wolf: the game is over.
    state = voteOut(state, 0).state;
    expect(state.phase, Phase.ended);
    expectNoLeaks(state);
    final told = viewFor(state, id(5)).chronicle;
    final kinds = [for (final e in told) e.kind];
    expect(kinds.take(4), [
      ChronicleKind.hunt,
      ChronicleKind.look,
      ChronicleKind.heal,
      ChronicleKind.poison,
    ]);
    expect(told.first.target, id(3));
    expect(told.firstWhere((e) => e.kind == ChronicleKind.look).actor, id(1));
    expect(
      told.firstWhere((e) => e.kind == ChronicleKind.poison).target,
      id(4),
    );
    final votes = told.where((e) => e.kind == ChronicleKind.vote).toList();
    expect(votes, hasLength(state.players.where((p) => p.isAlive).length + 1));
    expect(votes.where((v) => v.target == id(0)), hasLength(votes.length - 1));
  });

  test('with open voting everyone sees the votes as they come, and the '
      'day after how they went', () {
    var state = night(roles, settings: const GameSettings(openVotes: true));
    state = playNight(state, {0: 3}).state;
    state = apply(state, const EndDiscussion()).state;
    state = apply(state, CastVote(id(1), id(0))).state;
    expect(viewFor(state, id(5)).openVotes, {id(1): id(0)});
    expectNoLeaks(state);
    for (final p in state.alive.toList()) {
      if (p.id == id(1)) continue;
      final target = p.id == id(5) ? id(4) : id(5);
      state = apply(state, CastVote(p.id, target)).state;
    }
    if (state.phase != Phase.ended) {
      expectNoLeaks(state);
      expect(
        viewFor(state, id(1)).chronicle.every(
          (e) => e.kind == ChronicleKind.vote,
        ),
        isTrue,
      );
      expect(viewFor(state, id(1)).chronicle, isNotEmpty);
    }
  });
}
