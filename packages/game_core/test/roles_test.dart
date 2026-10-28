import 'dart:math';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('witch', () {
    // p0 wolf, p1 seer, p2 witch, p3–p5 villagers.
    const roles = [
      Role.werewolf,
      Role.seer,
      Role.witch,
      Role.villager,
      Role.villager,
      Role.villager,
    ];

    /// Plays the werewolves' step: everyone else picks the first other
    /// living player, then p0 takes [victim] (or the time runs out).
    GameState hunt(GameState state, int? victim) {
      var next = state;
      for (final p in state.alive.skip(1)) {
        final other = state.alive.firstWhere((o) => o.id != p.id).id;
        next = apply(next, nightAction(next, p.id, [other])).state;
      }
      return huntOver(
        apply(
          next,
          victim == null
              ? const PhaseTimeout()
              : WerewolfVote(id(0), id(victim)),
        ).state,
      );
    }

    test('she decides after the werewolves, and only she sees the victim', () {
      final state = hunt(night(roles), 3);
      expect(state.phase, Phase.night);
      expect(state.nightStep, NightStep.brew);
      expect(state.player(id(3))!.isAlive, isTrue);
      final witch = viewFor(state, id(2));
      expect(witch.victim, id(3));
      expect(witch.yourNightTask, NightAbility.brew);
      expect(witch.potions, {Potion.heal, Potion.poison});
      // Everyone acts again, so the witch's step looks like any other.
      expect(witch.waitingFor, 6);
      for (final i in [0, 1, 3, 4, 5]) {
        expect(viewFor(state, id(i)).victim, isNull);
        expect(viewFor(state, id(i)).yourNightTask, NightAbility.decoy);
      }
      expectNoLeaks(state);
    });

    test('the healing potion saves the victim, once per game', () {
      final update = playNight(night(roles), {0: 3}, brew: [3]);
      expect(update.state.phase, Phase.day);
      expect(update.state.alive, hasLength(6));
      expect(update.events.whereType<NobodyDied>(), hasLength(1));
      expect(viewFor(update.state, id(2)).potions, {Potion.poison});

      final next = voteOut(update.state, 5).state;
      final brewing = hunt(next, 4);
      expect(
        () => apply(brewing, nightAction(brewing, id(2), [id(4)])),
        refuses(Violation.alreadyActed),
      );
    });

    test('the poison kills; the morning does not tell how', () {
      final update = playNight(night(roles), {0: 3}, brew: [4]);
      expect(update.state.phase, Phase.day);
      expect(
        update.events.whereType<PlayerKilled>().map((e) => e.player),
        [id(3), id(4)],
      );
      expect(
        update.state.deaths.map((d) => d.cause),
        everyElement(DeathCause.night),
      );
      expect(viewFor(update.state, id(2)).potions, {Potion.heal});
    });

    test('she can heal and poison in the same night', () {
      final update = playNight(night(roles), {0: 3}, brew: [3, 0]);
      expect(update.state.phase, Phase.ended);
      expect(update.state.winner, Faction.village);
      expect(update.state.deaths.single.player, id(0));
      expect(update.state.potionsUsed, Potion.values.toSet());
    });

    test('she may heal herself', () {
      final update = playNight(night(roles), {0: 2}, brew: [2]);
      expect(update.state.player(id(2))!.isAlive, isTrue);
    });

    test('wrong potions are refused', () {
      final state = hunt(night(roles), 3);
      final cases = <GameAction, Violation>{
        WitchBrew(id(2), poison: id(2)): Violation.invalidTarget,
        WitchBrew(id(2), poison: id(3)): Violation.invalidTarget,
        WitchBrew(id(2), poison: const PlayerId('nobody')):
            Violation.unknownPlayer,
        NightDecoy(id(2), id(3)): Violation.notYourAction,
        WitchBrew(id(1), heal: true): Violation.notYourAction,
        WerewolfVote(id(0), id(4)): Violation.notYourAction,
      };
      for (final MapEntry(:key, :value) in cases.entries) {
        expect(() => apply(state, key), refuses(value), reason: '$key');
      }
      expect(
        () => nightAction(state, id(2), [id(4), id(5)]),
        refuses(Violation.invalidTarget),
      );
      final acted = apply(state, WitchBrew(id(2), poison: id(4))).state;
      expect(
        () => apply(acted, WitchBrew(id(2), heal: true)),
        refuses(Violation.alreadyActed),
      );
      // Before the werewolves are done, she has a decoy task like anyone.
      final early = night(roles);
      expect(nightTask(early, id(2)), NightAbility.decoy);
      expect(
        () => apply(early, WitchBrew(id(2), poison: id(4))),
        refuses(Violation.notYourAction),
      );
    });

    test('without a victim there is nothing to heal', () {
      final state = hunt(night(roles), null);
      expect(state.nightStep, NightStep.brew);
      expect(viewFor(state, id(2)).victim, isNull);
      expect(
        () => apply(state, WitchBrew(id(2), heal: true)),
        refuses(Violation.invalidTarget),
      );
    });

    test('a timeout in her step lets the night take its course', () {
      final state = hunt(night(roles), 3);
      final update = apply(state, const PhaseTimeout());
      expect(update.state.phase, Phase.day);
      expect(update.state.player(id(3))!.isAlive, isFalse);
      expect(update.state.potionsUsed, isEmpty);
    });

    test('her step stays after her death, so nights keep their course', () {
      final day = playNight(night(roles), {0: 2}).state;
      expect(day.player(id(2))!.isAlive, isFalse);
      final next = voteOut(day, 5).state;
      final state = hunt(next, 3);
      expect(state.nightStep, NightStep.brew);
      expect(viewFor(state, id(2)).potions, isEmpty);
    });

    test('games without a witch have no second step', () {
      final state = apply(
        night(const [Role.werewolf, Role.seer, Role.villager, Role.villager]),
        WerewolfVote(id(0), id(2)),
      ).state;
      final update = playNight(state, const {});
      expect(update.events.whereType<BrewStepBegan>(), isEmpty);
      expect(update.state.phase, Phase.day);
    });
  });

  group('hunter', () {
    // p0, p1 wolves, p2 hunter, p3 seer, p4–p6 villagers.
    const roles = [
      Role.werewolf,
      Role.werewolf,
      Role.hunter,
      Role.seer,
      Role.villager,
      Role.villager,
      Role.villager,
    ];

    test('killed at night, he takes someone along before the day', () {
      final update = playNight(night(roles), {0: 2, 1: 2});
      var state = update.state;
      expect(state.phase, Phase.hunterShot);
      expect(update.events.last, isA<HunterAims>());
      final view = viewFor(state, id(4));
      expect(view.shooter, id(2));
      expect(view.waitingFor, 1);
      expect(publicView(state).shooter, id(2));
      expect(timeLimit(state), shotTime);
      expectNoLeaks(state);

      expect(
        () => apply(state, HunterShoot(id(3), id(0))),
        refuses(Violation.notYourAction),
      );
      expect(
        () => apply(state, HunterShoot(id(2), id(2))),
        refuses(Violation.invalidTarget),
      );
      final shot = apply(state, HunterShoot(id(2), id(0)));
      state = shot.state;
      expect(state.phase, Phase.day);
      expect(state.round, 1);
      expect(state.shooter, isNull);
      expect(shot.events.whereType<PlayerShot>().single.player, id(0));
      expect(state.deaths.last.cause, DeathCause.shot);
      expect(shot.events.last, isA<DayBroke>());
    });

    test('voted out, he shoots and the next night falls', () {
      final day = playNight(night(roles), {0: 4, 1: 4}).state;
      final voted = voteOut(day, 2).state;
      expect(voted.phase, Phase.hunterShot);
      expect(voted.afterShot, Phase.night);
      final next = apply(voted, HunterShoot(id(2), id(0))).state;
      expect(next.phase, Phase.night);
      expect(next.round, 2);
      expect(next.player(id(0))!.isAlive, isFalse);
    });

    test('he may spare everyone, and his time can run out', () {
      final state = playNight(night(roles), {0: 2, 1: 2}).state;
      final spared = apply(state, HunterShoot(id(2), null));
      expect(spared.events.first, isA<HunterSpared>());
      expect(spared.state.phase, Phase.day);
      final late = apply(state, const PhaseTimeout());
      expect(late.state.phase, Phase.day);
      expect(late.state.alive, hasLength(6));
    });

    test('his shot comes before the win is decided', () {
      // p0 wolf, p1 hunter, p2, p3 villagers.
      var state = night(const [
        Role.werewolf,
        Role.hunter,
        Role.villager,
        Role.villager,
      ]);
      state = playNight(state, {0: 2}).state;
      // Wolf and villager would be even, but the hunter takes the wolf.
      state = playVote(state, {0: 1, 1: 0, 3: 1}).state;
      expect(state.phase, Phase.hunterShot);
      final update = apply(state, HunterShoot(id(1), id(0)));
      expect(update.state.phase, Phase.ended);
      expect(update.state.winner, Faction.village);
    });
  });

  group('cupid', () {
    // p0 wolf, p1 cupid, p2 seer, p3–p5 villagers.
    const roles = [
      Role.werewolf,
      Role.cupid,
      Role.seer,
      Role.villager,
      Role.villager,
      Role.villager,
    ];

    test('links two lovers in the first night; only they and cupid know', () {
      var state = night(roles);
      expect(nightTask(state, id(1)), NightAbility.link);
      expect(
        () => apply(state, NightDecoy(id(1), id(3))),
        refuses(Violation.notYourAction),
      );
      expect(
        () => apply(state, CupidLink(id(1), id(3), id(3))),
        refuses(Violation.invalidTarget),
      );
      expect(
        () => nightAction(state, id(1), [id(3)]),
        refuses(Violation.invalidTarget),
      );
      state = apply(state, CupidLink(id(1), id(3), id(4))).state;
      expect(
        () => apply(state, CupidLink(id(1), id(4), id(5))),
        refuses(Violation.alreadyActed),
      );
      expect(state.lovers, isEmpty, reason: 'linked when the step ends');
      final update = playNight(state, {0: 5});
      state = update.state;
      final linked = update.events.whereType<LoversLinked>().single;
      expect(linked.audience.includes(id(3)), isTrue);
      expect(linked.audience.includes(id(1)), isTrue);
      expect(linked.audience.includes(id(0)), isFalse);
      expect(state.lovers, [id(3), id(4)]);
      expect(viewFor(state, id(3)).partner, id(4));
      expect(viewFor(state, id(4)).partner, id(3));
      expect(viewFor(state, id(1)).couple, [id(3), id(4)]);
      expect(viewFor(state, id(1)).partner, isNull);
      expect(viewFor(state, id(2)).couple, isEmpty);
      expectNoLeaks(state);

      // From the second night on, cupid has a decoy task.
      state = voteOut(state, 2).state;
      expect(nightTask(state, id(1)), NightAbility.decoy);
    });

    test('cupid may link himself', () {
      final state = playNight(night(roles), {0: 5}, link: [1, 3]).state;
      expect(viewFor(state, id(1)).partner, id(3));
    });

    test('when one lover dies, the other dies of grief', () {
      final update = playNight(night(roles), {0: 3}, link: [3, 4]);
      expect(update.state.player(id(4))!.isAlive, isFalse);
      expect(update.events.whereType<LoverDied>().single.player, id(4));
      expect(update.state.deaths.last.cause, DeathCause.heartbreak);

      final voted = voteOut(
        playNight(night(roles), {0: 5}, link: [3, 4]).state,
        4,
      );
      expect(voted.state.player(id(3))!.isAlive, isFalse);
      expect(voted.state.deaths.last.cause, DeathCause.heartbreak);
    });

    test('a mixed couple wins when they are the last two', () {
      // p0 wolf and p3 villager in love.
      var state = playNight(night(roles), {0: 5}, link: [0, 3]).state;
      expect(state.phase, Phase.day);
      state = voteOut(state, 4).state;
      state = playNight(state, {0: 2}).state;
      expect(state.alive.map((p) => p.id), [id(0), id(1), id(3)]);
      // Village cannot win while the wolf lover lives; the wolf alone does
      // not count as a pack against the other two.
      expect(state.phase, Phase.day);
      final update = voteOut(state, 1);
      expect(update.state.phase, Phase.ended);
      expect(update.state.winner, Faction.lovers);
      expect(viewFor(update.state, id(4)).couple, [id(0), id(3)]);
    });

    test('a same-side couple plays for its side', () {
      var state = playNight(night(roles), {0: 5}, link: [3, 4]).state;
      state = voteOut(state, 0).state;
      expect(state.winner, Faction.village);
    });
  });

  group('death chains', () {
    // p0, p1 wolves, p2 hunter, p3 cupid, p4 witch, p5–p7 villagers.
    const roles = [
      Role.werewolf,
      Role.werewolf,
      Role.hunter,
      Role.cupid,
      Role.witch,
      Role.villager,
      Role.villager,
      Role.villager,
    ];

    test('a hunter in love dies of grief and still shoots', () {
      final update = playNight(night(roles), {0: 5, 1: 5}, link: [2, 5]);
      final state = update.state;
      expect(state.phase, Phase.hunterShot);
      expect(state.shooter, id(2));
      expect(state.deaths.map((d) => d.cause), [
        DeathCause.night,
        DeathCause.heartbreak,
      ]);
      final after = apply(state, HunterShoot(id(2), id(0))).state;
      expect(after.phase, Phase.day);
      expect(after.alive, hasLength(5));
    });

    test('the hunter shooting a lover takes the partner too', () {
      var state = playNight(night(roles), {0: 2, 1: 2}, link: [6, 7]).state;
      expect(state.phase, Phase.hunterShot);
      state = apply(state, HunterShoot(id(2), id(6))).state;
      expect(state.player(id(7))!.isAlive, isFalse);
      expect(
        state.deaths.map((d) => d.cause),
        [DeathCause.night, DeathCause.shot, DeathCause.heartbreak],
      );
      expect(state.phase, Phase.day);
    });

    test('the poisoned lover takes the partner and the night goes on', () {
      final update = playNight(
        night(roles),
        {0: 5, 1: 5},
        link: [6, 7],
        brew: [5, 6],
      );
      expect(update.state.player(id(5))!.isAlive, isTrue);
      expect(update.state.alive.map((p) => p.id), isNot(contains(id(7))));
      expect(update.state.phase, Phase.day);
    });
  });

  group('whole games with every role', () {
    test('random games always end and never leak', () {
      for (var seed = 0; seed < 300; seed++) {
        final random = Random(seed);
        final count = 5 + random.nextInt(4);
        var state = lobby(count, settings: Preset.fullStage.settings);
        state = apply(state, StartGame(random: random)).state;
        for (final p in state.players) {
          state = apply(state, ConfirmRole(p.id)).state;
        }
        var steps = 0;
        while (state.phase != Phase.ended) {
          expect(++steps, lessThan(500), reason: 'seed $seed hangs');
          expectNoLeaks(state);
          state = _randomMove(state, random);
        }
        expectNoLeaks(state);
        if (state.winner == Faction.lovers) {
          expect(state.alive.map((p) => p.id).toSet(), state.lovers.toSet());
        }
      }
    });
  });
}

