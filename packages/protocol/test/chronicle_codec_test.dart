import 'dart:convert';

import 'package:game_core/game_core.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

void main() {
  test('the chronicle and the open votes survive JSON and back', () {
    const view = PlayerView(
      you: PlayerId('p1'),
      phase: Phase.ended,
      round: 2,
      seats: [],
      deaths: [],
      waitingFor: 0,
      settings: GameSettings(openVotes: true),
      openVotes: {PlayerId('p1'): PlayerId('p2'), PlayerId('p3'): null},
      chronicle: [
        ChronicleEntry(
          round: 1,
          kind: ChronicleKind.hunt,
          target: PlayerId('p2'),
        ),
        ChronicleEntry(
          round: 1,
          kind: ChronicleKind.vote,
          actor: PlayerId('p1'),
          runoff: true,
        ),
      ],
    );
    final back = decodeView(
      JsonReader.decode(jsonEncode(encodeView(view)), maxBytes: 1 << 20),
    );
    expect(back.settings.openVotes, isTrue);
    expect(back.openVotes, view.openVotes);
    expect(back.chronicle, hasLength(2));
    expect(back.chronicle.first.kind, ChronicleKind.hunt);
    expect(back.chronicle.first.target, const PlayerId('p2'));
    expect(back.chronicle.last.actor, const PlayerId('p1'));
    expect(back.chronicle.last.target, isNull);
    expect(back.chronicle.last.runoff, isTrue);
  });

  test('a chronicle entry with a bad id is refused', () {
    const view = PlayerView(
      you: PlayerId('p1'),
      phase: Phase.ended,
      round: 1,
      seats: [],
      deaths: [],
      waitingFor: 0,
    );
    final json = encodeView(view)
      ..['chronicle'] = [
        {'r': 1, 'k': 'vote', 'a': '../x'},
      ];
    expect(
      () => decodeView(JsonReader.decode(jsonEncode(json), maxBytes: 1 << 20)),
      throwsA(isA<ProtocolError>()),
    );
  });
}
