import 'dart:convert';
import 'dart:math';

import 'package:game_core/game_core.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

const token = '0123456789abcdef0123456789abcdef';

void main() {
  group('client messages', () {
    test('round-trip', () {
      final messages = <ClientMessage>[
        const Hello(name: 'Ada', room: '1234'),
        const Hello(name: 'Ada', room: '1234', token: token),
        const StartGameIntent(),
        const ConfirmRoleIntent(),
        NightIntent(const PlayerId('p3')),
        NightIntent.of(const [PlayerId('p3'), PlayerId('p4')]),
        NightIntent.of(const []),
        const ShootIntent(PlayerId('p2')),
        const ShootIntent(null),
        SettingsIntent(Preset.fullStage.settings),
        SettingsIntent(
          Preset.classic.settings.copyWith(
            werewolves: 2,
            nightTime: const Duration(seconds: 40),
          ),
        ),
        const VoteIntent(PlayerId('p2')),
        const VoteIntent(null),
        const EndDiscussionIntent(),
        const KickIntent(PlayerId('p4')),
        const LeaveIntent(),
        const RematchIntent(),
        const SheepIntent(-3),
        const PersonaIntent(Persona.smith),
        const SwapSeatsIntent(PlayerId('p1'), PlayerId('p2')),
        const AdmitIntent(3, admit: true),
        const PingIntent(12),
      ];
      for (final m in messages) {
        final back = ClientMessage.parse(m.encode());
        expect(back.runtimeType, m.runtimeType);
        expect(back.encode(), m.encode());
      }
    });

    test('intents carry an optional sequence number', () {
      final numbered = ClientMessage.parseNumbered(
        NightIntent(const PlayerId('p3')).encode(seq: 7),
      );
      expect(numbered.seq, 7);
      expect(numbered.message, isA<NightIntent>());
      expect(
        ClientMessage.parseNumbered(const ConfirmRoleIntent().encode()).seq,
        isNull,
      );
      expect(
        () => ClientMessage.parse('{"v":5,"type":"confirm","seq":0}'),
        throwsA(isA<ProtocolError>()),
      );
    });

    test('anything not exactly valid is refused', () {
      final bad = [
        '',
        'null',
        '[]',
        '{',
        '{"v":5}',
        '{"v":6,"type":"start"}',
        '{"v":5,"type":"dance"}',
        '{"v":"1","type":"start"}',
        '{"v":5,"type":"night"}',
        '{"v":5,"type":"night","target":"p3"}',
        '{"v":5,"type":"night","targets":5}',
        '{"v":5,"type":"night","targets":[5]}',
        '{"v":5,"type":"night","targets":["P3"]}',
        '{"v":5,"type":"night","targets":["../etc"]}',
        '{"v":5,"type":"night","targets":["p1","p2","p3"]}',
        '{"v":2,"type":"night","targets":["p1"]}',
        '{"v":5,"type":"shoot","target":"P1"}',
        '{"v":5,"type":"settings"}',
        '{"v":5,"type":"settings","settings":{}}',
        jsonEncode({
          'v': protocolVersion,
          'type': 'settings',
          'settings': {
            ...encodeSettings(const GameSettings()),
            'roles': ['werewolf'],
          },
        }),
        jsonEncode({
          'v': protocolVersion,
          'type': 'settings',
          'settings': {
            ...encodeSettings(const GameSettings()),
            'roles': ['seer', 'seer'],
          },
        }),
        jsonEncode({
          'v': protocolVersion,
          'type': 'settings',
          'settings': {...encodeSettings(const GameSettings()), 'night': -1},
        }),
        jsonEncode({
          'v': protocolVersion,
          'type': 'settings',
          'settings': {...encodeSettings(const GameSettings()), 'sheep': 1},
        }),
        '{"v":5,"type":"hello","name":"Ada","room":"12a4"}',
        '{"v":5,"type":"hello","name":"Ada","room":"12345"}',
        '{"v":5,"type":"hello","name":"Ada","room":"1234","token":"short"}',
        '{"v":5,"type":"hello","name":"${'x' * 100}","room":"1234"}',
        jsonEncode({'v': protocolVersion, 'type': 'hello', 'name': 'x' * 2000}),
      ];
      for (final raw in bad) {
        expect(
          () => ClientMessage.parse(raw),
          throwsA(isA<ProtocolError>()),
          reason: raw,
        );
      }
    });

    test('random garbage never throws anything but ProtocolError', () {
      final random = Random(5);
      const alphabet = r'{}[]":,0123456789abcdefv typehlonigtr-.\';
      for (var i = 0; i < 5000; i++) {
        final raw = String.fromCharCodes([
          for (var j = 0; j < random.nextInt(80); j++)
            alphabet.codeUnitAt(random.nextInt(alphabet.length)),
        ]);
        try {
          ClientMessage.parse(raw);
        } on ProtocolError {
          // expected
        }
      }
    });
  });

  group('host messages', () {
    test('a full view round-trips', () {
      var state = GameState.lobby();
      for (var i = 0; i < 5; i++) {
        state = apply(state, AddPlayer(PlayerId('p$i'), 'Name $i')).state;
      }
      state = apply(state, StartGame(random: Random(2))).state;
      for (var i = 0; i < 5; i++) {
        state = apply(state, ConfirmRole(PlayerId('p$i'))).state;
      }
      final wolf = state.players.firstWhere((p) => p.role == Role.werewolf);
      final victim = state.players.firstWhere((p) => p.role == Role.villager);
      state = apply(state, WerewolfVote(wolf.id, victim.id)).state;

      final message = StateMessage(
        view: viewFor(state, wolf.id),
        isOwner: true,
        phaseEndsInMs: 4200,
        version: 17,
        pending: const [
          PendingJoin(id: 2, name: 'Eve', checkCode: [3, 15, 0]),
        ],
      );
      final back = HostMessage.parse(message.encode()) as StateMessage;
      expect(back.encode(), message.encode());
      expect(back.view.packChoices, {wolf.id: victim.id});
      expect(back.view.yourRole, Role.werewolf);
    });

    test('every view of a game with all roles round-trips', () {
      final random = Random(9);
      var state = GameState.lobby(settings: Preset.fullStage.settings);
      for (var i = 0; i < 8; i++) {
        state = apply(state, AddPlayer(PlayerId('p$i'), 'Name $i')).state;
      }
      state = apply(state, StartGame(random: random)).state;
      final kinds = <String>{};
      for (var step = 0; step < 400 && state.phase != Phase.ended; step++) {
        for (final p in state.players) {
          final view = viewFor(state, p.id);
          final message = StateMessage(view: view, isOwner: false);
          final back = HostMessage.parse(message.encode()) as StateMessage;
          expect(back.encode(), message.encode());
          if (view.couple.isNotEmpty) kinds.add('couple');
          if (view.victim != null) kinds.add('victim');
          if (view.shooter != null) kinds.add('shooter');
        }
        final alive = state.alive.toList();
        final waiting = alive.where(
          (p) => !state.nightChoices.containsKey(p.id),
        );
        final actor = state.phase == Phase.night
            ? waiting.first
            : alive[random.nextInt(alive.length)];
        final others = alive.where((o) => o.id != actor.id).toList();
        final other = others[random.nextInt(others.length)].id;
        try {
          state = apply(state, switch (state.phase) {
            Phase.roleReveal => ConfirmRole(actor.id),
            Phase.night => nightAction(state, actor.id, switch (nightTask(
              state,
              actor.id,
            )!) {
              NightAbility.link => [actor.id, other],
              NightAbility.brew => [?state.nightVictim],
              _ => [other],
            }),
            Phase.day => const EndDiscussion(),
            Phase.vote => CastVote(actor.id, other),
            Phase.hunterShot => HunterShoot(state.shooter!, other),
            _ => const PhaseTimeout(),
          }).state;
        } on RuleViolation {
          state = apply(state, const PhaseTimeout()).state;
        }
      }
      expect(state.phase, Phase.ended);
      expect(kinds, containsAll(['couple', 'victim']));
    });

    test('other host messages round-trip', () {
      for (final m in <HostMessage>[
        const Welcome(token: token, you: PlayerId('p1')),
        Welcome(
          token: token,
          you: const PlayerId('p1'),
          roomSecret: [
            for (var i = 0; i < 32; i++) i,
          ],
        ),
        const Refused(Violation.invalidTarget),
        const Bye(ByeReason.kicked),
        const Waiting(),
        const Ack(4, version: 9),
        const Pong(3),
      ]) {
        expect(HostMessage.parse(m.encode()).encode(), m.encode());
      }
    });

    test('invalid host messages are refused', () {
      for (final raw in [
        '{"v":5,"type":"welcome","token":"x","you":"p1"}',
        '{"v":5,"type":"welcome","token":"$token","you":"p1","secret":"AAAA"}',
        '{"v":5,"type":"bye","reason":"whatever"}',
        '{"v":5,"type":"state","owner":true}',
      ]) {
        expect(() => HostMessage.parse(raw), throwsA(isA<ProtocolError>()));
      }
    });
  });
}
