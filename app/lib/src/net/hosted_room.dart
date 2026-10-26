import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:game_host/game_host.dart';
import 'package:game_host/lan.dart';
import 'package:game_host/relay.dart';
import 'package:protocol/protocol.dart';
import 'package:secure_channel/secure_channel.dart';
import 'package:whowolf/src/net/discovery.dart';
import 'package:whowolf/src/net/keep_alive.dart';
import 'package:whowolf/src/net/room_store.dart';

/// A room this device hosts: the game host with its LAN socket and, if a
/// relay server is configured and reachable, a room on the relay for remote
/// players. The host player's own app joins through [GameHost.connectOwner],
/// like anyone else.
class HostedRoom {
  HostedRoom._(
    this.host,
    this._keys,
    this._hostName,
    this._lan,
    this._port,
    this._relay,
    this._link,
    this._announcer, {
    required this.relayFailed,
    required this.keptAlive,
  });

  /// Opens a room on the local network and, with [relayServer], online.
  ///
  /// With [notice] (the notification text for a room code), Android keeps
  /// the room alive in the background with a foreground service.
  static Future<HostedRoom> open({
    required String hostName,
    Uri? relayServer,
    String Function(String room)? notice,
  }) {
    final random = Random.secure();
    final code = List.generate(
      roomCodeLength,
      (_) => random.nextInt(10),
    ).join();
    return _start(
      GameHost(roomCode: code, random: random),
      keys: null,
      hostName: hostName,
      relayServer: relayServer,
      notice: notice,
    );
  }

  /// Brings back a room from its saved snapshot after the host app crashed
  /// or was closed. The players' apps reconnect by themselves.
  static Future<HostedRoom> restore(
    SavedRoom saved, {
    required String hostName,
    Uri? relayServer,
    String Function(String room)? notice,
  }) async {
    final keys = await HostKeys.fromJson(saved.keys);
    return _start(
      GameHost.restore(
        saved.snapshot,
        random: Random.secure(),
        roomSecret: keys.roomSecret,
      ),
      keys: keys,
      hostName: hostName,
      relayServer: relayServer,
      notice: notice,
    );
  }

  static Future<HostedRoom> _start(
    GameHost host, {
    required HostKeys? keys,
    required String hostName,
    Uri? relayServer,
    String Function(String room)? notice,
  }) async {
    final code = host.roomCode;
    // Every remote connection is end-to-end encrypted; the QR code carries
    // the key and secret that prove this host to the players.
    final roomKeys = keys ?? await HostKeys.generate();
    final keysJson = await roomKeys.toJson();
    // The default port first: players who lost the host reconnect to it.
    final lan = await LanTransport.bind();
    host.serve(SecureTransport(lan, roomKeys));
    const store = RoomStore();
    host.onSnapshot = (snapshot) =>
        unawaited(store.save(SavedRoom(snapshot, keysJson)));
    RelayTransport? relay;
    if (relayServer != null) {
      try {
        relay = await RelayTransport.open(relayServer);
        host.serve(SecureTransport(relay, roomKeys));
      } on Object {
        relay = null;
      }
    }
    // Others see the room under "Join a room" without typing anything.
    final announcer = RoomAnnouncer();
    await announcer.start(
      hostName: hostName,
      room: code,
      port: lan.port,
      hostKey: roomKeys.publicKey,
    );
    final keptAlive =
        notice != null &&
        await KeepAlive.start(title: 'Whowolf', text: notice(code));
    return HostedRoom._(
      host,
      roomKeys,
      hostName,
      lan,
      lan.port,
      relay,
      await _linkFor(code, roomKeys, lan, relay),
      announcer,
      relayFailed: relayServer != null && relay == null,
      keptAlive: keptAlive,
    );
  }

  static Future<JoinLink> _linkFor(
    String code,
    HostKeys keys,
    LanTransport lan,
    RelayTransport? relay,
  ) async {
    final addresses = await privateAddresses();
    final ip = addresses.isEmpty ? null : addresses.first.address;
    return JoinLink(
      room: code,
      lan: ip == null ? null : LanAddress(ip, lan.port),
      relayRoom: relay?.roomId,
      server: relay?.server,
      hostKey: keys.publicKey,
      roomSecret: keys.roomSecret,
    );
  }

  final GameHost host;
  final HostKeys _keys;
  final String _hostName;
  final RelayTransport? _relay;
  LanTransport _lan;

  /// The port the players know; a dead server no longer reports it.
  int _port;
  JoinLink _link;
  RoomAnnouncer _announcer;
  Future<void>? _reviving;
  bool _closed = false;

  /// How to reach this room; shown as text and as QR code. May change
  /// after [revive] (new port or Wi-Fi address).
  JoinLink get link => _link;

  /// A relay server was configured but could not be reached.
  final bool relayFailed;

  /// A foreground service keeps the room alive in the background (Android).
  /// Elsewhere the host must keep the app open.
  final bool keptAlive;

  String get roomCode => host.roomCode;

  /// Hosts again after the app was in the background: iOS suspends the app
  /// and its server socket dies with it. Binds a fresh LAN socket (the same
  /// port if possible, so players find the host where they left it) and
  /// announces the room again where needed. Players still connected keep their
  /// connection; the others reconnect by themselves.
  ///
  /// Safe to call at any time and repeatedly: calls during a revive join it.
  Future<void> revive() => _reviving ??= _revive().whenComplete(
    () => _reviving = null,
  );

  Future<void> _revive() async {
    if (_closed) return;
    try {
      // Frees the port; the host ignores the closed transport from now on.
      await _lan.close();
    } on Object {
      // The socket was already dead.
    }
    final lan = await LanTransport.bind(port: _port);
    if (_closed) {
      await lan.close();
      return;
    }
    final moved = lan.port != _port;
    _lan = lan;
    _port = lan.port;
    host.serve(SecureTransport(lan, _keys));
    _link = await _linkFor(roomCode, _keys, lan, _relay);
    // iOS withdraws a suspended app's Bonjour announcement; elsewhere it
    // survives, and announcing the same name again right away can leave a
    // stale twin in other devices' caches (seen on Android).
    if (!moved && defaultTargetPlatform != TargetPlatform.iOS) return;
    await _announcer.stop();
    final announcer = RoomAnnouncer();
    await announcer.start(
      hostName: _hostName,
      room: roomCode,
      port: lan.port,
      hostKey: _keys.publicKey,
    );
    _announcer = announcer;
    // Closed while announcing: close() already stopped the old announcer.
    if (_closed) await announcer.stop();
  }

  Future<void> close() async {
    _closed = true;
    try {
      await _reviving;
    } on Object {
      // A failed revive leaves nothing to clean up but the rest.
    }
    await _announcer.stop();
    await host.close();
    await KeepAlive.stop();
    await const RoomStore().clear();
  }
}
