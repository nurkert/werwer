import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:game_core/game_core.dart';
import 'package:game_host/game_host.dart';
import 'package:protocol/protocol.dart';

/// Opens a connection to the host; called again to reconnect.
typedef Dial = Future<Connection> Function();

/// Where the connection to the host stands.
enum SessionStatus { connecting, connected, reconnecting, ended }

/// This app's side of one game: it talks the protocol with the host and
/// holds the latest view. It knows nothing about where the host runs.
class GameSession extends ChangeNotifier {
  GameSession({
    required this.name,
    required this.roomCode,
    required this._dial,
    this.reconnectDelay = const Duration(seconds: 2),
  }) {
    unawaited(_connect());
  }

  final String name;
  final String roomCode;
  final Duration reconnectDelay;
  final Dial _dial;

  Connection? _connection;
  StreamSubscription<String>? _subscription;
  String? _token;
  bool _disposed = false;

  SessionStatus status = SessionStatus.connecting;

  /// Why the host ended the session; `null` if the connection just broke.
  ByeReason? byeReason;

  /// The latest view of the game.
  PlayerView? view;

  /// Whether this player opened the room.
  bool isOwner = false;

  /// When the current phase timer runs out, on this device's clock.
  DateTime? phaseEndsAt;

  /// The last refused intent, cleared by the UI after showing it.
  Violation? refused;

  Future<void> _connect() async {
    try {
      final connection = await _dial();
      if (_disposed) {
        await connection.close();
        return;
      }
      _connection = connection;
      _subscription = connection.messages.listen(
        _receive,
        onDone: _lost,
        onError: (Object _) => _lost(),
        cancelOnError: true,
      );
      connection.send(
        Hello(name: name, room: roomCode, token: _token).encode(),
      );
    } on Object {
      _lost();
    }
  }

  void _receive(String raw) {
    final HostMessage message;
    try {
      message = HostMessage.parse(raw);
    } on ProtocolError {
      return;
    }
    switch (message) {
      case Welcome(:final token):
        _token = token;
        status = SessionStatus.connected;
      case StateMessage():
        view = message.view;
        isOwner = message.isOwner;
        final endsIn = message.phaseEndsInMs;
        phaseEndsAt = endsIn == null
            ? null
            : DateTime.now().add(Duration(milliseconds: endsIn));
      case Refused(:final reason):
        refused = reason;
      case Bye(:final reason):
        byeReason = reason;
        status = SessionStatus.ended;
        unawaited(_subscription?.cancel());
        unawaited(_connection?.close());
    }
    notifyListeners();
  }

  void _lost() {
    if (_disposed || status == SessionStatus.ended) return;
    unawaited(_subscription?.cancel());
    _subscription = null;
    _connection = null;
    // Without a token the host never knew us: give up instead of retrying.
    if (_token == null && status == SessionStatus.connecting) {
      status = SessionStatus.ended;
      notifyListeners();
      return;
    }
    status = SessionStatus.reconnecting;
    notifyListeners();
    Timer(reconnectDelay, () {
      if (!_disposed && status == SessionStatus.reconnecting) {
        unawaited(_connect());
      }
    });
  }

  void send(ClientMessage message) => _connection?.send(message.encode());

  /// Leaves for good: tells the host (in the lobby) and closes.
  void leave() {
    if (view?.phase == Phase.lobby) send(const LeaveIntent());
    status = SessionStatus.ended;
    byeReason = ByeReason.left;
    unawaited(_connection?.close());
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    unawaited(_connection?.close());
    super.dispose();
  }
}
