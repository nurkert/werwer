/// A WebSocket [Connection] in the browser, for players who join without
/// the app. Uses `package:web`; import it only on the web.
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:game_host/src/transport.dart';
import 'package:web/web.dart' as web;

/// Opens a WebSocket to [url] (`ws://` or `wss://`) and returns it as a
/// [Connection] once it is open.
Future<Connection> dialBrowser(
  Uri url, {
  Duration timeout = const Duration(seconds: 6),
}) {
  final socket = web.WebSocket(url.toString());
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
    timeout,
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
