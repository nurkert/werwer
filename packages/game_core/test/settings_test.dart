import 'dart:math';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('presets', () {
    test('each preset is recognised, a change makes it custom', () {
      for (final preset in Preset.values) {
        expect(preset.settings.preset, preset);
        expect(preset.settings.copyWith(narratorVoice: false).preset, isNull);
        preset.settings.validate();
      }
      expect(const GameSettings().preset, isNull);
      expect(
        Preset.classic.settings
            .copyWith(
              sheepCounting: true,
              atmosphere: true,
              personaChoice: true,
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

    test('the game deals them, or refuses when they do not fit', () {
      final state = apply(
        lobby(6, settings: Preset.fullStage.settings),
        StartGame(random: Random(4)),
      ).state;
      expect(
        state.players.map((p) => p.role).toSet(),
        {...specialRoles, Role.werewolf, Role.villager},
      );
      expect(
        () => apply(
          lobby(4, settings: Preset.fullStage.settings),
          StartGame(random: Random(4)),
        ),
        refuses(Violation.invalidRoles),
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
      final settings = Preset.classic.settings;
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

    test('without persona choice, personas stay as dealt', () {
      final state = lobby(3, settings: Preset.classic.settings);
      expect(
        () => apply(state, ChoosePersona(id(0), Persona.quietPaw)),
        refuses(Violation.disabled),
      );
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
