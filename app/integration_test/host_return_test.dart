// The roadmap's device check, automated: the host's app dies in the middle
// of the vote (no goodbye, sockets gone), comes back 30 seconds later from
// its saved room, and the round carries on without anyone touching a thing.
//
//   flutter test integration_test/host_return_test.dart -d macos
//   flutter test integration_test/host_return_test.dart -d <iphone> --publish-port
//
// Everything is real except the people: the LAN socket, the encrypted
// channel, the snapshot file and the players' own reconnecting sessions.
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:game_host/game_host.dart';
import 'package:game_host/lan.dart';
import 'package:integration_test/integration_test.dart';
import 'package:protocol/protocol.dart';
import 'package:secure_channel/secure_channel.dart';
import 'package:whowolf/src/net/game_session.dart';
import 'package:whowolf/src/net/hosted_room.dart';
import 'package:whowolf/src/net/room_store.dart';

/// Plays what a session sees, like a person would (one action per step).
void autoplay(GameSession s) {
  final done = <String>{};
  void once(String key, ClientMessage m) {
    if (done.add(key)) s.send(m);
  }

  s.addListener(() {
    final v = s.view;
    if (v == null) return;
    final others = [
      for (final seat in v.seats)
        if (seat.isAlive && seat.id != v.you) seat.id,
    ];
    switch (v.phase) {
      case Phase.roleReveal:
        once('confirm', const ConfirmRoleIntent());
      case Phase.night when v.yourSeat.isAlive && !v.youActed:
        final prey = [
          for (final seat in v.seats)
            if (seat.isAlive && seat.id != v.you && seat.role != Role.werewolf)
              seat.id,
        ];
        once(
          'night${v.round}${v.nightStep.name}',
          NightIntent(
            v.yourNightTask == NightAbility.hunt ? prey.first : others.first,
          ),
        );
      case Phase.day when s.isOwner:
        once('end${v.round}', const EndDiscussionIntent());
      case Phase.lobby ||
          Phase.night ||
          Phase.day ||
          Phase.vote ||
          Phase.hunterShot ||
          Phase.ended:
        break;
    }
  });
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'the host closes the app in the middle of the vote and comes back',
    (tester) async {
      await tester.runAsync(() async {
        await const RoomStore().clear();
        var room = await HostedRoom.open(hostName: 'Ada');
        final code = room.roomCode;

        // The players' phones: they dial the host on its port, and while
        // the host is gone their tries fail like a closed port would.
        var hostUp = true;
        final open = <Connection>[];
        Future<Connection> dial() async {
          if (!hostUp) throw StateError('connection refused');
          final raw = await dialHost('127.0.0.1', room.link.lan!.port);
          final secure = await connectSecure(
            raw,
            hostKey: room.link.hostKey,
            roomSecret: room.link.roomSecret,
          );
          open.add(secure);
          return secure;
        }

        var owner = GameSession(
          name: 'Ada',
          roomCode: code,
          dial: () async => room.host.connectOwner(),
        );
        final players = [
          for (final name in ['Bo', 'Cem', 'Dina', 'Emil'])
            GameSession(name: name, roomCode: code, dial: dial),
        ];
        [owner, ...players].forEach(autoplay);
        Future<void> until(String what, bool Function() done) async {
          for (var i = 0; i < 600; i++) {
            if (done()) return;
            await Future<void>.delayed(const Duration(milliseconds: 100));
          }
          fail('timed out waiting for: $what');
        }

        await until('everyone seated', () => owner.view?.seats.length == 5);
        owner.send(const StartGameIntent());
        await until('the first vote', () => owner.view?.phase == Phase.vote);

        // One living player votes before the host goes away; that vote must
        // stay.
        await until(
          'every phone at the vote',
          () => players.every((p) => p.view?.phase == Phase.vote),
        );
        final early = players.firstWhere((p) => p.view!.yourSeat.isAlive);
        final target = early.view!.seats
            .firstWhere((s) => s.isAlive && s.id != early.view!.you)
            .id;
        early.send(VoteIntent(target));
        await until('the early vote', () => early.view?.youVoted ?? false);
        final left = owner.phaseEndsAt!.difference(DateTime.now());

        // The host's app dies: every socket breaks, nobody says goodbye.
        hostUp = false;
        for (final c in open) {
          await c.close();
        }
        await Future<void>.delayed(const Duration(milliseconds: 300));
        await room.host.close();
        owner.dispose();
        await until(
          'everyone pausing',
          () => players.every((p) => p.status == SessionStatus.reconnecting),
        );
        final pausedView = players[1].view;
        expect(pausedView?.phase, Phase.vote, reason: 'the last view stays');

        await Future<void>.delayed(const Duration(seconds: 30));

        // The host opens the app again: the room comes back from its file.
        final saved = await const RoomStore().load();
        expect(saved, isNotNull, reason: 'no saved room');
        room = await HostedRoom.restore(saved!, hostName: 'Ada');
        expect(room.roomCode, code);
        hostUp = true;
        owner = GameSession(
          name: 'Ada',
          roomCode: code,
          token: room.host.ownerToken,
          dial: () async => room.host.connectOwner(),
        );
        autoplay(owner);

        // Nobody does anything: the phones find the host by themselves.
        await until(
          'everyone back',
          () => [owner, ...players].every(
            (s) => s.status == SessionStatus.connected && s.view != null,
          ),
        );
        expect(owner.view!.phase, Phase.vote);
        expect(early.view!.youVoted, isTrue, reason: 'the early vote is kept');
        expect(early.view!.yourVote, target);
        // The vote's timer goes on with what was left, not from the start.
        final now = owner.phaseEndsAt!.difference(DateTime.now());
        expect(now, lessThanOrEqualTo(left + const Duration(seconds: 2)));

        // The rest vote, and the round goes on.
        for (final s in [owner, ...players.skip(1)]) {
          if (s.view!.yourSeat.isAlive) s.send(const VoteIntent(null));
        }
        await until(
          'the vote resolved',
          () => owner.view?.phase != Phase.vote,
        );
        expect(
          owner.view!.phase,
          anyOf(Phase.night, Phase.ended, Phase.hunterShot),
        );

        for (final s in [owner, ...players]) {
          s.dispose();
        }
        await room.close();
      });
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
