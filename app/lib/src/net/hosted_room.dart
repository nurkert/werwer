import 'dart:math';

import 'package:game_host/game_host.dart';
import 'package:game_host/lan.dart';
import 'package:game_host/relay.dart';
import 'package:protocol/protocol.dart';

/// A room this device hosts: the game host with its LAN socket and, if a
/// relay server is configured and reachable, a room on the relay for remote
/// players. The host player's own app joins through [GameHost.connectOwner],
/// like anyone else.
class HostedRoom {
  HostedRoom._(this.host, this.link, {required this.relayFailed});

  /// Opens a room on the local network and, with [relayServer], online.
  static Future<HostedRoom> open({Uri? relayServer}) async {
    final random = Random.secure();
    final code = List.generate(
      roomCodeLength,
      (_) => random.nextInt(10),
    ).join();
    final lan = await LanTransport.bind();
    final host = GameHost(roomCode: code, random: random)..serve(lan);
    final addresses = await privateAddresses();
    final ip = addresses.isEmpty ? null : addresses.first.address;

    RelayTransport? relay;
    if (relayServer != null) {
      try {
        relay = await RelayTransport.open(relayServer);
        host.serve(relay);
      } on Object {
        relay = null;
      }
    }
    final link = JoinLink(
      room: code,
      lan: ip == null ? null : LanAddress(ip, lan.port),
      relayRoom: relay?.roomId,
      server: relay?.server,
    );
    return HostedRoom._(
      host,
      link,
      relayFailed: relayServer != null && relay == null,
    );
  }

  final GameHost host;

  /// How to reach this room; shown as text and as QR code.
  final JoinLink link;

  /// A relay server was configured but could not be reached.
  final bool relayFailed;

  String get roomCode => host.roomCode;

  Future<void> close() => host.close();
}
