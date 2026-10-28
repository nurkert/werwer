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
      // Ciphertext does not compress, and inflating untrusted frames lets a
      // peer blow up memory with one small message.
      compression: CompressionOptions.compressionOff,
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

  /// Whether the server hands out door codes (it has a code page).
  bool get doors => _doors;
  bool _doors = false;

  /// The room's current door code for the server's code page, `null`
  /// while there is none (not asked yet, or the last one expired).
  String? get doorCode => _doorCode;
  String? _doorCode;

  /// Tells when [doorCode] changes.
  Stream<String?> get doorCodes => _doorCodes.stream;
  final _doorCodes = StreamController<String?>.broadcast();
  Timer? _doorRotation;
  Timer? _doorExpiry;

  /// Asks the server for a door code now and a fresh one [every] so often,
  /// so people without the QR code can type it on the server's page; they
  /// land on [build]'s page for [protocol] with the [room] code, and the
  /// game leader checks them like any join without the QR code. Does
  /// nothing if the server has no code page.
  void openDoor({
    required String room,
    required int protocol,
    required String build,
    Duration every = const Duration(minutes: 5),
  }) {
    if (!_doors || _doorRotation != null) return;
    final ask = DoorAsked(room: room, protocol: protocol, build: build);
    _send(ask);
    _doorRotation = Timer.periodic(every, (_) => _send(ask));
  }

  void _setDoor(String? code) {
    if (code == _doorCode) return;
    _doorCode = code;
    if (!_doorCodes.isClosed) _doorCodes.add(code);
  }

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
      case RoomOpened(:final roomId, :final doors):
        if (_opened.isCompleted) return;
        this.roomId = roomId;
        _doors = doors;
        _opened.complete();
      case DoorOpened(:final code, :final lifetime):
        if (_doorRotation == null) return;
        _setDoor(code);
        // Without a newer one, the code stops showing when it stops working.
        _doorExpiry?.cancel();
        _doorExpiry = Timer(lifetime, () => _setDoor(null));
      case DoorAsked():
        // Only hosts ask.
        return;
    }
  }

  void _send(RelayFrame frame) {
    if (_socket.readyState == WebSocket.open) _socket.add(frame.encode());
  }

  void _shutDown() {
    _doorRotation?.cancel();
    _doorExpiry?.cancel();
    _setDoor(null);
    if (!_doorCodes.isClosed) unawaited(_doorCodes.close());
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
    compression: CompressionOptions.compressionOff,
  ).timeout(timeout);
  socket.pingInterval = const Duration(seconds: 10);
  return WebSocketConnection(socket);
}
