/// The relay: hosts keep one outgoing WebSocket open (`/host`), remote players
/// connect to `/join/<room>`, and the server forwards messages between them.
///
/// It knows no game rules and keeps no game state: only which connections
/// belong to which room, in memory. It never logs message contents.
library;

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:protocol/protocol.dart';

/// Limits of a relay server.
class RelayConfig {
  const RelayConfig({
    this.maxRooms = 200,
    this.maxRoomsPerAddress = 4,
    this.maxPeersPerRoom = maxRelayPeers,
    this.maxMessagesPerSecond = 30,
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

  int get port => _server.port;

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
    final address = request.connectionInfo?.remoteAddress.address;
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
      // No compression: the payloads are ciphertext, and inflating an
      // attacker's frame could turn one small message into gigabytes.
      socket = await WebSocketTransformer.upgrade(
        request,
        compression: CompressionOptions.compressionOff,
      );
    } on Object {
      return;
    }
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
