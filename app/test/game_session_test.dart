import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:game_host/game_host.dart';
import 'package:protocol/protocol.dart';
import 'package:whowolf/src/net/game_session.dart';

void main() {
  test('sessions join a host, play into the night and come back', () async {
    final host = GameHost(roomCode: '1234', random: Random(4));
    final lan = MemoryTransport();
    host.serve(lan);
    Future<void> settle() => Future<void>.delayed(Duration.zero);

    final owner = GameSession(
      name: 'Owner',
      roomCode: '1234',
      dial: () async => host.connectOwner(),
    );
    final others = [
      for (final name in ['Bo', 'Cem'])
        GameSession(
          name: name,
          roomCode: '1234',
          dial: () async => lan.connect(),
        ),
    ];
    await settle();
    expect(owner.isOwner, isTrue);
    expect(owner.view!.seats, hasLength(3));
    expect(others.first.status, SessionStatus.connected);

    owner.send(const StartGameIntent());
    await settle();
    for (final s in [owner, ...others]) {
      s.send(const ConfirmRoleIntent());
    }
    await settle();
    for (final s in [owner, ...others]) {
      expect(s.view!.phase, Phase.night);
    }
    expect(owner.phaseEndsAt, isNotNull);

    owner.dispose();
    for (final s in others) {
      s.dispose();
    }
    await host.close();
  });

  test('a wrong room code ends the session with a reason', () async {
    final host = GameHost(roomCode: '1234', random: Random(4));
    final lan = MemoryTransport();
    host.serve(lan);
    final session = GameSession(
      name: 'X',
      roomCode: '9999',
      dial: () async => lan.connect(),
    );
    await Future<void>.delayed(Duration.zero);
    expect(session.status, SessionStatus.ended);
    expect(session.byeReason, ByeReason.wrongRoom);
    session.dispose();
    await host.close();
  });

  test('an unreachable host ends the session instead of retrying', () async {
    final session = GameSession(
      name: 'X',
      roomCode: '1234',
      dial: () => Future.error(const SocketExceptionLike()),
    );
    await Future<void>.delayed(Duration.zero);
    expect(session.status, SessionStatus.ended);
    expect(session.byeReason, isNull);
    session.dispose();
  });
}

class SocketExceptionLike implements Exception {
  const SocketExceptionLike();
}
