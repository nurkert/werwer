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
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:protocol/protocol.dart';

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
}

/// How many bytes a connection may send: a bucket that fills up at [rate]
/// bytes per second up to [burst]. A connection that sends more is cut off
/// at once, before a large frame is even complete, so no message can grow
/// beyond [burst] in the server's memory (`dart:io` would otherwise
/// buffer a whole WebSocket message of any size).
class ByteBudget {
  /// Creates a budget.
  const ByteBudget({required this.burst, required this.rate});

  /// What a player may send: their messages are a few hundred bytes.
  static const player = ByteBudget(burst: 256 * 1024, rate: 64 * 1024);

  /// What a host may send: every view to every player.
  static const host = ByteBudget(burst: 4 << 20, rate: 1 << 20);

  /// Most bytes at once.
  final int burst;

  /// Bytes per second over time.
  final int rate;
}

class _Bucket {
  _Bucket(this.budget) : _tokens = budget.burst.toDouble();

  final ByteBudget budget;
  final _watch = Stopwatch()..start();
  double _tokens;

  bool spend(int bytes) {
    final elapsed = _watch.elapsedMicroseconds;
    _watch.reset();
    _tokens = min(
      budget.burst.toDouble(),
      _tokens + elapsed * budget.rate / 1e6,
    );
    _tokens -= bytes;
    return _tokens >= 0;
  }
}

class _Room {
  _Room(this.id, this.host, this.address);

  final String id;
  final WebSocket host;

  /// Where the host connected from.
  final String? address;
  final peers = <int, WebSocket>{};
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
  RelayServer._(this._server, this.config, this._random);

  /// Starts listening on [address]:[port].
  static Future<RelayServer> start({
    Object address = '0.0.0.0',
    int port = 8080,
    RelayConfig config = const RelayConfig(),
    Random? random,
  }) async {
    final server = await HttpServer.bind(address, port);
    server
      ..idleTimeout = const Duration(seconds: 30)
      ..serverHeader = null;
    final relay = RelayServer._(server, config, random ?? Random.secure());
    server.listen(relay._handle, onError: (Object _) {});
    return relay;
  }

  final HttpServer _server;
  final RelayConfig config;
  final Random _random;
  final _rooms = <String, _Room>{};

  /// Open sockets per address, and when each address last upgraded.
  final _open = <String, int>{};
  int _openTotal = 0;
  final _upgrades = <String, List<int>>{};
  final _clock = Stopwatch()..start();

  /// Byte budgets; replaceable in tests.
  ByteBudget hostBudget = ByteBudget.host;
  ByteBudget playerBudget = ByteBudget.player;

  int get port => _server.port;

  /// Open sockets right now (hosts and players).
  int get connectionCount => _openTotal;

  int get roomCount => _rooms.length;

  Future<void> close() async {
    for (final room in [..._rooms.values]) {
      await room.host.close();
    }
    await _server.close(force: true);
  }

