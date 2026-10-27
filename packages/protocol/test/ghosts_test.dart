import 'dart:convert';
import 'dart:math';

import 'package:game_core/game_core.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

/// A full table late in the game, as busy as it gets: the first player is a
/// ghost who sees everything, everyone else voted and picked at night, and
/// the seer has looked at someone every night.
GameState _busy() {
  var state = GameState.lobby(settings: Preset.fullStage.settings);
  for (var i = 0; i < maxPlayers; i++) {
    state = apply(
      state,
      AddPlayer(PlayerId('p$i'), 'Spielername ${i.toString().padLeft(2)}x'),
    ).state;
  }
  state = apply(state, StartGame(random: Random(1))).state;
  final ids = [for (final p in state.players) p.id];
  final seer = state.players.firstWhere((p) => p.role == Role.seer).id;
  return state.copyWith(
    phase: Phase.vote,
    round: 30,
    players: [
      for (final p in state.players)
        p.id == ids.first ? p.copyWith(isAlive: false) : p,
    ],
    nightChoices: {
      for (final id in ids.skip(1)) id: [ids[1], ids[2]],
    },
    votes: {for (final id in ids.skip(1)) id: ids[2]},
    runoff: ids.take(maxPlayers ~/ 2).toList(),
    seerResults: {
      seer: [
        for (var round = 1; round <= 30; round++)
          SeerResult(
            target: ids[round % ids.length],
            round: round,
            faction: Faction.village,
            role: Role.villager,
          ),
      ],
    },
  );
}

void main() {
  test('a ghost view and a runoff survive JSON and back', () {
    final state = _busy();
    final view = viewFor(state, state.players.first.id);
    expect(view.yourGhostSight, GhostSight.everything);
    final json = jsonEncode(encodeView(view));
    final back = decodeView(JsonReader.decode(json, maxBytes: 1 << 20));
    expect(jsonEncode(encodeView(back)), json);
    expect(back.ghost!.votes, hasLength(maxPlayers - 1));
    expect(back.runoff, hasLength(maxPlayers ~/ 2));
  });

  test("the busiest ghost's view fits the host's padding size", () {
    final state = _busy();
    final message = StateMessage(
      version: 999999,
      view: viewFor(state, state.players.first.id),
      isOwner: true,
      phaseEndsInMs: 299999,
    ).encode();
    final size = utf8.encode(message).length;
    printOnFailure('size: $size');
    expect(size, lessThan(8192 - 512), reason: 'room for the channel');
  });

  test('a saved game without ghosts or runoff still loads', () {
    var state = GameState.lobby();
    for (var i = 0; i < 5; i++) {
      state = apply(state, AddPlayer(PlayerId('p$i'), 'P$i')).state;
    }
    final json = encodeState(state);
    (json['settings']! as Map<String, Object?>)
      ..remove('ghosts')
      ..remove('ties');
    json.remove('runoff');
    final back = decodeState(
      JsonReader.decode(jsonEncode(json), maxBytes: 1 << 20),
    );
    expect(back.settings.ghosts, const GameSettings().ghosts);
    expect(back.settings.tieRule, const GameSettings().tieRule);
    expect(back.runoff, isEmpty);
  });

  test('a broken ghost view is refused', () {
    final view = encodeView(viewFor(_busy(), const PlayerId('p0')));
    (view['ghost']! as Map<String, Object?>)['votes'] = [
      for (var i = 0; i < maxPlayers + 1; i++)
        {'player': 'p$i', 'target': 'p0'},
    ];
    expect(
      () => decodeView(JsonReader.decode(jsonEncode(view), maxBytes: 1 << 20)),
      throwsA(isA<ProtocolError>()),
    );
  });
}
