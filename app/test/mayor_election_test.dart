import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:game_host/game_host.dart';
import 'package:protocol/protocol.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/mayor_election.dart';
import 'package:whowolf/src/net/game_session.dart';
import 'package:whowolf/src/stage/mayor_mark.dart';
import 'package:whowolf/src/stage/puppet_card.dart';
import 'package:whowolf/src/theme.dart';

Widget _app(Widget child) => MaterialApp(
  theme: buildTheme(),
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: const [Locale('en'), Locale('de')],
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('the chain of office reads at every size, with a label', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const Wrap(
          children: [
            MayorMark(label: 'Mayor', size: 16),
            MayorMark(label: 'Mayor', size: 22),
            MayorMark(label: 'Mayor'),
            MayorPlaque(label: 'Mayor', size: 26),
            PuppetCard(
              persona: Persona.tinkerer,
              name: 'Ada',
              width: 80,
              mayor: 'Mayor',
            ),
            PuppetCard(persona: Persona.maid, name: 'Bo', width: 120),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(MayorMark), findsNWidgets(5));
    expect(find.byType(MayorPlaque), findsNWidgets(2));
    // The card says it for screen readers too.
    expect(find.bySemanticsLabel(RegExp('^Ada, Mayor')), findsOneWidget);
  });

  testWidgets('the ceremony shows the new mayor and closes by itself', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showMayorCeremony(
              context,
              mayor: const SeatView(
                id: PlayerId('p2'),
                name: 'Bo',
                isAlive: true,
                persona: Persona.tinkerer,
              ),
              you: const PlayerId('p1'),
            ),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('New mayor'), findsOneWidget);
    expect(find.text('Bo'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('New mayor'), findsNothing);
  });

  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(1280, 800),
  ]) {
    testWidgets(
      'electing a mayor: open, pick, confirm, decided '
      '(${size.width.toInt()} px)',
      (tester) async {
        tester.view
          ..physicalSize = size
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final timers = <(Duration, void Function())>[];
        final host = GameHost(
          roomCode: '1234',
          random: Random(3),
          settings: const GameSettings(roles: {}, mayor: true),
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
          bots.add(
            transport.connect()..send(Hello(name: name, room: '1234').encode()),
          );
        }
        await settle();
        owner.send(const StartGameIntent());
        await settle();
        owner.send(const ConfirmRoleIntent());
        for (final bot in bots) {
          bot.send(const ConfirmRoleIntent().encode());
        }
        await settle();
        // The night: the werewolf takes someone who is not the owner.
        final players = host.state.players;
        final me = owner.view!.you;
        final wolf = players.firstWhere((p) => p.role == Role.werewolf);
        final prey = players.firstWhere(
          (p) => p.role != Role.werewolf && p.id != me,
        );
        void send(Player p, ClientMessage message) => p.id == me
            ? owner.send(message)
            : bots[players.indexOf(p) - 1].send(message.encode());
        for (final p in players) {
          send(p, NightIntent(p == wolf ? prey.id : wolf.id));
        }
        await settle();
        for (final entry in [...timers]) {
          if (entry.$1 <= togetherHuntTime && timers.remove(entry)) entry.$2();
        }
        await settle();
        expect(host.state.phase, Phase.day);
        expect(host.state.electsMayor, isTrue);

        await tester.pumpWidget(_app(MayorEntry(session: owner)));
        await tester.pump();
        expect(find.text('Who becomes mayor?'), findsOneWidget);
        expect(find.text('0 of 4 have voted'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'no overflow');

        await tester.tap(find.text('Elect a mayor'));
        await tester.pumpAndSettle();
        expect(find.text('Mayoral election'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'no overflow');

        // A living candidate, not the owner.
        final pick = host.state.alive.firstWhere((p) => p.id != me);
        final card = find.descendant(
          of: find.byType(MayorElection),
          matching: find.text(pick.name),
        );
        await tester.ensureVisible(card.first);
        await tester.pump();
        await tester.tap(card.first);
        await tester.pump();
        await tester.tap(find.text('Vote for ${pick.name}'));
        await settle();
        await tester.pump();
        expect(host.state.mayorVotes[me], pick.id);
        expect(find.text('Your vote: ${pick.name}'), findsOneWidget);

        // Everyone else backs the same: decided at once, the sheet closes.
        for (final p in host.state.alive) {
          if (p.id != me) send(p, MayorIntent(pick.id));
        }
        await settle();
        await tester.pumpAndSettle();
        expect(host.state.mayor, pick.id);
        expect(find.byType(MayorElection), findsNothing);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox());
        for (final bot in bots) {
          await bot.close();
        }
        owner.dispose();
        await host.close();
      },
    );
  }
}
