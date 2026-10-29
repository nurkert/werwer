import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:game_host/game_host.dart';
import 'package:protocol/protocol.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/admit_card.dart';
import 'package:whowolf/src/game/stage.dart';
import 'package:whowolf/src/net/game_session.dart';
import 'package:whowolf/src/theme.dart';

/// [stage]: on the theatre's stage (its parallax listens to the motion
/// sensors, which a test with real async work would notice missing).
Widget _app(Widget child, {bool stage = true}) => MaterialApp(
  theme: buildTheme(),
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: const [Locale('en'), Locale('de')],
  home: stage ? StageScaffold(body: child) : Scaffold(body: child),
);

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets('the admit card fits a ${width.toInt()} px phone', (
      tester,
    ) async {
      tester.view
        ..physicalSize = Size(width, 700)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      bool? answer;
      await tester.pumpWidget(
        _app(
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AdmitCard(
                join: const PendingJoin(
                  id: 1,
                  name: 'Maximiliane',
                  checkCode: [13, 5, 9, 7],
                ),
                note: 'Joins as a ghost.',
                more: 2,
                onAnswer: (admit) => answer = admit,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull, reason: 'no overflow');
      expect(find.text('Joins as a ghost.'), findsOneWidget);
      await tester.tap(find.text('Let in').hitTestable());
      expect(answer, isTrue);
      await tester.tap(find.text('Refuse').hitTestable());
      expect(answer, isFalse);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('in a running game the leader is asked by day, never at night', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final timers = <(Duration, void Function())>[];
    final host = GameHost(
      roomCode: '1234',
      random: Random(3),
      settings: const GameSettings(roles: {}),
      config: const HostConfig(switchLead: Duration.zero),
      startTimer: (after, callback) {
        final entry = (after, callback);
        timers.add(entry);
        return () => timers.remove(entry);
      },
    );
    final transport = MemoryTransport();
    host.serve(transport);
    final owner = GameSession(
      name: 'Mira',
      roomCode: '1234',
      dial: () async => host.connectOwner(),
    );
    final bots = <Connection>[];
    Future<void> settle() => tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await settle();
    for (final name in ['Bo', 'Cem', 'Dina', 'Eli']) {
      final bot = transport.connect()
        ..send(Hello(name: name, room: '1234').encode());
      bots.add(bot);
    }
    await settle();
    await tester.pumpWidget(
      _app(LateJoinPrompt(session: owner), stage: false),
    );

    owner.send(const StartGameIntent());
    await settle();
    // Everyone confirms; the owner by intent, the bots by hand.
    owner.send(const ConfirmRoleIntent());
    for (final bot in bots) {
      bot.send(const ConfirmRoleIntent().encode());
    }
    await settle();
    expect(host.state.phase, Phase.night);

    final late = transport.connect()
      ..send(const Hello(name: 'Late', room: '1234').encode());
    await settle();
    await tester.pump();
    expect(find.byType(AdmitCard), findsNothing, reason: 'not at night');

    // The night: the werewolf takes someone, everyone else picks too.
    final players = host.state.players;
    final wolf = players.firstWhere((p) => p.role == Role.werewolf);
    final prey = players.firstWhere((p) => p.role != Role.werewolf);
    for (final p in players) {
      final target = p == wolf ? prey.id : wolf.id;
      final message = NightIntent(target);
      if (p.id == owner.view!.you) {
        owner.send(message);
      } else {
        bots[players.indexOf(p) - 1].send(message.encode());
      }
    }
    await settle();
    // The hunt's fixed time (counted on the real clock, so a hair less).
    for (final entry in [...timers]) {
      if (entry.$1 <= togetherHuntTime && timers.remove(entry)) entry.$2();
    }
    await settle();
    expect(host.state.phase, Phase.day);
    // The card slides in.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Late wants to join'), findsOneWidget);
    expect(find.text('Joins as a ghost.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Let in').hitTestable());
    await settle();
    await tester.pump(const Duration(milliseconds: 400));
    expect(host.state.players, hasLength(6));
    expect(host.state.players.last.isAlive, isFalse);
    // The card slides away.
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AdmitCard), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await late.close();
    for (final bot in bots) {
      await bot.close();
    }
    owner.dispose();
    await host.close();
  });
}
