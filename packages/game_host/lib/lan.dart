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
import 'package:protocol/protocol.dart' show hostSocketPath;

/// Port the host tries first; if it is taken, the system picks one.
const defaultPort = 47470;

/// The only path the host answers on.
const String socketPath = hostSocketPath;

/// A file of the web app the host serves to browsers on the local network.
class SiteFile {
  /// Creates a file; [gzip] means [bytes] are already gzip-compressed.
  const SiteFile(this.bytes, this.contentType, {this.gzip = false});

  /// The content.
  final List<int> bytes;

  /// Its media type, e.g. `text/html; charset=utf-8`.
  final String contentType;

  /// Whether [bytes] are gzip-compressed.
  final bool gzip;
}

/// Looks up a file of the web app by its path (no leading slash; `''` is
/// the page itself). `null` if there is no such file.
typedef Site = Future<SiteFile?> Function(String path);

final _sitePath = RegExp(r'^[A-Za-z0-9_.\-]+(/[A-Za-z0-9_.\-]+)*$');

/// Accepts WebSocket connections from the local network and, with a
/// [Site], serves the web app to browsers there (players join without
/// installing anything).
class LanTransport implements Transport {
  LanTransport._(this._server, this._site) {
    _server.listen(_handle, onError: (Object _) {});
  }

  /// Opens the server on [port] (falling back to any free port).
  static Future<LanTransport> bind({int port = defaultPort, Site? site}) async {
    HttpServer server;
    try {
      server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    } on SocketException {
      server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    }
    server
      ..idleTimeout = const Duration(seconds: 10)
      ..serverHeader = null;
    return LanTransport._(server, site);
  }

  final HttpServer _server;
  final Site? _site;
  final _incoming = StreamController<Connection>();

  /// The port players dial.
  int get port => _server.port;

  @override
  Stream<Connection> get connections => _incoming.stream;

  Future<void> _handle(HttpRequest request) async {
    final remote = request.connectionInfo?.remoteAddress;
    final local =
        remote != null && (remote.isLoopback || isPrivateIPv4(remote));
    final socket =
        request.uri.path == socketPath &&
        WebSocketTransformer.isUpgradeRequest(request);
    if (!local || !socket) {
      if (local && _site != null) return _serve(request, _site);
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

  /// Serves one file of the web app: GET or HEAD only, strict paths (no
  /// way out of the site), and headers that keep the page to itself.
  static Future<void> _serve(HttpRequest request, Site site) async {
    final response = request.response;
    try {
      final method = request.method;
      var path = request.uri.path;
      if (path == '/' || path == '/join') path = '/';
      path = path.substring(1);
      final valid =
          (method == 'GET' || method == 'HEAD') &&
          path.length <= 200 &&
          (path.isEmpty || _sitePath.hasMatch(path)) &&
          !path.split('/').any((part) => part.startsWith('.'));
      final file = valid ? await site(path) : null;
      if (file == null) {
        response.statusCode = valid
            ? HttpStatus.notFound
            : HttpStatus.badRequest;
        await response.close();
        return;
      }
      final host = request.headers.host;
      final port = request.headers.port;
      final self = host == null ? '' : ' ws://$host:$port';
      final accepts =
          request.headers.value(HttpHeaders.acceptEncodingHeader) ?? '';
      var bytes = file.bytes;
      final headers = response.headers
        ..contentType = ContentType.parse(file.contentType)
        ..set(HttpHeaders.cacheControlHeader, 'no-cache')
        ..set('X-Content-Type-Options', 'nosniff')
        ..set('X-Frame-Options', 'DENY')
        ..set('Referrer-Policy', 'no-referrer')
        ..set('Cross-Origin-Opener-Policy', 'same-origin')
        ..set(
          'Content-Security-Policy',
          "default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; "
              "style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; "
              "font-src 'self' data:; worker-src 'self' blob:; "
              "connect-src 'self'$self; frame-ancestors 'none'; "
              "base-uri 'none'; form-action 'none'",
        );
      if (file.gzip) {
        if (accepts.contains('gzip')) {
          headers.set(HttpHeaders.contentEncodingHeader, 'gzip');
        } else {
          bytes = gzip.decode(bytes);
        }
      }
      response.contentLength = bytes.length;
      if (method == 'GET') response.add(bytes);
      await response.close();
    } on Object {
      // The browser went away mid-file: nothing to clean up.
      try {
        await response.close();
      } on Object {
        // Already closed.
      }
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
