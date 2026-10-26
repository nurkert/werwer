/// LAN transport: the host device opens a WebSocket on the local network and
/// players dial it. Uses `dart:io`, so it is kept out of `game_host.dart`.
///
/// Not encrypted yet: this is for play tests on a trusted home network. The
/// Noise handshake (docs/SECURITY_DESIGN.md) will wrap [Connection] before a
/// public release.
library;

import 'dart:async';
import 'dart:io';

import 'package:game_host/src/transport.dart';

/// Port the host tries first; if it is taken, the system picks one.
const defaultPort = 47470;

/// The only path the host answers on.
const socketPath = '/whowolf';

/// Accepts WebSocket connections from the local network.
class LanTransport implements Transport {
  LanTransport._(this._server) {
    _server.listen(_handle, onError: (Object _) {});
  }

  /// Opens the server on [port] (falling back to any free port).
  static Future<LanTransport> bind({int port = defaultPort}) async {
    HttpServer server;
    try {
      server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    } on SocketException {
      server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    }
    server
      ..idleTimeout = const Duration(seconds: 10)
      ..serverHeader = null;
    return LanTransport._(server);
  }

  final HttpServer _server;
  final _incoming = StreamController<Connection>();

  /// The port players dial.
  int get port => _server.port;

  @override
  Stream<Connection> get connections => _incoming.stream;

  Future<void> _handle(HttpRequest request) async {
    final remote = request.connectionInfo?.remoteAddress;
    final local =
        remote != null && (remote.isLoopback || isPrivateIPv4(remote));
    if (!local ||
        request.uri.path != socketPath ||
        !WebSocketTransformer.isUpgradeRequest(request)) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    try {
      // No compression: ciphertext does not compress, and inflating a
      // stranger's frame could blow up memory from one small message.
      final socket = await WebSocketTransformer.upgrade(
        request,
        compression: CompressionOptions.compressionOff,
      );
      socket.pingInterval = const Duration(seconds: 5);
      if (_incoming.isClosed) {
        await socket.close();
        return;
      }
      _incoming.add(WebSocketConnection(socket));
    } on Object {
      // A broken handshake only affects that one request.
    }
  }

  @override
  Future<void> close() async {
    await _server.close(force: true);
    await _incoming.close();
  }
}

/// A `Connection` over a WebSocket. Binary frames end the connection.
class WebSocketConnection implements Connection {
  /// Wraps a connected WebSocket.
  WebSocketConnection(this._socket);

  final WebSocket _socket;
  bool _closed = false;

  @override
  Stream<String> get messages => _socket.map(
    (data) => data is String ? data : throw const FormatException('binary'),
  );

  @override
  void send(String message) {
    // The socket stays "open" for a moment after close(); adding then throws.
    if (!_closed && _socket.readyState == WebSocket.open) _socket.add(message);
  }

  @override
  Future<void> close() {
    _closed = true;
    return _socket.close();
  }
}

/// Connects to a host at [address]:[port].
Future<Connection> dialHost(
  String address,
  int port, {
  Duration timeout = const Duration(seconds: 6),
}) async {
  final socket = await WebSocket.connect(
    Uri(scheme: 'ws', host: address, port: port, path: socketPath).toString(),
    compression: CompressionOptions.compressionOff,
  ).timeout(timeout);
  socket.pingInterval = const Duration(seconds: 5);
  return WebSocketConnection(socket);
}

/// Whether [address] is a private IPv4 address (10/8, 172.16/12, 192.168/16).
bool isPrivateIPv4(InternetAddress address) {
  if (address.type != InternetAddressType.IPv4) return false;
  final b = address.rawAddress;
  return b[0] == 10 ||
      (b[0] == 172 && b[1] >= 16 && b[1] <= 31) ||
      (b[0] == 192 && b[1] == 168);
}

/// This device's private IPv4 addresses, Wi-Fi first where recognisable.
Future<List<InternetAddress>> privateAddresses() async {
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
  );
  int rank(NetworkInterface i) {
    final name = i.name.toLowerCase();
    if (name == 'en0' || name.startsWith('wlan') || name.startsWith('wl')) {
      return 0;
    }
    if (name.startsWith('en') || name.startsWith('eth')) return 1;
    return 2;
  }

  interfaces.sort((a, b) => rank(a).compareTo(rank(b)));
  return [
    for (final i in interfaces)
      for (final a in i.addresses)
        if (isPrivateIPv4(a)) a,
  ];
}
