import 'dart:math';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('roles', () {
    test('suggestRoles fits every size from minPlayers to maxPlayers', () {
      for (var n = minPlayers; n <= maxPlayers; n++) {
        final roles = suggestRoles(n);
        final wolves = roles.where((r) => r == Role.werewolf).length;
        expect(roles, hasLength(n));
        expect(wolves, greaterThan(0));
        expect(wolves, lessThan(n - wolves));
        expect(roles.where((r) => r == Role.seer), hasLength(n >= 4 ? 1 : 0));
      }
      expect(suggestRoles(5).where((r) => r == Role.werewolf), hasLength(1));
      expect(suggestRoles(8).where((r) => r == Role.werewolf), hasLength(2));
      expect(suggestRoles(20).where((r) => r == Role.werewolf), hasLength(5));
    });

    test('suggestRoles refuses too few or too many players', () {
      expect(() => suggestRoles(minPlayers - 1), throwsArgumentError);
      expect(() => suggestRoles(maxPlayers + 1), throwsArgumentError);
    });

    test('the same seed deals the same roles', () {
      List<Role?> deal(int seed) => apply(
        lobby(8),
        StartGame(random: Random(seed)),
      ).state.players.map((p) => p.role).toList();
      expect(deal(42), deal(42));
      expect(
        {for (var s = 0; s < 10; s++) deal(s).join()},
        hasLength(greaterThan(1)),
      );
    });
  });

  group('lobby', () {
    test('players join and leave', () {
      final state = lobby(3);
      expect(state.players.map((p) => p.name), ['Ada', 'Bo', 'Cem']);
      final left = apply(state, RemovePlayer(id(1)));
      expect(left.state.players.map((p) => p.name), ['Ada', 'Cem']);
      expect(left.events.single, isA<PlayerLeft>());
    });

    test('names must be unique, non-empty and short', () {
      final state = lobby(1);
      expect(
        () => apply(state, AddPlayer(id(9), ' ada ')),
        refuses(Violation.invalidName),
      );
      expect(
        () => apply(state, AddPlayer(id(9), '   ')),
        refuses(Violation.invalidName),
      );
      expect(
        () => apply(state, AddPlayer(id(9), 'x' * (maxNameLength + 1))),
        refuses(Violation.invalidName),
      );
      expect(
        () => apply(state, AddPlayer(id(0), 'Zoe')),
        refuses(Violation.duplicatePlayer),
      );
    });

    test('the game is full at maxPlayers', () {
      var state = GameState.lobby();
      for (var i = 0; i < maxPlayers; i++) {
        state = apply(state, AddPlayer(id(i), 'P$i')).state;
      }
      expect(
        () => apply(state, AddPlayer(id(99), 'Late')),
        refuses(Violation.gameFull),
      );
    });

    test('starting needs enough players and sensible roles', () {
      expect(
        () => apply(lobby(2), StartGame(random: Random(1))),
        refuses(Violation.playerCount),
      );
      expect(
        () => apply(
          lobby(4),
          StartGame(random: Random(1), roles: List.filled(4, Role.villager)),
        ),
        refuses(Violation.invalidRoles),
      );
      expect(
        () => apply(
          lobby(4),
          StartGame(
            random: Random(1),
            roles: const [Role.werewolf, Role.werewolf, Role.seer, Role.seer],
          ),
        ),
        refuses(Violation.invalidRoles),
      );
      expect(
        () => apply(
          lobby(4),
          StartGame(random: Random(1), roles: const [Role.werewolf]),
        ),
        refuses(Violation.invalidRoles),
      );
    });

    test('joining after the start is refused', () {
      final started = apply(lobby(5), StartGame(random: Random(1))).state;
      expect(
        () => apply(started, AddPlayer(id(9), 'Late')),
        refuses(Violation.wrongPhase),
      );
      expect(
        () => apply(started, RemovePlayer(id(0))),
        refuses(Violation.wrongPhase),
      );
    });
  });

  group('personas', () {
    test('joiners get free personas; personas can be changed in the lobby', () {
      var state = lobby(3);
      expect(state.players.map((p) => p.persona).toSet(), hasLength(3));
      state = apply(state, ChoosePersona(id(0), Persona.smith)).state;
      expect(state.player(id(0))!.persona, Persona.smith);
      expect(
        () => apply(state, ChoosePersona(id(1), Persona.smith)),
        refuses(Violation.personaTaken),
      );
      state = apply(
        state,
        AddPlayer(id(7), 'Hugo', persona: Persona.shepherd),
      ).state;
      expect(viewFor(state, id(1)).seats.last.persona, Persona.shepherd);
    });

    test('a full table has a persona for everyone', () {
      expect(Persona.values, hasLength(maxPlayers));
      var state = GameState.lobby();
      for (var i = 0; i < maxPlayers; i++) {
        state = apply(state, AddPlayer(id(i), 'P$i')).state;
      }
      expect(
        state.players.map((p) => p.persona).toSet(),
        Persona.values.toSet(),
      );
      // Everyone has their own, so nobody can take another's.
      expect(
        () => apply(state, ChoosePersona(id(maxPlayers - 1), Persona.maid)),
        refuses(Violation.personaTaken),
      );
    });

    test('seats can be swapped in the lobby only', () {
      var state = lobby(3);
      state = apply(state, SwapSeats(id(0), id(2))).state;
      expect(state.players.map((p) => p.name), ['Cem', 'Bo', 'Ada']);
      expect(viewFor(state, id(1)).seats.first.name, 'Cem');
      final started = apply(lobby(5), StartGame(random: Random(1))).state;
      expect(
        () => apply(started, SwapSeats(id(0), id(1))),
        refuses(Violation.wrongPhase),
      );
    });

    test('personas are only chosen in the lobby', () {
      final started = apply(lobby(5), StartGame(random: Random(1))).state;
      expect(
        () => apply(started, ChoosePersona(id(0), Persona.smith)),
        refuses(Violation.wrongPhase),
      );
    });
  });

  group('role reveal', () {
    test('night falls once everyone confirmed', () {
      var state = apply(lobby(5), StartGame(random: Random(3))).state;
      expect(state.phase, Phase.roleReveal);
      for (var i = 0; i < 4; i++) {
        state = apply(state, ConfirmRole(id(i))).state;
      }
      expect(state.phase, Phase.roleReveal);
      final update = apply(state, ConfirmRole(id(4)));
      expect(update.state.phase, Phase.night);
      expect(update.state.round, 1);
      expect(update.events.single, isA<NightFell>());
    });

    test('an absent player cannot hold up the first night', () {
      var state = apply(lobby(5), StartGame(random: Random(3))).state;
      state = apply(state, ConfirmRole(id(0))).state;
      final update = apply(state, const PhaseTimeout());
      expect(update.state.phase, Phase.night);
      expect(update.state.round, 1);
      expect(update.events.single, isA<NightFell>());
    });
  });

  group('night', () {
    const roles = [
      Role.werewolf,
      Role.werewolf,
      Role.seer,
      Role.villager,
      Role.villager,
      Role.villager,
      Role.villager,
      Role.villager,
    ];

    test('night ends when every living player acted', () {
      final state = night(roles);
      final update = playNight(state, {0: 3, 1: 3, 2: 0});
      expect(update.state.phase, Phase.day);
      expect(update.state.player(id(3))!.isAlive, isFalse);
      expect(update.events.whereType<PlayerKilled>().single.player, id(3));
      expect(update.state.nightChoices, isEmpty);
    });

    test('a werewolf tie kills nobody', () {
      final update = playNight(night(roles), {0: 3, 1: 4, 2: 0});
      expect(update.state.alive, hasLength(8));
      expect(update.events.whereType<NobodyDied>(), hasLength(1));
    });

    test('werewolves can change their pick until the night ends', () {
      var state = night(roles);
      state = apply(state, WerewolfVote(id(0), id(4))).state;
      state = apply(state, WerewolfVote(id(0), id(3))).state;
      expect(state.nightChoices[id(0)], [id(3)]);
    });

    test('invalid night actions are refused and change nothing', () {
      final state = night(roles);
      final cases = <GameAction, Violation>{
        WerewolfVote(id(0), id(1)): Violation.invalidTarget,
        WerewolfVote(id(0), id(0)): Violation.invalidTarget,
        WerewolfVote(id(2), id(3)): Violation.notYourAction,
        SeerInspect(id(3), id(0)): Violation.notYourAction,
        SeerInspect(id(2), id(2)): Violation.invalidTarget,
        NightDecoy(id(0), id(3)): Violation.notYourAction,
        WerewolfVote(id(0), const PlayerId('nobody')): Violation.unknownPlayer,
        const CastVote(PlayerId('p3'), null): Violation.wrongPhase,
        const EndDiscussion(): Violation.wrongPhase,
      };
      for (final MapEntry(:key, :value) in cases.entries) {
        expect(() => apply(state, key), refuses(value), reason: '$key');
      }
    });

    test('the seer looks once per night and only she learns it', () {
      var state = night(roles);
      final update = apply(state, SeerInspect(id(2), id(0)));
      state = update.state;
      final seen = update.events.whereType<SeerSaw>().single;
      expect(seen.result.role, Role.werewolf);
      expect(seen.audience.includes(id(2)), isTrue);
      expect(seen.audience.includes(id(0)), isFalse);
      expect(
        () => apply(state, SeerInspect(id(2), id(1))),
        refuses(Violation.alreadyActed),
      );
      expect(viewFor(state, id(2)).seerResults.single.target, id(0));
    });

    test('with seerSeesRole off the seer only learns the faction', () {
      final state = night(
        roles,
        settings: const GameSettings(seerSeesRole: false),
      );
      final seen = apply(
        state,
        SeerInspect(id(2), id(0)),
      ).events.whereType<SeerSaw>().single;
      expect(seen.result.role, isNull);
      expect(seen.result.faction, Faction.werewolves);
    });

    test('the dead cannot act or be picked', () {
      final day = playNight(night(roles), {0: 3, 1: 3, 2: 0}).state;
      final next = playVote(day, {
        for (final p in day.alive) int.parse(p.id.value.substring(1)): null,
      }).state;
      expect(next.phase, Phase.night);
      expect(
        () => apply(next, NightDecoy(id(3), id(4))),
        refuses(Violation.playerDead),
      );
      expect(
        () => apply(next, WerewolfVote(id(0), id(3))),
        refuses(Violation.invalidTarget),
      );
    });

    test('a timeout resolves the night with what was picked', () {
      var state = night(roles);
      state = apply(state, WerewolfVote(id(0), id(5))).state;
      final update = apply(state, const PhaseTimeout());
      expect(update.state.phase, Phase.day);
      expect(update.state.player(id(5))!.isAlive, isFalse);
    });
  });

  group('counting sheep', () {
    const roles = [
      Role.werewolf,
      Role.seer,
      Role.villager,
      Role.villager,
      Role.villager,
    ];

    test('sheep stay secret at night and are told in the morning', () {
      var state = night(roles);
      state = apply(state, CountSheep(id(2), 1)).state;
      state = apply(state, CountSheep(id(2), 3)).state;
      state = apply(state, CountSheep(id(3), -2)).state;
      expect(viewFor(state, id(4)).lastNightSheep, isEmpty);
      state = playNight(state, {0: 4, 1: 0}).state;
      final view = viewFor(state, id(0));
      expect(view.lastNightSheep[id(2)], 3);
      expect(view.lastNightSheep[id(3)], -2);
      expect(view.lastNightSheep[id(0)], 0);
      // The victim counted too before the wolves came.
      expect(view.lastNightSheep[id(4)], 0);
      expect(view.dreams[id(2)], 3);
      expect(publicView(state).dreams[id(2)], 3);
    });

    test('dream points add up over the nights', () {
      var state = night(roles);
      state = apply(state, CountSheep(id(2), 3)).state;
      state = playNight(state, {0: 4, 1: 0}).state;
      state = playVote(state, {0: null, 1: null, 2: null, 3: null}).state;
      state = apply(state, CountSheep(id(2), 2)).state;
      state = playNight(state, {0: 3, 1: 0}).state;
      expect(state.dreams[id(2)], 5);
      expect(state.lastNightSheep[id(2)], 2);
    });

    test('flocks differ between players and nights, and cap the count', () {
      final state = night(roles);
      final flocks = {for (final p in state.players) flockFor(state, p.id)};
      expect(flocks.every((f) => f >= minFlock && f <= maxFlock), isTrue);
      final many = apply(lobby(8), StartGame(random: Random(3))).state;
      final sizes = <int>{
        for (var r = 1; r < 6; r++)
          for (final p in many.players) flockFor(many.copyWith(round: r), p.id),
      };
      expect(sizes.length, greaterThan(5));
      final flock = flockFor(state, id(2));
      expect(viewFor(state, id(2)).yourFlock, flock);
      expect(
        () => apply(state, CountSheep(id(2), flock + 1)),
        refuses(Violation.outOfRange),
      );
    });

    test('counting is only for the living, at night, within limits', () {
      final state = night(roles);
      expect(
        () => apply(state, CountSheep(id(2), maxSheepPerNight + 1)),
        refuses(Violation.outOfRange),
      );
      final day = playNight(state, {0: 4, 1: 0}).state;
      expect(
        () => apply(day, CountSheep(id(2), 1)),
        refuses(Violation.wrongPhase),
      );
    });
  });

  group('vote', () {
    const roles = [
      Role.werewolf,
      Role.seer,
      Role.villager,
      Role.villager,
      Role.villager,
    ];

    test('a tie eliminates nobody, abstentions do not count', () {
      final day = playNight(night(roles), {0: 4, 1: 0}).state;
      final update = playVote(day, {0: 2, 1: 0, 2: null, 3: 2});
      // 0 and 3 vote 2, 1 votes 0 → 2 is out.
      expect(update.state.player(id(2))!.isAlive, isFalse);

      final tie = playVote(day, {0: 2, 1: 0, 2: 0, 3: 2});
      expect(tie.state.alive, hasLength(4));
      expect(tie.events.whereType<NobodyEliminated>().single.tie, isTrue);
      expect(tie.state.phase, Phase.night);
      expect(tie.state.round, 2);
    });

    test('votes can change until everyone voted; self votes are refused', () {
      final day = playNight(night(roles), {0: 4, 1: 0}).state;
      var state = apply(day, const EndDiscussion()).state;
      state = apply(state, CastVote(id(0), id(2))).state;
      state = apply(state, CastVote(id(0), id(3))).state;
      expect(state.votes[id(0)], id(3));
      expect(
        () => apply(state, CastVote(id(1), id(1))),
        refuses(Violation.invalidTarget),
      );
      expect(
        () => apply(state, CastVote(id(4), id(1))),
        refuses(Violation.playerDead),
      );
    });

    test('a timeout resolves the vote with the votes so far', () {
      final day = playNight(night(roles), {0: 4, 1: 0}).state;
      var state = apply(day, const EndDiscussion()).state;
      state = apply(state, CastVote(id(1), id(0))).state;
      final update = apply(state, const PhaseTimeout());
      expect(update.state.phase, Phase.ended);
      expect(update.state.winner, Faction.village);
    });

    test('a day timeout starts the vote', () {
      final day = playNight(night(roles), {0: 4, 1: 0}).state;
      expect(apply(day, const PhaseTimeout()).state.phase, Phase.vote);
      expect(
        () => apply(lobby(3), const PhaseTimeout()),
        refuses(Violation.wrongPhase),
      );
    });
  });

  group('whole games', () {
    test('the village finds the werewolf', () {
      var state = apply(lobby(5), StartGame(random: Random(7))).state;
      for (var i = 0; i < 5; i++) {
        state = apply(state, ConfirmRole(id(i))).state;
      }
      final wolf = state.players.firstWhere((p) => p.role == Role.werewolf);
      final villager = state.players.firstWhere(
        (p) => p.role == Role.villager,
      );
      // Night 1: the werewolf takes a villager; everyone else picks the wolf.
      for (final p in state.alive) {
        final target = p.id == wolf.id ? villager.id : wolf.id;
        state = apply(state, nightAction(state, p.id, [target])).state;
      }
      expect(state.phase, Phase.day);
      expect(state.deaths.single.player, villager.id);
      // Day 1: everyone but the wolf votes for the wolf.
      state = apply(state, const EndDiscussion()).state;
      for (final p in state.alive) {
        final target = p.id == wolf.id ? state.alive.first.id : wolf.id;
        state = apply(
          state,
          CastVote(p.id, target == p.id ? state.alive.last.id : target),
        ).state;
      }
      expect(state.phase, Phase.ended);
      expect(state.winner, Faction.village);
      expect(
        viewFor(state, villager.id).seats.every((s) => s.role != null),
        isTrue,
      );
    });

    test('the werewolves take over the village', () {
      const roles = [
        Role.werewolf,
        Role.seer,
        Role.villager,
        Role.villager,
        Role.villager,
      ];
      var state = night(roles);
      // Night 1: the seer dies.
      var update = playNight(state, {0: 1, 1: 0});
      expect(update.events.whereType<PlayerKilled>().single.role, Role.seer);
      // Day 1: the village votes out a villager.
      update = playVote(update.state, {0: 2, 2: 3, 3: 2, 4: 2});
      expect(update.events.whereType<PlayerEliminated>().single.player, id(2));
      state = update.state;
      expect(state.phase, Phase.night);
      // Night 2: one more villager; one wolf against one villager is a win.
      update = playNight(state, {0: 3});
      expect(update.state.phase, Phase.ended);
      expect(update.state.winner, Faction.werewolves);
      expect(update.events.last, isA<GameEnded>());
    });
  });

  group('views leak nothing', () {
    const roles = [
      Role.werewolf,
      Role.werewolf,
      Role.seer,
      Role.villager,
      Role.villager,
      Role.villager,
      Role.villager,
      Role.villager,
    ];

    test('for every player in every phase', () {
      var state = night(roles);
      expectNoLeaks(state);
      state = apply(state, WerewolfVote(id(0), id(3))).state;
      state = apply(state, SeerInspect(id(2), id(1))).state;
      state = apply(state, NightDecoy(id(4), id(5))).state;
      expectNoLeaks(state);
      final wolfView = viewFor(state, id(1));
      expect(wolfView.packChoices, {id(0): id(3)});
      expect(
        wolfView.seats.firstWhere((s) => s.id == id(0)).role,
        Role.werewolf,
      );
      state = playNight(state, {0: 3, 1: 3}).state;
      expectNoLeaks(state);
      state = apply(state, const EndDiscussion()).state;
      state = apply(state, CastVote(id(4), id(0))).state;
      expectNoLeaks(state);
    });

    test('hidden roles stay hidden when revealRoleOnDeath is off', () {
      var state = night(
        roles,
        settings: const GameSettings(revealRoleOnDeath: false),
      );
      final update = playNight(state, {0: 3, 1: 3, 2: 0});
      expect(update.events.whereType<PlayerKilled>().single.role, isNull);
      state = update.state;
      expectNoLeaks(state);
      expect(viewFor(state, id(4)).deaths.single.role, isNull);
    });
  });
}
