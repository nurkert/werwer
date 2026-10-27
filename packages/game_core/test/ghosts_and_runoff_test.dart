import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('runoff', () {
    const roles = [
      Role.werewolf,
      Role.seer,
      Role.villager,
      Role.villager,
      Role.villager,
    ];

    // After the night seat 4 is dead; 0 to 3 vote.
    GameState day() => playNight(night(roles), {0: 4}).state;

    test('a tie leads to a runoff between the tied only', () {
      final tie = playVote(day(), {0: 2, 1: 0, 2: 0, 3: 2});
      expect(tie.state.phase, Phase.vote);
      expect(tie.state.runoff, [id(0), id(2)]);
      expect(tie.events.whereType<RunoffStarted>().single.candidates, [
        id(0),
        id(2),
      ]);
      expect(tie.state.votes, isEmpty);
      expect(
        timeLimit(tie.state),
        const GameSettings().voteTime ~/ 2,
        reason: 'a runoff takes half the time',
      );
      expect(viewFor(tie.state, id(1)).runoff, [id(0), id(2)]);
      expect(publicView(tie.state).runoff, [id(0), id(2)]);

      // Only the tied can be voted for.
      expect(
        () => apply(tie.state, CastVote(id(1), id(3))),
        throwsA(isA<RuleViolation>()),
      );
      var state = tie.state;
      for (final (voter, target) in [(0, 2), (1, 0), (2, 0), (3, 0)]) {
        state = apply(state, CastVote(id(voter), id(target))).state;
      }
      expect(state.player(id(0))!.isAlive, isFalse);
      expect(state.runoff, isEmpty);
    });

    test('a second tie spares everyone and night falls', () {
      final tie = playVote(day(), {0: 2, 1: 0, 2: 0, 3: 2}).state;
      var state = tie;
      for (final (voter, target) in [(0, 2), (1, 0), (2, 0), (3, 2)]) {
        state = apply(state, CastVote(id(voter), id(target))).state;
      }
      expect(state.alive, hasLength(4));
      expect(state.phase, Phase.night);
      expect(state.round, 2);
      expect(state.runoff, isEmpty);
    });

    test('a runoff that runs out without votes spares everyone', () {
      final tie = playVote(day(), {0: 2, 1: 0, 2: 0, 3: 2}).state;
      final out = apply(tie, const PhaseTimeout()).state;
      expect(out.phase, Phase.night);
      expect(out.alive, hasLength(4));
    });
  });

  group('ghosts', () {
    const roles = [
      Role.werewolf,
      Role.seer,
      Role.villager,
      Role.villager,
      Role.villager,
    ];

    test('with everything, the dead see all roles and the night live', () {
      final day = playNight(night(roles), {0: 4}).state;
      final ghost = viewFor(day, id(4));
      expect(ghost.yourGhostSight, GhostSight.everything);
      expect(ghost.seats.map((s) => s.role), roles);
      // The next night, as it happens.
      var state = voteOut(day, 3).state;
      expect(state.phase, Phase.night);
      state = apply(state, nightAction(state, id(0), [id(2)])).state;
      final live = viewFor(state, id(4)).ghost!;
      expect(live.night[id(0)], [id(2)]);
      // The living see none of it.
      expect(viewFor(state, id(1)).ghost, isNull);
      expect(viewFor(state, id(1)).seats[0].role, isNull);
    });

    test('with roles only, the dead see the roles but not the night', () {
      final day = playNight(
        night(
          roles,
          settings: const GameSettings(ghosts: GhostSight.roles),
        ),
        {0: 4},
      ).state;
      final ghost = viewFor(day, id(4));
      expect(ghost.yourGhostSight, GhostSight.roles);
      expect(ghost.seats.map((s) => s.role), roles);
      expect(ghost.ghost, isNull);
    });

    test('switched off, the dead see no more than before', () {
      final day = playNight(
        night(
          roles,
          settings: const GameSettings(
            ghosts: GhostSight.off,
            revealRoleOnDeath: false,
          ),
        ),
        {0: 4},
      ).state;
      final ghost = viewFor(day, id(4));
      expect(ghost.yourGhostSight, GhostSight.off);
      expect(ghost.ghost, isNull);
      expect(ghost.seats[0].role, isNull);
    });

    test('the dead hunter sees no more until he has shot', () {
      const withHunter = [
        Role.werewolf,
        Role.werewolf,
        Role.hunter,
        Role.seer,
        Role.villager,
        Role.villager,
        Role.villager,
      ];
      final aiming = playNight(night(withHunter), {0: 2, 1: 2}).state;
      expect(aiming.phase, Phase.hunterShot);
      final hunter = viewFor(aiming, id(2));
      expect(hunter.yourGhostSight, GhostSight.off);
      expect(hunter.ghost, isNull);
      expect(hunter.seats[0].role, isNull, reason: 'he would know whom to hit');

      final shot = apply(aiming, HunterShoot(id(2), id(4))).state;
      expect(viewFor(shot, id(2)).yourGhostSight, GhostSight.everything);
      expect(viewFor(shot, id(2)).seats[0].role, Role.werewolf);
    });

    test('random games with every ghost sight never leak to the living', () {
      for (final sight in GhostSight.values) {
        var state = night(
          roles,
          settings: GameSettings(ghosts: sight, revealRoleOnDeath: false),
        );
        for (var round = 0; round < 3 && state.phase != Phase.ended; round++) {
          state = playNight(state, {0: round + 2}).state;
          expectNoLeaks(state);
          if (state.phase != Phase.day) break;
          state = voteOut(state, seatOf(state.alive.last.id)).state;
          expectNoLeaks(state);
        }
      }
    });
  });
}
