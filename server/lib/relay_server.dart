/// The relay: hosts keep one outgoing WebSocket open (`/host`), remote players
/// connect to `/join/<room>`, and the server forwards messages between them.
///
/// It knows no game rules and keeps no game state: only which connections
/// belong to which room, in memory. It never logs message contents.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:game_host/socket_guard.dart';
import 'package:protocol/protocol.dart';
import 'package:whowolf_server/web_apps.dart';

/// Limits of a relay server.
class RelayConfig {
  const RelayConfig({
    this.maxRooms = 200,
    this.maxRoomsPerAddress = 4,
    this.maxPeersPerRoom = maxRelayPeers,
    this.maxMessagesPerSecond = 30,
    this.maxConnections = 2000,
    this.maxConnectionsPerAddress = 32,
    this.maxUpgradesPerMinute = 60,
    this.trustProxy = false,
    this.maxRequestsPerMinute = 600,
    this.publicHost,
    this.appleAppId,
    this.androidCertSha256,
  });

  /// Most rooms open at once.
  final int maxRooms;

  /// Most rooms one network address may hold open, so one client cannot
  /// take them all. 0 turns the limit off (behind a reverse proxy every
  /// request comes from the proxy's address).
  final int maxRoomsPerAddress;

  /// Most players per room.
  final int maxPeersPerRoom;

  /// More messages than this per second from one connection end it.
  final int maxMessagesPerSecond;

  /// Most open sockets (hosts and players) at once.
  final int maxConnections;

  /// Most open sockets from one address. A table on one mobile network may
  /// share an address, so this is generous; it stops one machine from
  /// holding thousands. 0 turns it off.
  final int maxConnectionsPerAddress;

  /// Most new sockets one address may open per minute (this also makes
  /// guessing room ids hopeless). 0 turns it off.
  final int maxUpgradesPerMinute;

  /// Behind a reverse proxy that is the only way in (the relay's own port
  /// is not public): the client's address is the last entry of
  /// `X-Forwarded-For`, which the proxy sets. Never enable it otherwise,
  /// or anyone could claim any address.
  final bool trustProxy;

  /// Most plain HTTP requests (the web app's files) one address may make
  /// per minute. A page load is a few dozen files, most cached after the
  /// first time. 0 turns it off.
  final int maxRequestsPerMinute;

  /// The host name players reach this server under (`play.whowolf.de`):
  /// the web app's pages may open WebSockets to it. Without it they rely on
  /// `'self'`.
  final String? publicHost;

  /// `<team id>.<bundle id>` of the iOS app, so a QR code for this server
  /// opens the app where it is installed (Universal Links). Never in the
  /// repository; set on the server.
  final String? appleAppId;

  /// SHA-256 fingerprint of the Android app's signing key (`AA:BB:…`), for
  /// Android App Links.
  final List<String>? androidCertSha256;
}

/// What a player's connection may cost: messages of a few hundred bytes
/// in, filtered views out.
const playerSocketLimits = SocketLimits(
  burst: 256 * 1024,
  rate: 64 * 1024,
  maxMessage: 8 * 1024,
  maxBacklog: 256 * 1024,
);

/// What a host's connection may cost: every view to every player in,
/// small player messages out.
const hostSocketLimits = SocketLimits(
  burst: 4 << 20,
  rate: 1 << 20,
  maxMessage: 2 * maxHostMessage,
  maxBacklog: 256 * 1024,
);

class _Room {
  _Room(this.id, this.host, this.address);

  final String id;
  final GuardedWebSocket host;

  /// Where the host connected from.
  final String? address;
  final peers = <int, GuardedWebSocket>{};
  int nextPeer = 1;
}

/// Counts messages per second for one connection.
class _Meter {
  _Meter(this.limit);

  final int limit;
  final _watch = Stopwatch()..start();
  int _count = 0;

  bool tick() {
    if (_watch.elapsedMilliseconds >= 1000) {
      _watch.reset();
      _count = 0;
    }
    return ++_count > limit;
  }
}

class RelayServer {
  RelayServer._(this._server, this.config, this._random, this.webApps);

  /// Starts listening on [address]:[port].
  static Future<RelayServer> start({
    Object address = '0.0.0.0',
    int port = 8080,
    RelayConfig config = const RelayConfig(),
    Random? random,
    WebApps? webApps,
  }) async {
    final server = await HttpServer.bind(address, port);
    server
      ..idleTimeout = const Duration(seconds: 30)
      ..serverHeader = null;
    final relay = RelayServer._(
      server,
      config,
      random ?? Random.secure(),
      webApps ?? WebApps.none(),
    );
    // One bad request (a malformed header, a client gone mid-answer) must
    // never take the server down: every request runs inside its own guard.
    server.listen(
      (request) => unawaited(relay._guarded(request)),
      onError: (Object _) {},
    );
    return relay;
  }

  final HttpServer _server;
  final RelayConfig config;
  final Random _random;
  final _rooms = <String, _Room>{};

  /// The web app this relay serves (none by default).
  final WebApps webApps;