  Future<void> _handle(HttpRequest request) async {
    final path = request.uri.path;
    if (path == '/health') {
      request.response
        ..statusCode = HttpStatus.ok
        ..write('ok');
      await request.response.close();
      return;
    }
    final joinMatch = RegExp(r'^/join/([a-z0-9]+)$').firstMatch(path);
    final isHost = path == '/host';
    if ((!isHost && joinMatch == null) ||
        !WebSocketTransformer.isUpgradeRequest(request)) {
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
    final WebSocket socket;
    try {
      socket = await _upgrade(request, isHost ? hostBudget : playerBudget);
    } on Object {
      return;
    }
    _count(address, 1);
    unawaited(socket.done.whenComplete(() => _count(address, -1)));
    socket.pingInterval = const Duration(seconds: 10);
    // The upgrade took a moment: other requests may have opened rooms or the
    // room may be gone by now, so the limits are checked again before the
    // socket counts.
    if (isHost ? !_mayOpenRoom(address) : !_mayJoin(room!)) {
      unawaited(socket.close());
      return;
    }
    if (isHost) {
      _openRoom(socket, address);
    } else {
      _joinRoom(room!, socket);
    }
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

  /// The WebSocket handshake by hand (RFC 6455, section 4.2.2), so the raw
  /// socket can be metered byte by byte before `dart:io` assembles frames.
  /// No compression: the payloads are ciphertext, and inflating an
  /// attacker's frame could turn one small message into gigabytes.
  static Future<WebSocket> _upgrade(
    HttpRequest request,
    ByteBudget budget,
  ) async {
    final key = request.headers.value('sec-websocket-key');
    if (key == null || key.length > 64) throw const FormatException('no key');
    final accept = base64.encode(
      sha1
          .convert(
            ascii.encode('${key.trim()}258EAFA5-E914-47DA-95CA-C5AB0DC85B11'),
          )
          .bytes,
    );
    request.response
      ..statusCode = HttpStatus.switchingProtocols
      ..headers.set(HttpHeaders.connectionHeader, 'Upgrade')
      ..headers.set(HttpHeaders.upgradeHeader, 'websocket')
      ..headers.set('Sec-WebSocket-Accept', accept);
    final raw = await request.response.detachSocket();
    return WebSocket.fromUpgradedSocket(
      _MeteredSocket(raw, _Bucket(budget)),
      serverSide: true,
      compression: CompressionOptions.compressionOff,
    );
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
      room.host.readyState == WebSocket.open &&
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

  void _openRoom(WebSocket host, String? address) {
    final room = _Room(_newRoomId(), host, address);
    _rooms[room.id] = room;
    host.add(RoomOpened(room.id).encode());
    final meter = _Meter(config.maxMessagesPerSecond * config.maxPeersPerRoom);
    void end() {
      if (_rooms[room.id] != room) return;
      _rooms.remove(room.id);
      for (final peer in room.peers.values) {
        unawaited(peer.close());
      }
      room.peers.clear();
      unawaited(host.close());
    }

    host.listen(
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
            final socket = room.peers[peer];
            if (socket != null && socket.readyState == WebSocket.open) {
              socket.add(data);
            }
          case PeerLeft(:final peer):
            unawaited(room.peers.remove(peer)?.close());
          case RoomOpened() || PeerJoined():
            end();
        }
      },
      onDone: end,
      onError: (Object _) => end(),
      cancelOnError: true,
    );
  }

  void _joinRoom(_Room room, WebSocket peer) {
    final id = room.nextPeer++;
    room.peers[id] = peer;
    if (room.host.readyState == WebSocket.open) {
      room.host.add(PeerJoined(id).encode());
    }
    final meter = _Meter(config.maxMessagesPerSecond);
    void leave() {
      if (room.peers.remove(id) != null &&
          room.host.readyState == WebSocket.open) {
        room.host.add(PeerLeft(id).encode());
      }
      unawaited(peer.close());
    }

    peer.listen(
      (data) {
        if (data is! String || data.length > maxClientMessage || meter.tick()) {
          return leave();
        }
        if (room.host.readyState == WebSocket.open) {
          room.host.add(PeerData(id, data).encode());
        }
      },
      onDone: leave,
      onError: (Object _) => leave(),
      cancelOnError: true,
    );
  }
}

/// A socket whose incoming bytes are counted against a budget; one that
/// sends too much is destroyed on the spot.
class _MeteredSocket extends Stream<Uint8List> implements Socket {
  _MeteredSocket(this._inner, this._bucket);

  final Socket _inner;
  final _Bucket _bucket;

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _inner
      .where((chunk) {
        if (_bucket.spend(chunk.length)) return true;
        _inner.destroy();
        return false;
      })
      .listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );

  @override
  Encoding get encoding => _inner.encoding;

  @override
  set encoding(Encoding value) => _inner.encoding = value;

  @override
  InternetAddress get address => _inner.address;

  @override
  InternetAddress get remoteAddress => _inner.remoteAddress;

  @override
  int get port => _inner.port;

  @override
  int get remotePort => _inner.remotePort;

  @override
  bool setOption(SocketOption option, bool enabled) =>
      _inner.setOption(option, enabled);

  @override
  Uint8List getRawOption(RawSocketOption option) => _inner.getRawOption(option);

  @override
  void setRawOption(RawSocketOption option) => _inner.setRawOption(option);

  @override
  void add(List<int> data) => _inner.add(data);

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _inner.addError(error, stackTrace);

  @override
  Future<void> addStream(Stream<List<int>> stream) => _inner.addStream(stream);

  @override
  Future<void> close() => _inner.close();

  @override
  Future<void> get done => _inner.done;

  @override
  Future<void> flush() => _inner.flush();

  @override
  void write(Object? object) => _inner.write(object);

  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) =>
      _inner.writeAll(objects, separator);

  @override
  void writeCharCode(int charCode) => _inner.writeCharCode(charCode);

  @override
  void writeln([Object? object = '']) => _inner.writeln(object);

  @override
  void destroy() => _inner.destroy();
}
