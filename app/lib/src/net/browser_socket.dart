import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:game_host/game_host.dart';
import 'package:game_host/lan.dart' show socketPath;
import 'package:web/web.dart' as web;

/// The browser's WebSocket back to the host that served this page (the
/// web app is loaded from the host's phone on the local network).
Future<Connection> dialPageHost() {
  final here = Uri.base;
  final url = Uri(
    scheme: 'ws',
    host: here.host,
    port: here.port,
    path: socketPath,
  ).toString();
  final socket = web.WebSocket(url);
  final open = Completer<Connection>();
  final connection = _BrowserConnection(socket);
  socket
    ..onopen = ((web.Event _) {
      if (!open.isCompleted) open.complete(connection);
    }).toJS
    ..onerror = ((web.Event _) {
      if (!open.isCompleted) open.completeError(StateError('no host'));
      unawaited(connection.close());
    }).toJS
    ..onclose = ((web.Event _) {
      if (!open.isCompleted) open.completeError(StateError('closed'));
      unawaited(connection.close());
    }).toJS
    ..onmessage = ((web.MessageEvent event) {
      final data = event.data;
      // Text frames only, like the native side.
      if (data.isA<JSString>()) {
        connection._incoming.add((data! as JSString).toDart);
      } else {
        unawaited(connection.close());
      }
    }).toJS;
  return open.future.timeout(
    const Duration(seconds: 6),
    onTimeout: () {
      unawaited(connection.close());
      throw TimeoutException('no answer');
    },
  );
}

class _BrowserConnection implements Connection {
  _BrowserConnection(this._socket);

  final web.WebSocket _socket;
  final _incoming = StreamController<String>();
  bool _closed = false;

  @override
  Stream<String> get messages => _incoming.stream;

  @override
  void send(String message) {
    if (!_closed && _socket.readyState == web.WebSocket.OPEN) {
      _socket.send(message.toJS);
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _socket.close();
    await _incoming.close();
  }
}

/// Removes the join link (with the room's key) from the address bar and
/// the history, so it does not linger where others can see it.
void forgetPageLink() {
  final history = web.window.history;
  // Keep the router's own state; only the address changes.
  history.replaceState(history.state, '', '/join');
}

const _gameKey = 'whowolf.game';

/// Keeps the way back into this game (link with the room's key, the
/// session token) in this tab's session storage: a phone that throws away
/// a background tab reloads the page and comes back to its seat. Session
/// storage belongs to this tab only and is gone when the tab closes.
void rememberGame(String link, {String? token, String? name}) {
  try {
    web.window.sessionStorage.setItem(
      _gameKey,
      jsonEncode({'link': link, 'token': ?token, 'name': ?name}),
    );
  } on Object {
    // No storage: a reload means scanning again.
  }
}

/// The way back into this tab's game, if any.
({String link, String? token, String? name})? recallGame() {
  try {
    final raw = web.window.sessionStorage.getItem(_gameKey);
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, Object?>;
    return (
      link: json['link']! as String,
      token: json['token'] as String?,
      name: json['name'] as String?,
    );
  } on Object {
    return null;
  }
}

/// Forgets this tab's game (it ended, or the player left).
void forgetGame() {
  try {
    web.window.sessionStorage.removeItem(_gameKey);
  } on Object {
    // Nothing kept.
  }
}
