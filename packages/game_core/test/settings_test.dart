import 'dart:math';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('fitted to the table', () {
    test('too many roles for three: the last ones stay out, the wish '
        'stays', () {
      const wish = GameSettings(
        roles: {Role.seer, Role.witch, Role.hunter, Role.cupid},
      );
      expect(wish.rolesFor(3), isNull);
      final fitted = wish.fittedFor(3);
      expect(fitted.rolesFor(3), isNotNull);
      expect(fitted.roles, {Role.seer, Role.witch});
      expect(wish.droppedFor(3), {Role.hunter, Role.cupid});
      // With more players everything fits again.
      expect(wish.fittedFor(8), wish);
      expect(wish.droppedFor(8), isEmpty);
    });

    test('too many werewolves fall back to the suggested number', () {
      const wish = GameSettings(werewolves: 3);
      final fitted = wish.fittedFor(4);
      expect(fitted.werewolves, isNull);
      expect(fitted.rolesFor(4), isNotNull);
    });

    test('a game of three starts with every role switched on', () {
      final state = apply(
        lobby(
          3,
          settings: const GameSettings(
            roles: {Role.seer, Role.witch, Role.hunter, Role.cupid},
          ),
        ),
        StartGame(random: Random(1)),
      ).state;
      expect(state.phase, Phase.roleReveal);
      final dealt = state.players.map((p) => p.role).toSet();
      expect(dealt, isNot(contains(Role.cupid)));
      expect(dealt, isNot(contains(Role.hunter)));
    });
  });

  test('times suited to the table stay within the ranges and grow with '
      'it', () {
    for (var n = minPlayers; n <= maxPlayers; n++) {
      const GameSettings().timedFor(n).validate();
    }
    expect(
      const GameSettings().timedFor(4).dayTime,
      lessThan(const GameSettings().timedFor(14).dayTime),
    );
  });

  group('presets', () {
    test('each preset is recognised, a change makes it custom', () {
      for (final preset in Preset.values) {
        expect(preset.settings.preset, preset);
        expect(
          preset.settings.copyWith(narratorMode: NarratorMode.always).preset,
          isNull,
        );
        // Where sound plays is the table's choice, not part of a preset.
        expect(
          preset.settings
              .copyWith(
                soundMode: SoundMode.chosen,
                soundSeats: {const PlayerId('p1')},
              )
              .preset,
          preset,
        );
        preset.settings.validate();
      }
      expect(const GameSettings().preset, isNull);
      expect(
        const GameSettings().narratorMode,
        NarratorMode.moments,
        reason: 'the narrator tells the big moments unless switched off',
      );
      expect(
        Preset.classic.settings
            .copyWith(
              sheepCounting: true,
              atmosphere: true,
              doorSigns: true,
              nightMode: NightMode.together,
            )
            .preset,
        Preset.whowolf,
      );
    });

    test('they grow from classic to the full stage', () {
      final classic = Preset.classic.settings;
      final whowolf = Preset.whowolf.settings;
      final full = Preset.fullStage.settings;
      expect(classic.sheepCounting || classic.atmosphere, isFalse);
      expect(classic.wolfTrail, isFalse);
      expect(whowolf.sheepCounting && whowolf.atmosphere, isTrue);
      expect(const GameSettings().doorSigns || classic.doorSigns, isFalse);
      expect(whowolf.doorSigns && full.doorSigns, isTrue);
      expect(full.roles, specialRoles);
      expect(full.wolfTrail, isTrue);
    });
  });

  group('changing settings', () {
    test('only in the lobby, and everyone sees them', () {
      final state = apply(
        lobby(5),
        ChangeSettings(Preset.fullStage.settings),
      ).state;
      expect(viewFor(state, id(3)).settings, Preset.fullStage.settings);
      expect(publicView(state).settings.preset, Preset.fullStage);
      final started = apply(state, StartGame(random: Random(1))).state;
      expect(
        () => apply(started, const ChangeSettings(GameSettings())),
        refuses(Violation.wrongPhase),
      );
    });

    test('values out of bounds are refused', () {
      const base = GameSettings();
      final cases = <GameSettings, Violation>{
        base.copyWith(nightTime: const Duration(seconds: 29)):
            Violation.outOfRange,
        base.copyWith(nightTime: const Duration(minutes: 6)):
            Violation.outOfRange,
        base.copyWith(dayTime: const Duration(seconds: 59)):
            Violation.outOfRange,
        base.copyWith(dayTime: const Duration(minutes: 31)):
            Violation.outOfRange,
        base.copyWith(voteTime: Duration.zero): Violation.outOfRange,
        base.copyWith(werewolves: 0): Violation.invalidRoles,
        base.copyWith(werewolves: maxWerewolves + 1): Violation.invalidRoles,
        base.copyWith(roles: {Role.werewolf}): Violation.invalidRoles,
        base.copyWith(roles: {Role.villager}): Violation.invalidRoles,
      };
      for (final MapEntry(:key, :value) in cases.entries) {
        expect(
          () => apply(lobby(3), ChangeSettings(key)),
          refuses(value),
          reason: '$value',
        );
      }
    });
  });

  group('roles from the settings', () {
    test('the werewolves follow the player count unless set', () {
      const settings = GameSettings(roles: {Role.seer, Role.witch});
      for (var n = minPlayers + 1; n <= maxPlayers; n++) {
        final roles = settings.rolesFor(n)!;
        expect(roles, hasLength(n));
        expect(
          roles.where((r) => r == Role.werewolf),
          hasLength(
            suggestedWerewolves(n),
          ),
        );
        expect(roles.where((r) => r == Role.witch), hasLength(1));
      }
      final three = settings.copyWith(werewolves: 3).rolesFor(8)!;
      expect(three.where((r) => r == Role.werewolf), hasLength(3));
      expect(settings.copyWith(werewolves: 3).rolesFor(6), isNull);
      expect(Preset.fullStage.settings.rolesFor(4), isNull);
    });

    test('the game deals them, fitted to the table; explicit roles that '
        'do not fit are refused', () {
      final state = apply(
        lobby(7, settings: Preset.fullStage.settings),
        StartGame(random: Random(4)),
      ).state;
      expect(
        state.players.map((p) => p.role).toSet(),
        {...specialRoles, Role.werewolf, Role.villager},
      );
      // Four players, every role asked for: the ones that do not fit stay
      // out instead of blocking the start.
      final four = apply(
        lobby(4, settings: Preset.fullStage.settings),
        StartGame(random: Random(4)),
      ).state;
      expect(four.players, hasLength(4));
      expect(
        four.players.where((p) => p.role == Role.werewolf),
        hasLength(1),
      );
      expect(
        () => apply(
          lobby(5),
          StartGame(
            random: Random(4),
            roles: const [
              Role.werewolf,
              Role.witch,
              Role.witch,
              Role.villager,
              Role.villager,
            ],
          ),
        ),
        refuses(Violation.invalidRoles),
      );
    });
  });

  group('switches', () {
    test('without sheep counting, nights still need a neutral pick', () {
      final settings = Preset.classic.settings.copyWith(
        nightMode: NightMode.together,
      );
      final state = night(const [
        Role.werewolf,
        Role.seer,
        Role.villager,
        Role.villager,
      ], settings: settings);
      expect(viewFor(state, id(2)).yourFlock, isNull);
      expect(viewFor(state, id(2)).yourNightTask, NightAbility.decoy);
      expect(
        () => apply(state, CountSheep(id(2), 1)),
        refuses(Violation.disabled),
      );
      final day = playNight(state, {0: 3});
      expect(day.state.phase, Phase.day);
      expect(day.state.lastNightSheep, isEmpty);
      expect(day.state.dreams, isEmpty);
    });

    test(
      'in the lobby everyone picks among the free figures, at any level',
      () {
        for (final preset in Preset.values) {
          final state = lobby(3, settings: preset.settings);
          final taken = state.players[1].persona;
          final free = Persona.values.firstWhere(
            (p) => !state.players.any((q) => q.persona == p),
          );
          final picked = apply(state, ChoosePersona(id(0), free)).state;
          expect(picked.players.first.persona, free);
          expect(
            () => apply(state, ChoosePersona(id(0), taken)),
            refuses(Violation.personaTaken),
          );
        }
      },
    );

    test('after a death the talk starts once the last words are over', () {
      const roles = [
        Role.werewolf,
        Role.villager,
        Role.villager,
        Role.villager,
      ];
      final day = playNight(night(roles), {0: 3}).state;
      expect(day.phase, Phase.day);
      expect(timeLimit(day), const GameSettings().dayTime + lastWordsTime);
      final quiet = apply(night(roles), const PhaseTimeout()).state;
      expect(quiet.phase, Phase.day);
      expect(timeLimit(quiet), const GameSettings().dayTime);
    });

    test("Whowolf's hunt never ends right on the last pick", () {
      const roles = [
        Role.werewolf,
        Role.villager,
        Role.villager,
        Role.villager,
      ];
      var state = night(roles);
      for (final p in state.alive) {
        final other = state.alive.firstWhere((o) => o.id != p.id).id;
        state = apply(state, nightAction(state, p.id, [other])).state;
      }
      expect(state.phase, Phase.night, reason: 'all picked, still night');
      expect(timeLimit(state), togetherHuntTime);
      expect(apply(state, const PhaseTimeout()).state.phase, Phase.day);
    });

    test('the times follow the table until the host sets them', () {
      var state = lobby(3, settings: const GameSettings().timedFor(0));
      expect(state.settings.dayTime, const GameSettings().timedFor(3).dayTime);
      for (var i = 3; i < 9; i++) {
        state = apply(state, AddPlayer(PlayerId('p$i'), 'N$i')).state;
      }
      expect(state.settings.dayTime, const GameSettings().timedFor(9).dayTime);
      final mine = state.settings.copyWith(
        dayTime: const Duration(minutes: 3),
      );
      state = apply(state, ChangeSettings(mine)).state;
      state = apply(state, const RemovePlayer(PlayerId('p8'))).state;
      expect(state.settings.dayTime, const Duration(minutes: 3));
      // A preset keeps the table's times.
      expect(Preset.classic.settings.withTableOf(mine).dayTime, mine.dayTime);
    });

    test('the phase times come from the settings', () {
      final settings = const GameSettings().copyWith(
        nightTime: const Duration(seconds: 45),
        dayTime: const Duration(minutes: 3),
        voteTime: const Duration(seconds: 50),
        roles: {Role.witch},
      );
      var state = night(const [
        Role.werewolf,
        Role.witch,
        Role.villager,
        Role.villager,
      ], settings: settings);
      expect(timeLimit(state), const Duration(seconds: 45));
      state = apply(state, const PhaseTimeout()).state;
      expect(state.nightStep, NightStep.brew);
      expect(timeLimit(state), brewTime);
      state = apply(state, const PhaseTimeout()).state;
      expect(timeLimit(state), const Duration(minutes: 3));
      state = apply(state, const EndDiscussion()).state;
      expect(timeLimit(state), const Duration(seconds: 50));
      expect(timeLimit(lobby(3)), isNull);
    });
  });
}
