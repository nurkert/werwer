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
    required this._name,
    required this.roomCode,
    required this._dial,
    this._token,
    this.onWelcome,
    this.onEnded,
    this.reconnectDelay = const Duration(seconds: 2),
    this.maxReconnects = 90,
  }) {
    unawaited(_connect());
  }

  String _name;
  final String roomCode;

  /// The name this player joins with.
  String get name => _name;

  /// The host refused the name (taken or invalid); [rename] tries another.
  bool nameRefused = false;
  final Duration reconnectDelay;

  /// Give up after this many failed reconnects in a row (the host is gone).
  final int maxReconnects;

  /// Called with the session token and the accepted name once welcomed.
  final void Function(String token, String name)? onWelcome;

  /// Called when the session ends for good.
  final void Function()? onEnded;

  final Dial _dial;
  int _failedReconnects = 0;

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
        Hello(name: _name, room: roomCode, token: _token).encode(),
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
        _failedReconnects = 0;
        status = SessionStatus.connected;
        nameRefused = false;
        onWelcome?.call(token, _name);
      case StateMessage():
        view = message.view;
        isOwner = message.isOwner;
        final endsIn = message.phaseEndsInMs;
        phaseEndsAt = endsIn == null
            ? null
            : DateTime.now().add(Duration(milliseconds: endsIn));
      case Refused(:final reason):
        if (reason == Violation.invalidName && _token == null) {
          nameRefused = true;
        } else {
          refused = reason;
        }
      case Bye(:final reason):
        byeReason = reason;
        _end();
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
    final neverJoined = _token == null && status == SessionStatus.connecting;
    if (neverJoined || _failedReconnects >= maxReconnects) {
      _end();
      notifyListeners();
      return;
    }
    if (status == SessionStatus.reconnecting) _failedReconnects++;
    status = SessionStatus.reconnecting;
    notifyListeners();
    _retry?.cancel();
    _retry = Timer(reconnectDelay, () {
      if (!_disposed && status == SessionStatus.reconnecting) {
        unawaited(_connect());
      }
    });
  }

  void _end() {
    if (status == SessionStatus.ended) return;
    status = SessionStatus.ended;
    onEnded?.call();
  }

  /// Joins with another name after the host refused the first one.
  void rename(String name) {
    _name = name.trim();
    nameRefused = false;
    send(Hello(name: _name, room: roomCode));
    notifyListeners();
  }

  Timer? _retry;

  /// Reconnects immediately if the connection is down (e.g. the app just
  /// came back to the foreground or the network changed).
  void reconnectNow() {
    if (_disposed || status != SessionStatus.reconnecting) return;
    _retry?.cancel();
    unawaited(_connect());
  }

  void send(ClientMessage message) => _connection?.send(message.encode());

  /// Leaves for good: tells the host (in the lobby) and closes.
  void leave() {
    if (view?.phase == Phase.lobby) send(const LeaveIntent());
    byeReason = ByeReason.left;
    _end();
    unawaited(_connection?.close());
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _retry?.cancel();
    unawaited(_subscription?.cancel());
    unawaited(_connection?.close());
    super.dispose();
  }
}
