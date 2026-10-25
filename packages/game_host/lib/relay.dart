/// Relay transport: the host keeps one outgoing WebSocket to a relay server,
/// which forwards remote players. Works behind any router. Uses `dart:io`.
///
/// Not end-to-end encrypted yet: the relay could read the game messages.
/// The Noise handshake (docs/SECURITY_DESIGN.md) closes this before release.
library;

import 'dart:async';
import 'dart:io';

import 'package:game_host/lan.dart';
import 'package:game_host/src/transport.dart';
import 'package:protocol/protocol.dart';

/// Players reached through a relay server, as one [Transport].
class RelayTransport implements Transport {
  RelayTransport._(this._socket, this.server) {
    _socket.listen(
      _receive,
      onDone: _shutDown,
      onError: (Object _) => _shutDown(),
      cancelOnError: true,
    );
  }

  /// Opens a room on [server] (a `ws://` or `wss://` origin).
  static Future<RelayTransport> open(
    Uri server, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final socket = await WebSocket.connect(
      server.replace(path: '/host').toString(),
    ).timeout(timeout);
    socket.pingInterval = const Duration(seconds: 10);
    final transport = RelayTransport._(socket, server);
    try {
      await transport._opened.future.timeout(timeout);
    } on Object {
      await transport.close();
      rethrow;
    }
    return transport;
  }

  final WebSocket _socket;

  /// The relay server.
  final Uri server;

  final _opened = Completer<void>();

  /// The room id players use on the relay.
  late final String roomId;

  final _incoming = StreamController<Connection>();
  final _peers = <int, _RelayPeer>{};

  @override
  Stream<Connection> get connections => _incoming.stream;

  void _receive(Object? data) {
    if (data is! String) return;
    final RelayFrame frame;
    try {
      frame = RelayFrame.parse(data);
    } on ProtocolError {
      return;
    }
    switch (frame) {
      case PeerJoined(:final peer):
        final connection = _RelayPeer(this, peer);
        _peers[peer] = connection;
        _incoming.add(connection);
      case PeerData(:final peer, :final data):
        _peers[peer]?._in.add(data);
      case PeerLeft(:final peer):
        _peers.remove(peer)?._ended();
      case RoomOpened(:final roomId):
        if (_opened.isCompleted) return;
        this.roomId = roomId;
        _opened.complete();
    }
  }

  void _send(RelayFrame frame) {
    if (_socket.readyState == WebSocket.open) _socket.add(frame.encode());
  }

  void _shutDown() {
    if (!_opened.isCompleted) {
      _opened.completeError(const ProtocolError('relay closed'));
    }
    for (final peer in [..._peers.values]) {
      peer._ended();
    }
    _peers.clear();
    if (!_incoming.isClosed) unawaited(_incoming.close());
  }

  @override
  Future<void> close() async {
    await _socket.close();
    _shutDown();
  }
}

class _RelayPeer implements Connection {
  _RelayPeer(this._relay, this._id);

  final RelayTransport _relay;
  final int _id;
  final _in = StreamController<String>();
  bool _closed = false;

  @override
  Stream<String> get messages => _in.stream;

  @override
  void send(String message) {
    if (!_closed) _relay._send(PeerData(_id, message));
  }

  void _ended() {
    if (_closed) return;
    _closed = true;
    unawaited(_in.close());
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _relay
      .._send(PeerLeft(_id))
      .._peers.remove(_id);
    _ended();
  }
}

/// Connects a player to a host's room on a relay [server].
Future<Connection> dialRelay(
  Uri server,
  String roomId, {
  Duration timeout = const Duration(seconds: 8),
}) async {
  if (!isRelayRoomId(roomId)) throw ArgumentError.value(roomId, 'roomId');
  final socket = await WebSocket.connect(
    server.replace(path: '/join/$roomId').toString(),
  ).timeout(timeout);
  socket.pingInterval = const Duration(seconds: 10);
  return WebSocketConnection(socket);
}
