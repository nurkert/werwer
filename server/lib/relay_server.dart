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
    this.maxDoorLookupsPerMinute = 10,
    this.doorLifetime = const Duration(minutes: 7),
    this.minDoorInterval = const Duration(seconds: 60),
  });

  /// Most door codes one address may try per minute on the code page
  /// (`/c`), right or wrong: guessing one of a few hundred live codes among
  /// 887 million takes years. 0 turns it off.
  final int maxDoorLookupsPerMinute;

  /// How long a door code works after the host got it. Hosts ask for a new
  /// one every few minutes; the previous one keeps working until its time
  /// is up, so a code read a moment ago still opens the door.
  final Duration doorLifetime;

  /// A host asking for door codes faster than this is not answered.
  final Duration minDoorInterval;

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

  /// This room's door codes, oldest first (at most two).
  final doors = <String>[];

  /// When the host last got a door code (relay clock, ms); `null` if never.
  int? lastDoor;
}

/// Where a door code leads: a room's page on this server.
class _Door {
  _Door(this.room, this.roomCode, this.protocol, this.build, this.until);

  final _Room room;
  final String roomCode;
  final int protocol;
  final String build;

  /// Until when it works (relay clock, ms).
  final int until;
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

  /// Live door codes; they die with their room.
  final _doors = <String, _Door>{};

  /// Recent door code tries per address.
  final _lookups = <String, List<int>>{};

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

  /// Door codes held right now (expired ones may linger until looked up or
  /// until their room asks again).
  int get doorCount => _doors.length;