  /// Recent plain HTTP requests per address.
  final _requests = <String, List<int>>{};

  /// Open sockets per address, and when each address last upgraded.
  final _open = <String, int>{};
  int _openTotal = 0;
  final _upgrades = <String, List<int>>{};
  final _clock = Stopwatch()..start();

  /// What a connection may cost; replaceable in tests.
  SocketLimits hostLimits = hostSocketLimits;
  SocketLimits playerLimits = playerSocketLimits;

  int get port => _server.port;

  /// Open sockets right now (hosts and players).
  int get connectionCount => _openTotal;

  int get roomCount => _rooms.length;

  Future<void> close() async {
    for (final room in [..._rooms.values]) {
      await room.host.socket.close();
    }
    await _server.close(force: true);
  }

  Future<void> _guarded(HttpRequest request) async {
    try {
      await _handle(request);
    } on Object {
      // Nothing about the request is logged (it may carry a room).
      try {
        request.response.statusCode = HttpStatus.badRequest;
      } on Object {
        // Headers already sent.
      }
      try {
        await request.response.close();
      } on Object {
        // Already closed, or the socket was detached for a WebSocket.
      }
    }
  }

  Future<void> _handle(HttpRequest request) async {
    final path = request.uri.path;
    final upgrade = WebSocketTransformer.isUpgradeRequest(request);
    // Every plain request counts against its address, not only the files.
    if (!upgrade && !_mayRequest(_clientAddress(request))) {
      request.response.statusCode = HttpStatus.tooManyRequests;
      await request.response.close();
      return;
    }
    if (path == '/health') {
      request.response
        ..statusCode = HttpStatus.ok
        ..write('ok');
      await request.response.close();
      return;
    }
    if (WebApps.owns(path) || path.startsWith('/.well-known/')) {
      if (path.startsWith('/.well-known/')) return _wellKnown(request, path);
      final host = config.publicHost;
      return webApps.serve(request, host == null ? '' : 'wss://$host');
    }
    final joinMatch = RegExp(r'^/join/([a-z0-9]+)$').firstMatch(path);
    // Browsers always send an Origin with a WebSocket, the app never: no
    // web page, not even a foreign one, can open rooms from a visitor's
    // browser. Browsers only join.
    // (`headers.value` would throw on a repeated header: ask for the list.)
    final isHost = path == '/host' && request.headers['origin'] == null;
    if ((!isHost && joinMatch == null) || !upgrade) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    final address = _clientAddress(request);
    if (!_mayConnect(address)) {
      request.response.statusCode = HttpStatus.tooManyRequests;
      await request.response.close();
      return;
    }
    if (isHost && !_mayOpenRoom(address)) {
      request.response.statusCode = HttpStatus.serviceUnavailable;
      await request.response.close();
      return;
    }
    final room = joinMatch == null ? null : _rooms[joinMatch.group(1)];
    if (!isHost && (room == null || !_mayJoin(room))) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    final GuardedWebSocket socket;
    try {
      socket = await upgradeGuarded(
        request,
        isHost ? hostLimits : playerLimits,
        pingInterval: const Duration(seconds: 10),
      );
    } on Object {
      return;
    }
    _count(address, 1);
    unawaited(
      socket.socket.done
          .catchError((Object _) {})
          .whenComplete(() => _count(address, -1)),
    );
    // The upgrade took a moment: other requests may have opened rooms or the
    // room may be gone by now, so the limits are checked again before the
    // socket counts.
    if (isHost ? !_mayOpenRoom(address) : !_mayJoin(room!)) {
      unawaited(socket.socket.close().catchError((Object _) {}));
      return;
    }
    if (isHost) {
      _openRoom(socket, address);
    } else {
      _joinRoom(room!, socket);
    }
  }

  /// One more plain request for [address], within its rate.
  bool _mayRequest(String? address) {
    final perMinute = config.maxRequestsPerMinute;
    if (perMinute <= 0) return true;
    final now = _clock.elapsedMilliseconds;
    if (_requests.length > 10000) {
      _requests.removeWhere((_, at) => at.isEmpty || now - at.last > 60000);
    }
    final recent = _requests.putIfAbsent(address ?? '', () => [])
      ..removeWhere((at) => now - at > 60000);
    if (recent.length >= perMinute) return false;
    recent.add(now);
    return true;
  }

  /// The files that tie this server's QR codes to the app (Universal Links,
  /// App Links), built only from the server's own configuration, never
  /// from the request.
  Future<void> _wellKnown(HttpRequest request, String path) async {
    final response = request.response;
    final apple = config.appleAppId;
    final android = config.androidCertSha256;
    final body = switch (path) {
      '/.well-known/apple-app-site-association' when apple != null => {
        'applinks': {
          'details': [
            {
              'appIDs': [apple],
              'components': [
                {'/': '/v/*/*/join', 'comment': 'A room to join'},
              ],
            },
          ],
        },
      },
      '/.well-known/assetlinks.json' when android != null => [
        {
          'relation': ['delegate_permission/common.handle_all_urls'],
          'target': {
            'namespace': 'android_app',
            'package_name': 'de.whowolf.app',
            'sha256_cert_fingerprints': android,
          },
        },
      ],
      _ => null,
    };
    if (body == null || request.method != 'GET') {
      response.statusCode = HttpStatus.notFound;
    } else {
      response
        ..headers.contentType = ContentType.json
        ..headers.set('X-Content-Type-Options', 'nosniff')
        ..write(jsonEncode(body));
    }
    await response.close();
  }

