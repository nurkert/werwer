import 'dart:convert';
import 'dart:math';

import 'package:game_core/game_core.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

String roundTrip(GameState state) {
  final json = jsonEncode(encodeState(state));
  final back = decodeState(JsonReader.decode(json, maxBytes: 1 << 20));
  return jsonEncode(encodeState(back));
}

void main() {
  test('a state in the middle of a game survives JSON and back', () {
    var state = GameState.lobby(
      settings: const GameSettings(seerSeesRole: false),
    );
    for (var i = 0; i < 6; i++) {
      state = apply(state, AddPlayer(PlayerId('p$i'), 'P$i')).state;
    }
    state = apply(state, StartGame(random: Random(8))).state;
    for (var i = 0; i < 6; i++) {
      state = apply(state, ConfirmRole(PlayerId('p$i'))).state;
    }
    final wolf = state.players.firstWhere((p) => p.role == Role.werewolf);
    final seer = state.players.firstWhere((p) => p.role == Role.seer);
    final victim = state.players.firstWhere((p) => p.role == Role.villager);
    state = apply(state, SeerInspect(seer.id, wolf.id)).state;
    state = apply(state, CountSheep(victim.id, 2)).state;
    state = apply(state, WerewolfVote(wolf.id, victim.id)).state;
    final mid = jsonEncode(encodeState(state));
    expect(roundTrip(state), mid);

    // Continue the restored game exactly like the original.
    final restored = decodeState(JsonReader.decode(mid, maxBytes: 1 << 20));
    final a = apply(state, const PhaseTimeout()).state;
    final b = apply(restored, const PhaseTimeout()).state;
    expect(jsonEncode(encodeState(b)), jsonEncode(encodeState(a)));
    expect(b.deaths.single.player, victim.id);
    expect(viewFor(b, seer.id).seerResults.single.role, isNull);
  });

  test('a state with every role survives JSON and back', () {
    var state = GameState.lobby(
      settings: Preset.fullStage.settings.copyWith(werewolves: 2),
    );
    for (var i = 0; i < 8; i++) {
      state = apply(state, AddPlayer(PlayerId('p$i'), 'P$i')).state;
    }
    state = apply(state, StartGame(random: Random(3))).state;
    for (final p in state.players) {
      state = apply(state, ConfirmRole(p.id)).state;
    }
    Player holder(Role role) => state.players.firstWhere((p) => p.role == role);
    final wolves = state.players.where((p) => p.role == Role.werewolf);
    final hunter = holder(Role.hunter);
    final villagers = state.players.where((p) => p.role == Role.villager);
    final cupid = holder(Role.cupid);
    // Night 1: cupid links two villagers, the wolves take the hunter.
    state = apply(
      state,
      CupidLink(cupid.id, villagers.first.id, villagers.last.id),
    ).state;
    for (final w in wolves) {
      state = apply(state, WerewolfVote(w.id, hunter.id)).state;
    }
    state = apply(state, const PhaseTimeout()).state;
    expect(state.nightStep, NightStep.brew);
    state = apply(
      state,
      WitchBrew(holder(Role.witch).id, poison: villagers.first.id),
    ).state;
    expect(
      jsonDecode(roundTrip(state)),
      jsonDecode(jsonEncode(encodeState(state))),
    );
    state = apply(state, const PhaseTimeout()).state;
    expect(state.phase, Phase.hunterShot);
    expect(state.lovers, hasLength(2));
    expect(state.potionsUsed, {Potion.poison});
    final json = jsonEncode(encodeState(state));
    expect(roundTrip(state), json);
    final restored = decodeState(JsonReader.decode(json, maxBytes: 1 << 20));
    expect(restored.shooter, hunter.id);
    expect(restored.afterShot, Phase.day);
    expect(restored.settings, state.settings);
  });

  test('broken state is refused', () {
    final good = encodeState(GameState.lobby());
    for (final bad in [
      {...good, 'phase': 'party'},
      {...good, 'round': -1},
      {
        ...good,
        'confirmed': [1],
      },
      {...good, 'players': 'x'},
      {
        ...good,
        'lovers': ['p1'],
      },
      {
        ...good,
        'potionsUsed': ['love'],
      },
      {...good, 'nightStep': 'dawn'},
      // The game's secret is 32 bytes or none, never a guessable stub.
      {
        ...good,
        'secret': base64Url.encode([1, 2, 3, 4]),
      },
      {...good, 'secret': '%%%'},
    ]) {
      expect(
        () => decodeState(JsonReader.decode(jsonEncode(bad), maxBytes: 4096)),
        throwsA(isA<ProtocolError>()),
      );
    }
  });
}
