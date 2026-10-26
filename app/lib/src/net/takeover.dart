import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:game_host/game_host.dart';
import 'package:game_host/lan.dart';
import 'package:protocol/protocol.dart';
import 'package:secure_channel/secure_channel.dart';
import 'package:whowolf/src/net/discovery.dart';

/// What lets this device take over a room whose host went away: its own
/// candidate keys for this game and the sealer. Only apps that can host on
/// the local network have one (not the browser).
class TakeoverKit {
  TakeoverKit._(this.keys, this.sealer);

  /// New candidate keys, or `null` where this device cannot host.
  static Future<TakeoverKit?> create() async {
    if (kIsWeb) return null;
    try {
      final sodium = await loadSodium();
      return TakeoverKit._(await HostKeys.generate(), SodiumSealer(sodium));
    } on Object {
      return null;
    }
  }

  /// The candidate key pair and secret (the secret goes to the witness).
  final HostKeys keys;

  /// Opens the successor's sealed room.
  final RoomSealer sealer;

  /// What the hello tells the host.
  Candidate get candidate =>
      Candidate(key: keys.publicKey, secret: keys.roomSecret);

  /// Opens the successor's entrance on the local network (any free port,
  /// never the room's) and announces it, so the witness finds it.
  Future<Transport> openEntrance({
    required String room,
    required String name,
  }) async {
    final lan = await LanTransport.bind(port: 0);
    final announcer = RoomAnnouncer();
    await announcer.start(
      hostName: name,
      room: room,
      port: lan.port,
      hostKey: keys.publicKey,
      candidate: true,
    );
    return _Announced(CandidateEntrance(lan, keys), announcer);
  }

  /// The witness's way to the successor: found by its candidate key,
  /// authenticated with key and secret.
  static Future<Connection> dialSuccessor(
    String room,
    Candidate successor,
  ) async {
    final at = HostLocator.shared.findCandidate(room, successor.key);
    if (at == null) throw StateError('successor not announced yet');
    final raw = await dialHost(
      at.ip,
      at.port,
      timeout: const Duration(seconds: 3),
    );
    return connectSecure(
      raw,
      hostKey: successor.key,
      roomSecret: successor.secret,
    );
  }
}

/// An entrance that withdraws its announcement when it closes.
class _Announced implements Transport {
  _Announced(this._inner, this._announcer);

  final Transport _inner;
  final RoomAnnouncer _announcer;

  @override
  Stream<Connection> get connections => _inner.connections;

  @override
  Future<void> close() async {
    await _announcer.stop();
    await _inner.close();
  }
}
