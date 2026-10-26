import 'dart:convert';
import 'dart:math';

import 'package:game_core/game_core.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

void main() {
  test("a full table's state fits the host's padding size", () {
    // The encrypted channel pads every host message to 8192 bytes, so that
    // all views look alike; the biggest view must fit in it.
    var state = GameState.lobby(settings: Preset.fullStage.settings);
    for (var i = 0; i < maxPlayers; i++) {
      state = apply(
        state,
        AddPlayer(PlayerId('p$i'), 'Spielername ${i.toString().padLeft(2)}x'),
      ).state;
    }
    state = apply(state, StartGame(random: Random(1))).state;
    var biggest = 0;
    for (final p in state.players) {
      final message = StateMessage(
        version: 999999,
        view: viewFor(state, p.id),
        isOwner: true,
        phaseEndsInMs: 299999,
      ).encode();
      biggest = max(biggest, utf8.encode(message).length);
    }
    printOnFailure('biggest: $biggest');
    expect(biggest, lessThan(4000), reason: 'leave room for a late game');
  });
}
