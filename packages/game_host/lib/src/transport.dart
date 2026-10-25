import 'dart:async';

/// One player's link to the host, whatever carries it (LAN WebSocket, later a
/// relay, or memory in tests). Messages are already-encoded protocol strings.
abstract interface class Connection {
  /// Messages from the other side. Single subscription; done when closed.
  Stream<String> get messages;

  /// Sends [message] to the other side. Ignored once closed.
  void send(String message);

  /// Closes the connection.
  Future<void> close();
}

/// Something that brings new connections to the host. A host can serve
/// several transports at once (e.g. LAN and, later, a relay).
abstract interface class Transport {
  /// New incoming connections.
  Stream<Connection> get connections;

  /// Stops accepting connections and closes the transport.
  Future<void> close();
}

/// A transport inside one process: for the host player's own app and tests.
class MemoryTransport implements Transport {
  final _incoming = StreamController<Connection>();

  @override
  Stream<Connection> get connections => _incoming.stream;

  /// Opens a connection; returns the player's end, the host gets the other.
  Connection connect() {
    final toHost = StreamController<String>();
    final toPlayer = StreamController<String>();
    final hostEnd = _MemoryConnection(toHost, toPlayer);
    final playerEnd = _MemoryConnection(toPlayer, toHost);
    hostEnd._peer = playerEnd;
    playerEnd._peer = hostEnd;
    _incoming.add(hostEnd);
    return playerEnd;
  }

  @override
  Future<void> close() => _incoming.close();
}

class _MemoryConnection implements Connection {
  _MemoryConnection(this._in, this._out);

  final StreamController<String> _in;
  final StreamController<String> _out;
  late _MemoryConnection _peer;
  bool _closed = false;

  @override
  Stream<String> get messages => _in.stream;

  @override
  void send(String message) {
    if (!_closed) _out.add(message);
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _peer._closed = true;
    // Not awaited: a close only completes once the other side listened.
    unawaited(_in.close());
    unawaited(_out.close());
  }
}