/// [player] tries a door sign (refused unless a werewolf in the hunt with
/// the pack's attempt still free): mostly a guess, sometimes the right sign.
GameState _randomMark(GameState state, Player player, Random random) {
  final prey = [
    for (final o in state.alive)
      if (o.role != Role.werewolf) o.id,
  ];
  final target = prey[random.nextInt(prey.length)];
  final sign = random.nextBool()
      ? doorSignFor(state, target)
      : [
          for (var i = 0; i < doorSignLength; i++)
            random.nextInt(doorSignSymbols),
        ];
  try {
    return apply(state, MarkDoor(player.id, target, sign)).state;
  } on RuleViolation {
    return state;
  }
}

/// One random legal move (or a timeout) in [state].
GameState _randomMove(GameState state, Random random) {
  T pick<T>(List<T> list) => list[random.nextInt(list.length)];
  if (random.nextInt(12) == 0) return apply(state, const PhaseTimeout()).state;
  final alive = state.alive.toList();
  switch (state.phase) {
    case Phase.night:
      final p = pick(alive);
      if (random.nextInt(4) == 0) return _randomMark(state, p, random);
      final others = [
        for (final o in alive)
          if (o.id != p.id) o.id,
      ];
      final poisonable = [
        for (final o in others)
          if (o != state.nightVictim) o,
      ];
      final targets = switch (nightTask(state, p.id)!) {
        NightAbility.hunt => [
          pick([
            for (final o in alive)
              if (o.role != Role.werewolf) o.id,
          ]),
        ],
        NightAbility.link => (others..shuffle(random)).take(2).toList(),
        NightAbility.brew => [
          if (state.nightVictim != null &&
              !state.potionsUsed.contains(Potion.heal) &&
              random.nextBool())
            state.nightVictim!,
          if (!state.potionsUsed.contains(Potion.poison) &&
              poisonable.isNotEmpty &&
              random.nextInt(3) == 0)
            pick(poisonable),
        ],
        _ => [pick(others)],
      };
      try {
        return apply(state, nightAction(state, p.id, targets)).state;
      } on RuleViolation {
        // Seer or cupid acting twice; try another move.
        return state;
      }
    case Phase.day:
      return apply(state, const EndDiscussion()).state;
    case Phase.vote:
      final voter = pick(alive);
      final others = [
        for (final o in alive)
          if (o.id != voter.id &&
              (state.runoff.isEmpty || state.runoff.contains(o.id)))
            o.id,
      ];
      return apply(
        state,
        CastVote(voter.id, random.nextInt(5) == 0 ? null : pick(others)),
      ).state;
    case Phase.hunterShot:
      return apply(
        state,
        HunterShoot(state.shooter!, random.nextBool() ? pick(alive).id : null),
      ).state;
    case Phase.lobby || Phase.roleReveal || Phase.ended:
      throw StateError('unexpected ${state.phase}');
  }
}
