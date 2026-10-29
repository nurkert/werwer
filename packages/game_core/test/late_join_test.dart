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
  ];
  const ghosts = GameSettings(roles: {});
  const villagers = GameSettings(roles: {}, lateJoin: LateJoin.villager);

  /// The first day: the werewolf (0) took 4 in the night.
  GameState firstDay(GameSettings settings) =>
      playNight(night(roles, settings: settings), {0: 4}).state;

  test('new rooms let latecomers in as ghosts', () {
    expect(const GameSettings().lateJoin, LateJoin.ghost);
  });

  test('a latecomer joins only by day', () {
    final first = night(roles, settings: ghosts);
    expect(
      () => apply(first, JoinLate(id(5), 'Fynn')),
      refuses(Violation.wrongPhase),
    );
    expect(
      () => apply(lobby(3), JoinLate(id(5), 'Fynn')),
      refuses(Violation.wrongPhase),
    );
    final vote = apply(firstDay(ghosts), const EndDiscussion()).state;
    expect(
      () => apply(vote, JoinLate(id(5), 'Fynn')),
      refuses(Violation.wrongPhase),
    );
  });

  test('a latecomer needs a free name and a new id', () {
    final day = firstDay(ghosts);
    expect(
      () => apply(day, JoinLate(id(5), ' ada ')),
      refuses(Violation.invalidName),
    );
    expect(
      () => apply(day, JoinLate(id(5), '')),
      refuses(Violation.invalidName),
    );
    expect(
      () => apply(day, JoinLate(id(1), 'Fynn')),
      refuses(Violation.duplicatePlayer),
    );
  });

  test('as a ghost: dead from the start, no death to tell, nothing changes '
      'about who can win', () {
    final day = firstDay(ghosts);
    final update = apply(day, JoinLate(id(5), ' Fynn '));
    final state = update.state;
    final fynn = state.player(id(5))!;
    expect(fynn.name, 'Fynn');
    expect(fynn.isAlive, isFalse);
    expect(fynn.role, Role.villager);
    expect(state.alive.length, day.alive.length);
    expect(state.deaths, day.deaths, reason: 'nobody died');
    expect(update.events.single, isA<PlayerJoined>());
    expect(state.phase, Phase.day);
    expect(state.winner, isNull);
    // Watches as the dead do, by the table's ghost rules.
    expect(viewFor(state, id(5)).yourGhostSight, ghosts.ghosts);
    expectNoLeaks(state);
    // A ghost has no say in the vote.
    final vote = apply(state, const EndDiscussion()).state;
    expect(
      () => apply(vote, CastVote(id(5), id(0))),
      refuses(Violation.playerDead),
    );
  });

  test('as a villager: alive, sees only their own role, and their vote '
      'counts', () {
    final day = firstDay(villagers);
    final state = apply(day, JoinLate(id(5), 'Fynn')).state;
    final fynn = state.player(id(5))!;
    expect(fynn.isAlive, isTrue);
    expect(fynn.role, Role.villager);
    final view = viewFor(state, id(5));
    expect(view.yourRole, Role.villager);
    for (final seat in view.seats) {
      final p = state.player(seat.id)!;
      if (p.id != id(5) && p.isAlive) {
        expect(seat.role, isNull, reason: 'sees ${p.id}');
      }
    }
    expectNoLeaks(state);

    // Four villagers and the newcomer against the werewolf: the newcomer's
    // vote is one of the four that take the werewolf out.
    // Everyone voted: the vote is counted at once.
    final out = playVote(state, {0: 1, 1: 0, 2: 0, 3: 0, 5: 0}).state;
    expect(out.player(id(0))!.isAlive, isFalse);
    expect(out.winner, Faction.village);
  });

  test('a living latecomer keeps the werewolves from winning too early', () {
    // Two werewolves, two villagers left after the night: without the
    // newcomer the werewolves would be as many as the rest.
    const five = [
      Role.werewolf,
      Role.werewolf,
      Role.villager,
      Role.villager,
      Role.villager,
      Role.villager,
    ];
    final day = playNight(night(five, settings: villagers), {0: 5, 1: 5}).state;
    var state = apply(day, JoinLate(id(6), 'Gul')).state;
    // The village votes out a villager by mistake: 2 werewolves against 2
    // villagers and the newcomer, the game goes on.
    state = voteOut(state, 4).state;
    expect(state.player(id(4))!.isAlive, isFalse);
    expect(state.winner, isNull);
    expect(state.phase, isNot(Phase.ended));
  });
}