  /// The client's address: the socket's, or behind a trusted proxy the
  /// one the proxy put last into `X-Forwarded-For`.
  String? _clientAddress(HttpRequest request) {
    final direct = request.connectionInfo?.remoteAddress.address;
    if (!config.trustProxy) return direct;
    final forwarded = request.headers['x-forwarded-for'];
    final last = forwarded?.last.split(',').last.trim();
    return last == null || last.isEmpty || last.length > 64 ? direct : last;
  }

  /// One more socket for [address]: within the totals and its rate.
  bool _mayConnect(String? address) {
    if (_openTotal >= config.maxConnections) return false;
    final key = address ?? '';
    final perAddress = config.maxConnectionsPerAddress;
    if (perAddress > 0 && (_open[key] ?? 0) >= perAddress) return false;
    final perMinute = config.maxUpgradesPerMinute;
    if (perMinute <= 0) return true;
    final now = _clock.elapsedMilliseconds;
    final recent = _upgrades.putIfAbsent(key, () => [])
      ..removeWhere((at) => now - at > 60000);
    if (recent.length >= perMinute) return false;
    recent.add(now);
    // Forget quiet addresses, so the table cannot grow without end.
    if (_upgrades.length > 10000) {
      _upgrades.removeWhere(
        (_, times) => times.every((at) => now - at > 60000),
      );
    }
    return true;
  }

  void _count(String? address, int delta) {
    final key = address ?? '';
    _openTotal += delta;
    final now = (_open[key] ?? 0) + delta;
    if (now <= 0) {
      _open.remove(key);
    } else {
      _open[key] = now;
    }
  }

  /// Room for one more room, overall and for [address].
  bool _mayOpenRoom(String? address) {
    final perAddress = config.maxRoomsPerAddress;
    return _rooms.length < config.maxRooms &&
        (perAddress <= 0 ||
            _rooms.values.where((r) => r.address == address).length <
                perAddress);
  }

  /// [room] is still open and has a free seat.
  bool _mayJoin(_Room room) =>
      _rooms[room.id] == room &&
      room.host.socket.readyState == WebSocket.open &&
      room.peers.length < config.maxPeersPerRoom;

  String _newRoomId() {
    while (true) {
      final id = String.fromCharCodes([
        for (var i = 0; i < relayRoomIdLength; i++)
          relayAlphabet.codeUnitAt(_random.nextInt(relayAlphabet.length)),
      ]);
      if (!_rooms.containsKey(id)) return id;
    }
  }

  void _openRoom(GuardedWebSocket host, String? address) {
    final room = _Room(_newRoomId(), host, address);
    _rooms[room.id] = room;
    host.send(RoomOpened(room.id).encode());
    final meter = _Meter(config.maxMessagesPerSecond * config.maxPeersPerRoom);
    void end() {
      if (_rooms[room.id] != room) return;
      _rooms.remove(room.id);
      for (final peer in room.peers.values) {
        unawaited(peer.socket.close().catchError((Object _) {}));
      }
      room.peers.clear();
      unawaited(host.socket.close().catchError((Object _) {}));
    }

    host.socket.listen(
      (data) {
        if (data is! String || meter.tick()) return end();
        final RelayFrame frame;
        try {
          frame = RelayFrame.parse(data);
        } on ProtocolError {
          return end();
        }
        switch (frame) {
          case PeerData(:final peer, :final data):
            // A player who stops reading is dropped by its guard, never
            // buffered without end.
            room.peers[peer]?.send(data);
          case PeerLeft(:final peer):
            unawaited(
              room.peers
                  .remove(peer)
                  ?.socket
                  .close()
                  .catchError(
                    (Object _) {},
                  ),
            );
          case RoomOpened() || PeerJoined():
            end();
        }
      },
      onDone: end,
      onError: (Object _) => end(),
      cancelOnError: true,
    );
  }

  void _joinRoom(_Room room, GuardedWebSocket peer) {
    final id = room.nextPeer++;
    room.peers[id] = peer;
    room.host.send(PeerJoined(id).encode());
    final meter = _Meter(config.maxMessagesPerSecond);
    void leave() {
      if (room.peers.remove(id) != null) {
        room.host.send(PeerLeft(id).encode());
      }
      unawaited(peer.socket.close().catchError((Object _) {}));
    }

    peer.socket.listen(
      (data) {
        if (data is! String || data.length > maxClientMessage || meter.tick()) {
          return leave();
        }
        room.host.send(PeerData(id, data).encode());
      },
      onDone: leave,
      onError: (Object _) => leave(),
      cancelOnError: true,
    );
  }
}
