import 'dart:math';

import 'package:game_host/game_host.dart';
import 'package:game_host/lan.dart';
import 'package:protocol/protocol.dart';

/// A room this device hosts: the game host plus its LAN socket. The host
/// player's own app joins through [GameHost.connectOwner], like anyone else.
class HostedRoom {
  HostedRoom._(this.host, this._lan, this.address);

  /// Opens a room on the local network.
  static Future<HostedRoom> open() async {
    final random = Random.secure();
    final code = List.generate(
      roomCodeLength,
      (_) => random.nextInt(10),
    ).join();
    final lan = await LanTransport.bind();
    final addresses = await privateAddresses();
    final host = GameHost(roomCode: code, random: random)..serve(lan);
    final ip = addresses.isEmpty ? null : addresses.first.address;
    return HostedRoom._(host, lan, ip == null ? null : '$ip:${lan.port}');
  }

  final GameHost host;
  final LanTransport _lan;

  /// Where players dial in (`ip:port`), or `null` without a local network.
  final String? address;

  String get roomCode => host.roomCode;

  int get port => _lan.port;

  Future<void> close() => host.close();
}
