// The host takeover with everything real: LAN sockets, Bonjour, libsodium,
// the sealed room, the candidate entrance and the players' own sessions.
// Only the people are bots, and all phones share this one machine.
//
//   flutter test integration_test/takeover_test.dart -d macos
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:integration_test/integration_test.dart';
import 'package:protocol/protocol.dart';
import 'package:whowolf/src/join_screen.dart';
import 'package:whowolf/src/net/discovery.dart';
import 'package:whowolf/src/net/game_session.dart';
import 'package:whowolf/src/net/hosted_room.dart';
import 'package:whowolf/src/net/room_store.dart';
import 'package:whowolf/src/net/store.dart';

Future<void> until(bool Function() condition, {int seconds = 30}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('timed out');
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<(HostedRoom, GameSession, List<GameSession>)> table() async {
    await const RoomStore().clear();
    await const Store().clearResume();
    final room = await HostedRoom.open(hostName: 'Ada');
    final owner = GameSession(
      name: 'Ada',
      roomCode: room.roomCode,
      dial: () async => room.host.connectOwner(),
      hosted: room,
    );
    final link = room.link;
    // All phones are this machine (see HostLocator.loopback).
    HostLocator.loopback = true;
    final here = LanAddress('127.0.0.1', link.lan!.port);
    final players = [
      for (final name in ['Ben', 'Cleo', 'Dev'])
        await playerSession(
          name: name,
          room: link.room,
          lan: here,
          hostKey: link.hostKey,
          roomSecret: link.roomSecret,
        ),
    ];
    await until(() => owner.view?.seats.length == 4);
    owner.send(const StartGameIntent());
    await until(
      () => players.every((p) => p.view?.phase == Phase.roleReveal),
    );
    // Successor and witness are chosen and hold their parts.
    await Future<void>.delayed(const Duration(seconds: 1));
    return (room, owner, players);
  }

  testWidgets('the host phone dies: another phone takes over the room', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final (room, owner, players) = await table();
      final roles = {
        for (final p in players) p.name: p.view!.yourRole,
      };
      // No goodbye, sockets gone: like a phone whose battery ran out.
      await room.close(quietly: true);
      owner.dispose();

      await until(() => players.any((p) => p.tookOver));
      final successor = players.firstWhere((p) => p.tookOver);
      await until(
        () => players.every((p) => p.status == SessionStatus.connected),
      );
      expect(successor.isOwner, isTrue);
      expect(successor.hosted, isNotNull);
      for (final p in players) {
        expect(p.view!.yourRole, roles[p.name], reason: p.name);
        expect(p.view!.phase, Phase.roleReveal);
      }
      // The new host takes intents: everyone confirms their role.
      for (final p in players) {
        p.send(const ConfirmRoleIntent());
      }
      await until(
        () => players.every((p) => p.unconfirmed == 0 && p.view!.youConfirmed),
      );
      for (final p in players) {
        p.dispose();
      }
    });
  });

  testWidgets('the host leaves on purpose: the game goes on at once', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final (_, owner, players) = await table();
      final watch = Stopwatch()..start();
      await owner.leave();
      owner.dispose();
      await until(() => players.any((p) => p.tookOver), seconds: 10);
      await until(
        () => players.every((p) => p.status == SessionStatus.connected),
      );
      // Nobody waited for a missing host (six seconds and more).
      expect(watch.elapsed.inSeconds, lessThan(6));
      for (final p in players) {
        p.dispose();
      }
    });
  });
}
