import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:game_core/game_core.dart' show NarratorLanguage, PlayerId;
import 'package:game_host/game_host.dart';
import 'package:game_host/lan.dart';
import 'package:game_host/relay.dart';
import 'package:protocol/protocol.dart';
import 'package:secure_channel/secure_channel.dart';
import 'package:whowolf/src/net/discovery.dart';
import 'package:whowolf/src/net/invite_code.dart';
import 'package:whowolf/src/net/keep_alive.dart';
import 'package:whowolf/src/net/on_demand_relay.dart';
import 'package:whowolf/src/net/room_store.dart';
import 'package:whowolf/src/net/web_app.dart';

/// A room this device hosts: the game host with its LAN socket and, if a
/// relay server is configured and reachable, a room on the relay for remote
/// players. By default the relay room only opens when the host shows the
/// QR code ([goOnline]) or has no Wi-Fi, so the server learns nothing of
/// games that stay on the local network. The host player's own app joins
/// through [GameHost.connectOwner], like anyone else.
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
    required this._relayServer,
    required this._relayGate,
    required this._webAppBuild,
    required this._serverHasBuild,
  });

  /// Opens a room on the local network and, with [relayServer], online.
  ///
  /// With [notice] (the notification text for a room code), Android keeps
  /// the room alive in the background with a foreground service.
  ///
  /// With [online] the room opens on the relay right away; otherwise only
  /// without Wi-Fi or on [goOnline]. [serveWebApp] gives browsers on the
  /// same Wi-Fi the web app; [webAppBuild] is this app's build, whose page
  /// a relay that serves the web app has under `/v/<protocol>/<build>/`.
  static Future<HostedRoom> open({
    required String hostName,
    Uri? relayServer,
    String Function(String room)? notice,
    NarratorLanguage language = NarratorLanguage.de,
    bool online = true,
    bool serveWebApp = true,
    String? webAppBuild,
  }) async {
    final random = Random.secure();
    final code = List.generate(
      roomCodeLength,
      (_) => random.nextInt(10),
    ).join();
    // The keys first: the host hands the room secret to players it lets in
    // without the QR code, so they can come back after a dropped
    // connection like everyone else.
    final keys = await HostKeys.generate();
    return _start(
      GameHost(
        roomCode: code,
        random: random,
        roomSecret: keys.roomSecret,
        // The narrator speaks the host's language to the whole table.
        settings: GameHost.defaultSettings.copyWith(narratorLanguage: language),
      ),
      keys: keys,
      hostName: hostName,
      relayServer: relayServer,
      notice: notice,
      online: online,
      serveWebApp: serveWebApp,
      webAppBuild: webAppBuild,
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

  /// This device takes over [room] (the successor's opened copy: snapshot
  /// and room keys) from a host that went away. Same code, same keys, so
  /// the players' apps find it by themselves; [newOwner] (this device's
  /// player) runs the table from now on.
  static Future<HostedRoom> takeOver(
    String room, {
    required PlayerId newOwner,
    required String hostName,
    Uri? relayServer,
    String Function(String room)? notice,
  }) async {
    final json = jsonDecode(room) as Map<String, Object?>;
    final keys = await HostKeys.fromJson(
      json['keys']! as Map<String, Object?>,
    );
    return _start(
      GameHost.restore(
        json['snapshot']! as String,
        random: Random.secure(),
        roomSecret: keys.roomSecret,
        takeOver: true,
        newOwner: newOwner,
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
    bool online = true,
    bool serveWebApp = true,
    String? webAppBuild,
  }) async {
    final code = host.roomCode;
    // Every remote connection is end-to-end encrypted; the QR code carries
    // the key and secret that prove this host to the players.
    final roomKeys = keys ?? await HostKeys.generate();
    final keysJson = await roomKeys.toJson();
    // The default port first: players who lost the host reconnect to it.
    // With the web app in this build, phones without the app join in the
    // browser from the same address.
    final site = serveWebApp ? await bundledWebApp() : null;
    final lan = await LanTransport.bind(site: site);
    host.serve(SecureTransport(lan, roomKeys));
    const store = RoomStore();
    final sealer = SodiumSealer(await loadSodium());
    // A successor gets the whole room, sealed; only the witness's key opens
    // it.
    final custody = CustodyConfig(
      sealer: sealer,
      room: (snapshot) => jsonEncode({'snapshot': snapshot, 'keys': keysJson}),
    );
    host
      ..custody = custody
      ..onSnapshot = (snapshot) {
        unawaited(store.save(SavedRoom(snapshot, keysJson)));
      };
    // Without Wi-Fi nobody can reach this room but through the server.
    final offline = (await privateAddresses()).isEmpty;
    final gate = OnDemandRelay<RelayTransport>(
      () async =>
          relayServer == null ? null : _openRelay(relayServer, host, roomKeys),
    );
    final relay = OnDemandRelay.rightAway(always: online, offline: offline)
        ? await gate.open()
        : null;
    // Others see the room under "Join a room" without typing anything.
    final announcer = RoomAnnouncer();
    await announcer.start(
      hostName: hostName,
      room: code,
      port: lan.port,
      hostKey: roomKeys.publicKey,
      epoch: host.epoch,
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
      relayFailed:
          relayServer != null &&
          OnDemandRelay.rightAway(always: online, offline: offline) &&
          relay == null,
      keptAlive: keptAlive,
      relayServer: relayServer,
      relayGate: gate,
      webAppBuild: webAppBuild,
      serverHasBuild: relay != null && await _serves(relayServer!, webAppBuild),
    ).._webApp = site;
  }

  static Future<RelayTransport?> _openRelay(
    Uri server,
    GameHost host,
    HostKeys keys,
  ) async {
    try {
      final relay = await RelayTransport.open(server);
      host.serve(SecureTransport(relay, keys));
      return relay;
    } on Object {
      return null;
    }
  }

  /// Whether the relay [server] has the web app page of [build] for
  /// browsers that join over the internet.
  static Future<bool> _serves(Uri server, String? build) async {
    if (build == null || server.scheme != 'wss' || !isWebAppBuild(build)) {
      return false;
    }
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
    try {
      final request = await client.headUrl(
        Uri(
          scheme: 'https',
          host: server.host,
          port: server.hasPort ? server.port : null,
          path: '/v/$protocolVersion/$build/join',
        ),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 4),
      );
      await response.drain<void>();
      return response.statusCode == HttpStatus.ok;
    } on Object {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  /// Opens this room on the online server too, because the host shows the
  /// QR code. Whether the room is online now.
  Future<bool> goOnline() async {
    if (_relay != null) return true;
    final server = _relayServer;
    if (server == null || _closed) return false;
    final relay = await _relayGate.open();
    relayFailed = relay == null;
    if (relay == null) return false;
    if (_closed) {
      await relay.close();
      return false;
    }
    if (_relay == relay) return true;
    _relay = relay;
    _link = await _linkFor(roomCode, _keys, _lan, relay);
    _serverHasBuild = await _serves(server, _webAppBuild);
    return true;
  }

  /// Whether the room is open on the online server.
  bool get online => _relay != null;

  /// Whether the room could go online (a server is set).
  bool get canGoOnline => _relayServer != null;

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
  final Uri? _relayServer;
  final OnDemandRelay<RelayTransport> _relayGate;
  final String? _webAppBuild;
  RelayTransport? _relay;
  bool _serverHasBuild;

  /// The host chose the Wi-Fi code: the QR code stays on the local page even
  /// when the server has the web app (a game without internet).
  bool localOnly = false;
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

  /// The web app this room serves to browsers, if this build has it.
  Site? get _site => _webApp;
  Site? _webApp;

  /// What the QR code says: the server's page for this build when the room
  /// is online and the server has it; else the host's own address when it
  /// serves the web app (a phone without the app opens it in the browser
  /// and joins); otherwise the usual link. The app reads all of them.
  String get qrText => inviteCode(
    _link,
    serverHasBuild: _serverHasBuild,
    servesWebApp: _webApp != null,
    localOnly: localOnly,
    build: _webAppBuild,
  );

  /// Whether a phone without the app can join with the QR code.
  bool get browserCanJoin => qrText != _link.encode();

  /// A relay server was configured but could not be reached.
  bool relayFailed;

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
    final lan = await LanTransport.bind(port: _port, site: _site);
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
      epoch: host.epoch,
    );
    _announcer = announcer;
    // Closed while announcing: close() already stopped the old announcer.
    if (_closed) await announcer.stop();
  }

  /// The host's public key (the players pin it).
  List<int> get hostKey => _keys.publicKey;

  /// The room secret from the QR code.
  List<int> get roomSecret => _keys.roomSecret;

  /// Leaves on purpose: another player takes over if one can (the game
  /// goes on without this device); otherwise the room closes for all.
  Future<void> leave() async {
    if (_closed) return;
    if (await host.handOver(leave: true)) {
      // A moment for the successor and the witness to read it.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await close(quietly: true);
    } else {
      await close();
    }
  }

  /// Closes the room. [quietly] skips the goodbye: the players look for the
  /// host again and find whoever took over.
  Future<void> close({bool quietly = false}) async {
    if (_closed && quietly) return;
    _closed = true;
    // A real close: the room is gone, also from this device's own search
    // at once (a quiet close hands it to a successor, who announces it
    // again).
    if (!quietly) RoomFinder.closed(_keys.publicKey);
    try {
      await _reviving;
    } on Object {
      // A failed revive leaves nothing to clean up but the rest.
    }
    await _announcer.stop();
    await host.close(quietly: quietly);
    await KeepAlive.stop();
    await const RoomStore().clear();
  }
}