  /// Whether this server hands out door codes: only with a web app, where
  /// the code page can send people.
  bool get _hasDoors => webApps.builds.isNotEmpty;

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
    if (!upgrade && _hasDoors && (path == '/' || path == '/c')) {
      return _doorPage(request, path == '/c');
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

  /// The code page (`/`) and its answer (`/c?code=…`): a typed door code
  /// leads to its room's page, without the room's keys (see [DoorAsked]).
  /// Nothing from the request is echoed or logged; every try counts
  /// against its address.
  Future<void> _doorPage(HttpRequest request, bool lookup) async {
    final response = request.response;
    final german =
        (request.headers[HttpHeaders.acceptLanguageHeader]?.join(',') ?? '')
            .trim()
            .toLowerCase()
            .startsWith('de');
    final method = request.method;
    if (method != 'GET' && method != 'HEAD') {
      response.statusCode = HttpStatus.methodNotAllowed;
      await response.close();
      return;
    }
    var note = _DoorNote.none;
    if (lookup) {
      if (!_mayLookUp(_clientAddress(request))) {
        note = _DoorNote.tooMany;
      } else {
        final code = normalizeDoorCode(
          request.uri.queryParameters['code'] ?? '',
        );
        final door = code == null ? null : _doors[code];
        final now = _clock.elapsedMilliseconds;
        if (door != null && door.until <= now) _doors.remove(code);
        if (door == null || door.until <= now || !_mayJoin(door.room)) {
          note = _DoorNote.unknown;
        } else if (!webApps.builds.contains(
          '${door.protocol}/${door.build}',
        )) {
          note = _DoorNote.version;
        } else {
          response
            ..statusCode = HttpStatus.seeOther
            ..headers.set(HttpHeaders.cacheControlHeader, 'no-store')
            ..headers.set('Referrer-Policy', 'no-referrer')
            ..headers.set(
              HttpHeaders.locationHeader,
              Uri(
                path: '/v/${door.protocol}/${door.build}/join',
                queryParameters: {
                  'room': door.roomCode,
                  'relay': door.room.id,
                },
              ).toString(),
            );
          await response.close();
          return;
        }
      }
    }
    response
      ..statusCode = switch (note) {
        _DoorNote.none => HttpStatus.ok,
        _DoorNote.tooMany => HttpStatus.tooManyRequests,
        _DoorNote.unknown || _DoorNote.version => HttpStatus.notFound,
      }
      ..headers.contentType = ContentType.html
      ..headers.set(HttpHeaders.cacheControlHeader, 'no-store')
      ..headers.set('X-Content-Type-Options', 'nosniff')
      ..headers.set('X-Frame-Options', 'DENY')
      ..headers.set('Referrer-Policy', 'no-referrer')
      ..headers.set(
        'Content-Security-Policy',
        "default-src 'none'; style-src 'unsafe-inline'; "
            "frame-ancestors 'none'; base-uri 'none'; form-action 'self'",
      );
    final body = utf8.encode(_doorHtml(german: german, note: note));
    response.contentLength = body.length;
    if (method == 'GET') response.add(body);
    await response.close();
  }

  /// One more door code try for [address], within its rate.
  bool _mayLookUp(String? address) {
    final perMinute = config.maxDoorLookupsPerMinute;
    if (perMinute <= 0) return true;
    final now = _clock.elapsedMilliseconds;
    if (_lookups.length > 10000) {
      _lookups.removeWhere((_, at) => at.isEmpty || now - at.last > 60000);
    }
    final recent = _lookups.putIfAbsent(address ?? '', () => [])
      ..removeWhere((at) => now - at > 60000);
    if (recent.length >= perMinute) return false;
    recent.add(now);
    return true;
  }

  /// Gives [room] a fresh door code for [ask], unless it asked too soon.
  void _openDoor(_Room room, DoorAsked ask) {
    final now = _clock.elapsedMilliseconds;
    final last = room.lastDoor;
    if (!_hasDoors ||
        (last != null && now - last < config.minDoorInterval.inMilliseconds)) {
      return;
    }
    room.lastDoor = now;
    String code;
    do {
      code = String.fromCharCodes([
        for (var i = 0; i < doorCodeLength; i++)
          relayAlphabet.codeUnitAt(_random.nextInt(relayAlphabet.length)),
      ]);
    } while (_doors.containsKey(code));
    final lifetime = config.doorLifetime;
    _doors[code] = _Door(
      room,
      ask.room,
      ask.protocol,
      ask.build,
      now + lifetime.inMilliseconds,
    );
    room.doors.add(code);
    // The previous code keeps working until its time is up; older ones go.
    while (room.doors.length > 2) {
      _doors.remove(room.doors.removeAt(0));
    }
    room.host.send(DoorOpened(code, lifetime: lifetime).encode());
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
    host.send(RoomOpened(room.id, doors: _hasDoors).encode());
    final meter = _Meter(config.maxMessagesPerSecond * config.maxPeersPerRoom);
    void end() {
      if (_rooms[room.id] != room) return;
      _rooms.remove(room.id);
      // A closed room's codes open nothing.
      room.doors.forEach(_doors.remove);
      room.doors.clear();
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
          case final DoorAsked ask:
            _openDoor(room, ask);
          case RoomOpened() || PeerJoined() || DoorOpened():
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

/// What the code page says above its form.
enum _DoorNote { none, unknown, version, tooMany }

/// The code page: one field, no script, nothing from the request in it.
String _doorHtml({required bool german, required _DoorNote note}) {
  final t = german
      ? (
          lang: 'de',
          title: 'Mitspielen mit Code',
          lead:
              'Gib den Code ein, den die Einladung am Tisch zeigt. '
              'Du spielst dann direkt hier im Browser mit.',
          label: 'Code',
          button: 'Weiter',
          hint:
              'Danach vergleicht ihr ein paar Symbole: Die Spielleitung '
              'lässt dich herein, wenn sie auf beiden Bildschirmen gleich '
              'sind.',
          unknown:
              'Diesen Code kennen wir nicht, oder er ist abgelaufen. '
              'Er wechselt alle paar Minuten: Schau noch einmal auf die '
              'Einladung.',
          version:
              'Diese Runde läuft mit einer App-Version, die es hier im '
              'Browser noch nicht gibt. Spielt mit der Whowolf-App, oder '
              'versucht es in ein paar Minuten noch einmal.',
          tooMany:
              'Zu viele Versuche. Warte eine Minute und versuche es dann '
              'noch einmal.',
          app: 'Lieber mit der App? whowolf.de',
        )
      : (
          lang: 'en',
          title: 'Join with a code',
          lead:
              'Enter the code the invitation at the table shows. You will '
              'play right here in your browser.',
          label: 'Code',
          button: 'Continue',
          hint:
              'Then you compare a few symbols: the game leader lets you in '
              'when both screens show the same ones.',
          unknown:
              'We do not know this code, or it has expired. It changes every '
              'few minutes: look at the invitation again.',
          version:
              'This game runs an app version this browser page does not have '
              'yet. Play with the Whowolf app, or try again in a few minutes.',
          tooMany: 'Too many tries. Wait a minute, then try again.',
          app: 'Rather use the app? whowolf.de',
        );
  final message = switch (note) {
    _DoorNote.none => null,
    _DoorNote.unknown => t.unknown,
    _DoorNote.version => t.version,
    _DoorNote.tooMany => t.tooMany,
  };
  return '''
<!DOCTYPE html>
<html lang="${t.lang}"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>Whowolf – ${t.title}</title>
<style>
*{box-sizing:border-box}
body{margin:0;min-height:100vh;display:grid;place-items:center;padding:24px 16px;
font:17px/1.5 system-ui,-apple-system,"Segoe UI",sans-serif;color:#F4EEDC;
background:radial-gradient(ellipse at 50% -10%,#2B3C5A 0%,#141A33 55%,#0B0F22 100%)}
main{width:100%;max-width:26rem;text-align:center}
.moon{width:72px;height:72px;margin:0 auto 20px;border-radius:50%;
background:radial-gradient(circle at 38% 36%,#FFF6DA,#F2D58C 55%,#C99A45);
box-shadow:0 0 40px 8px rgba(242,181,68,.35)}
h1{margin:0;font:700 clamp(1.8rem,7vw,2.3rem)/1.15 Georgia,"Times New Roman",serif}
p{margin:.8em auto 0;color:#D9D0B8}
form{margin-top:28px;display:grid;gap:14px}
label{font-size:.8rem;font-weight:700;letter-spacing:.12em;text-transform:uppercase;color:#F2B544}
input{width:100%;min-height:64px;padding:8px 12px;border:2px solid #6E5A35;border-radius:16px;
background:#0E1426;color:#FFF6DA;text-align:center;font:700 2rem/1 ui-monospace,Menlo,monospace;
letter-spacing:.3em;text-transform:uppercase}
input:focus{outline:3px solid #F2B544;outline-offset:2px;border-color:#F2B544}
button{min-height:52px;border:0;border-radius:999px;background:#F2B544;color:#1C1408;
font:700 1.1rem/1 system-ui,sans-serif;cursor:pointer}
button:hover{background:#FFC864}
button:focus-visible{outline:3px solid #FFF6DA;outline-offset:3px}
.note{margin-top:22px;padding:12px 16px;border-radius:14px;background:rgba(201,74,58,.18);
border:1px solid rgba(232,120,98,.55);color:#FFE3D6}
.hint{font-size:.9rem;color:#B9B09A}
a{color:#F2B544}
</style></head><body><main>
<div class="moon" aria-hidden="true"></div>
<h1>${t.title}</h1>
<p>${t.lead}</p>
${message == null ? '' : '<p class="note" role="alert">$message</p>'}
<form method="get" action="/c">
<label for="code">${t.label}</label>
<input id="code" name="code" required maxlength="9" autocomplete="off"
autocapitalize="characters" autocorrect="off" spellcheck="false" autofocus
placeholder="ABC 234">
<button type="submit">${t.button}</button>
</form>
<p class="hint">${t.hint}</p>
<p class="hint"><a href="https://whowolf.de">${t.app}</a></p>
</main></body></html>
''';
}
