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
    ]) {
      expect(
        () => decodeState(JsonReader.decode(jsonEncode(bad), maxBytes: 4096)),
        throwsA(isA<ProtocolError>()),
      );
    }
  });
}
