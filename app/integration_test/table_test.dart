// Runs on a real device or desktop, e.g.
//   flutter test integration_test -d macos
// The room is announced and found over Bonjour, then the host player plays a
// round through the real UI with four bots joining over the local network.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:game_host/game_host.dart';
import 'package:game_host/lan.dart';
import 'package:integration_test/integration_test.dart';
import 'package:protocol/protocol.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/app.dart';
import 'package:whowolf/src/game/game_screen.dart';
import 'package:whowolf/src/game/sheep.dart';
import 'package:whowolf/src/net/discovery.dart';
import 'package:whowolf/src/net/game_session.dart';
import 'package:whowolf/src/net/hosted_room.dart';
import 'package:whowolf/src/theme.dart';

/// A player on another device, speaking the protocol over the network.
class Bot {
  Bot(this.name, this.connection) {
    connection.messages.listen((raw) {
      final message = HostMessage.parse(raw);
      if (message is StateMessage) {
        view = message.view;
        _act();
      }
    });
    connection.send(Hello(name: name, room: room).encode());
  }

  static late String room;
  final String name;
  final Connection connection;
  PlayerView? view;
  final _done = <String>{};

  void _once(String key, ClientMessage message) {
    if (_done.add(key)) connection.send(message.encode());
  }

  void _act() {
    final v = view!;
    if (v.phase == Phase.roleReveal) {
      _once('confirm', const ConfirmRoleIntent());
    } else if (v.phase == Phase.night && v.yourSeat.isAlive) {
      final others = v.seats.where(
        (s) =>
            s.isAlive &&
            s.id != v.you &&
            !(v.yourRole == Role.werewolf && s.role == Role.werewolf),
      );
      _once('sheep${v.round}', SheepIntent(min(3, v.yourFlock ?? 0)));
      _once('night${v.round}', NightIntent(others.first.id));
    } else if (v.phase == Phase.vote && v.yourSeat.isAlive) {
      _once('vote${v.round}', const VoteIntent(null));
    }
  }
}

Future<void> until(
  WidgetTester tester,
  bool Function() done, {
  int seconds = 30,
}) async {
  for (var i = 0; i < seconds * 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (done()) {
      await tester.pump(const Duration(milliseconds: 100));
      return;
    }
  }
  fail('condition not met in $seconds s');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a room is found over Bonjour', (tester) async {
    final room = await HostedRoom.open(hostName: 'Ada');
    final finder = RoomFinder();
    try {
      await tester.runAsync(() async {
        for (var i = 0; i < 100 && finder.rooms.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
        }
      });
      final found = finder.rooms.where((r) => r.room == room.roomCode);
      expect(found, isNotEmpty, reason: 'room not announced/found via mDNS');
      expect(found.first.hostName, 'Ada');
    } finally {
      finder.dispose();
      await room.close();
    }
  });

  testWidgets('the host plays a round with four players over the network', (
    tester,
  ) async {
    final room = await HostedRoom.open(hostName: 'Ada');
    Bot.room = room.roomCode;
    final session = GameSession(
      name: 'Ada',
      roomCode: room.roomCode,
      dial: () async => room.host.connectOwner(),
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: supportedLocales,
        theme: buildTheme(),
        home: GameScreen(session: session, room: room),
      ),
    );
    await until(tester, () => session.view != null);

    final lan = room.link.lan!;
    final bots = <Bot>[];
    await tester.runAsync(() async {
      for (final name in ['Bo', 'Cem', 'Dina', 'Eli']) {
        // Loopback: a desktop firewall may block the Wi-Fi address for an
        // unsigned test build; the network path is the same otherwise.
        bots.add(Bot(name, await dialHost('127.0.0.1', lan.port)));
      }
    });
    await until(tester, () => session.view!.seats.length == 5);
    expect(find.text('Holt die anderen dazu'), findsOneWidget);

    // Owner starts through the UI.
    await tester.scrollUntilVisible(find.text('Rollen verteilen'), 300);
    await tester.tap(find.text('Rollen verteilen'));
    await until(tester, () => session.view!.phase == Phase.roleReveal);
    await tester.tap(find.textContaining('Tippe, um deine Rolle'));
    await tester.pump();
    await tester.tap(find.text('Verstanden'));
    await until(tester, () => session.view!.phase == Phase.night);

    // Night: the narrator speaks, everyone has a meadow with a flock.
    expect(find.textContaining('Die Nacht legt sich'), findsOneWidget);
    expect(find.byType(SheepMeadow), findsOneWidget);
    expect(session.view!.yourFlock, isNotNull);
    final me = session.view!;
    if (me.yourRole != Role.villager) {
      final target = me.seats.firstWhere(
        (s) =>
            s.id != me.you &&
            !(me.yourRole == Role.werewolf && s.role == Role.werewolf),
      );
      await tester.tap(find.text(target.name).first);
    }
    // Villagers' decoy pick goes out by itself after a few seconds.
    await until(tester, () => session.view!.phase != Phase.night, seconds: 40);

    // Shows in the test log which path (role) this run took.
    // ignore: avoid_print
    print('host was ${me.yourRole?.name}, now ${session.view!.phase.name}');
    if (session.view!.phase == Phase.day) {
      // Morning: everyone sees how well everyone slept.
      expect(find.text('Wie gut habt ihr geschlafen?'), findsOneWidget);
      expect(find.textContaining('Schäfchen'), findsWidgets);
      expect(find.textContaining('Die Sonne geht'), findsOneWidget);
      expect(session.view!.lastNightSheep.length, greaterThanOrEqualTo(4));
    }

    await tester.pumpWidget(const SizedBox());
    for (final bot in bots) {
      await bot.connection.close();
    }
  });
}
