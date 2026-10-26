import 'dart:convert';
import 'dart:math';

import 'package:game_core/game_core.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

String mark(Object? sign, {Object? target = 'p3'}) => jsonEncode({
  'v': protocolVersion,
  'type': 'mark',
  'target': target,
  'sign': sign,
});

/// Six players in the first night with door signs; p0 and p1 are the
/// werewolves.
GameState signNight() {
  var state = GameState.lobby(settings: Preset.whowolf.settings);
  for (var i = 0; i < 6; i++) {
    state = apply(state, AddPlayer(PlayerId('p$i'), 'P$i')).state;
  }
  state = apply(
    state,
    StartGame(
      random: Random(4),
      roles: const [
        Role.werewolf,
        Role.werewolf,
        Role.villager,
        Role.villager,
        Role.villager,
        Role.villager,
      ],
    ),
  ).state;
  // Dealing shuffles; put the werewolves on p0 and p1.
  state = state.copyWith(
    players: [
      for (final (i, p) in state.players.indexed)
        p.copyWith(role: i < 2 ? Role.werewolf : Role.villager),
    ],
  );
  for (final p in state.players) {
    state = apply(state, ConfirmRole(p.id)).state;
  }
  return state;
}

void main() {
  group('door signs on the wire', () {
    test('the mark intent round-trips, numbered like every intent', () {
      final intent = MarkIntent(const PlayerId('p3'), const [0, 7, 15]);
      final back = ClientMessage.parseNumbered(intent.encode(seq: 4));
      expect(back.seq, 4);
      final parsed = back.message as MarkIntent;
      expect(parsed.target, const PlayerId('p3'));
      expect(parsed.sign, [0, 7, 15]);
      expect(parsed.encode(), intent.encode());
    });

    test('anything but a valid sign is refused', () {
      for (final raw in [
        mark(null),
        mark('0,1,2'),
        mark(<int>[]),
        mark([1, 2]),
        mark([1, 2, 3, 4]),
        mark([1, 2, 16]),
        mark([-1, 2, 3]),
        mark([1, 2.5, 3]),
        mark([1, '2', 3]),
        mark([1, null, 3]),
        mark([1, 2, 1099511627776]),
        mark([1, 2, 3], target: null),
        mark([1, 2, 3], target: 'P3'),
        mark([1, 2, 3], target: 3),
        jsonEncode({
          'v': protocolVersion,
          'type': 'mark',
          'sign': [1, 2, 3],
        }),
      ]) {
        expect(
          () => ClientMessage.parse(raw),
          throwsA(isA<ProtocolError>()),
          reason: raw,
        );
      }
    });

    test('the setting travels; settings without it are refused', () {
      const settings = GameSettings(doorSigns: true);
      final back = ClientMessage.parse(const SettingsIntent(settings).encode());
      expect((back as SettingsIntent).settings, settings);
      final json = encodeSettings(settings)..remove('doorSigns');
      expect(
        () => ClientMessage.parse(
          jsonEncode({
            'v': protocolVersion,
            'type': 'settings',
            'settings': json,
          }),
        ),
        throwsA(isA<ProtocolError>()),
      );
    });

    test('views carry the own sign and the pack mark, strictly', () {
      var state = signNight();
      final sign = doorSignFor(state, const PlayerId('p3'));
      state = apply(
        state,
        MarkDoor(const PlayerId('p0'), const PlayerId('p3'), sign),
      ).state;
      for (final p in state.players) {
        final view = viewFor(state, p.id);
        final message = StateMessage(view: view, isOwner: false);
        final back = HostMessage.parse(message.encode()) as StateMessage;
        expect(back.encode(), message.encode());
        expect(back.view.yourDoorSign, doorSignFor(state, p.id));
        expect(back.view.packMark, view.packMark);
      }
      final wolf = viewFor(state, const PlayerId('p1'));
      expect(wolf.packMark, (target: const PlayerId('p3'), correct: true));
      final villager = encodeView(viewFor(state, const PlayerId('p4')));
      expect(villager.containsKey('packMark'), isFalse);

      String state0(Map<String, Object?> view) => jsonEncode({
        'v': protocolVersion,
        'type': 'state',
        'owner': false,
        'view': view,
        'pending': <Object?>[],
      });
      for (final broken in <Map<String, Object?>>[
        {
          ...villager,
          'doorSign': <int>[1, 2],
        },
        {
          ...villager,
          'doorSign': <int>[1, 2, 99],
        },
        {...villager, 'doorSign': 'abc'},
        {...villager, 'packMark': 'p3'},
        {
          ...villager,
          'packMark': {'target': 'p3'},
        },
        {
          ...villager,
          'packMark': {'target': 'p3', 'correct': 'yes'},
        },
      ]) {
        expect(
          () => HostMessage.parse(state0(broken)),
          throwsA(isA<ProtocolError>()),
          reason: '$broken',
        );
      }
    });

    test("the pack's attempt survives a snapshot", () {
      var state = signNight();
      state = apply(
        state,
        const MarkDoor(PlayerId('p1'), PlayerId('p4'), [1, 2, 3]),
      ).state;
      final json = jsonEncode(encodeState(state));
      final back = decodeState(JsonReader.decode(json, maxBytes: 1 << 20));
      expect(back.packMark, state.packMark);
      expect(back.settings.doorSigns, isTrue);
      expect(jsonEncode(encodeState(back)), json);
      expect(
        () => apply(
          back,
          const MarkDoor(PlayerId('p0'), PlayerId('p3'), [1, 2, 3]),
        ),
        throwsA(isA<RuleViolation>()),
      );
    });
  });
}
