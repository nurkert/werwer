import 'dart:async';

import 'package:game_host/game_host.dart';
import 'package:game_host/lan.dart';
import 'package:game_host/relay.dart';
import 'package:protocol/protocol.dart';
import 'package:secure_channel/secure_channel.dart';
import 'package:whowolf/src/net/discovery.dart';
import 'package:whowolf/src/net/game_session.dart';

/// The room's public key and secret. From the QR code, or filled in by the
/// host's welcome for players it let in after comparing the check code.
class RoomKeys {
  RoomKeys({this.hostKey, this.roomSecret});

  List<int>? hostKey;
  List<int>? roomSecret;
}

/// Dials a host every way at once and takes the first that answers:
/// the last known address on the local network, the address the room search
/// sees now for this room and key (the host may have moved), and the relay
/// server. Each path is end-to-end encrypted; with the [keys] the host is
/// authenticated, without them it lets the player in after the check code.
Dial dialerFor({
  required RoomKeys keys,
  required String room,
  LanAddress? lan,
  String? relayRoom,
  Uri? server,
  HostLocator? locator,
}) {
  Future<Connection> secure(Future<Connection> raw) async => connectSecure(
    await raw,
    hostKey: keys.hostKey,
    roomSecret: keys.roomSecret,
  );
  return () {
    final found = locator?.find(room, keys.hostKey);
    final addresses = {?lan, ?found}.toList();
    return firstConnection([
      for (final a in addresses)
        () =>
            secure(dialHost(a.ip, a.port, timeout: const Duration(seconds: 5))),
      if (relayRoom != null && server != null)
        () => secure(dialRelay(server, relayRoom)),
    ]);
  };
}

/// Starts all [attempts] together and returns the first connection that
/// succeeds; later successes are closed. Fails only if every attempt fails.
Future<Connection> firstConnection(
  List<Future<Connection> Function()> attempts,
) {
  if (attempts.isEmpty) {
    return Future.error(StateError('no way to reach the host'));
  }
  final winner = Completer<Connection>();
  var failed = 0;
  for (final attempt in attempts) {
    unawaited(_settle(attempt(), winner, () => ++failed == attempts.length));
  }
  return winner.future;
}

Future<void> _settle(
  Future<Connection> attempt,
  Completer<Connection> winner,
  bool Function() lastFailure,
) async {
  try {
    final connection = await attempt;
    if (winner.isCompleted) {
      await connection.close();
    } else {
      winner.complete(connection);
    }
  } on Object catch (error, stack) {
    if (lastFailure() && !winner.isCompleted) {
      winner.completeError(error, stack);
    }
  }
}
