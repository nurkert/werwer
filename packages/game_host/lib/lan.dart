/// LAN transport: the host device opens a WebSocket on the local network and
/// players dial it. Uses `dart:io`, so it is kept out of `game_host.dart`.
///
/// Not encrypted yet: this is for play tests on a trusted home network. The
/// Noise handshake (docs/SECURITY_DESIGN.md) will wrap [Connection] before a
/// public release.
library;

import 'dart:async';
import 'dart:io';

import 'package:game_host/socket_guard.dart';
import 'package:game_host/src/transport.dart';
import 'package:protocol/protocol.dart'
    show hostSocketPath, isWebAppPath, webAppHeaders;

/// What one player's connection to the host may cost on the Wi-Fi: small
/// messages in (the encrypted handshake and frames, which secure_channel
/// caps at 90 000 characters), views out.
const lanSocketLimits = SocketLimits(
  burst: 512 * 1024,
  rate: 128 * 1024,
  maxMessage: 192 * 1024,
  maxBacklog: 512 * 1024,
);

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
      // Guarded on the raw socket: a stranger on the Wi-Fi can neither
      // send one endless message nor stop reading and let output pile up.
      final guarded = await upgradeGuarded(
        request,
        lanSocketLimits,
        pingInterval: const Duration(seconds: 5),
      );
      if (_incoming.isClosed) {
        await guarded.socket.close();
        return;
      }
      _incoming.add(WebSocketConnection.guarded(guarded));
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
          (path.isEmpty || isWebAppPath(path));
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
      final self = host == null ? '' : 'ws://$host:$port';
      final accepts =
          request.headers[HttpHeaders.acceptEncodingHeader]?.join(',') ?? '';
      final bytes = file.bytes;
      final headers = response.headers
        ..contentType = ContentType.parse(file.contentType)
        ..set(HttpHeaders.cacheControlHeader, 'no-cache');
      webAppHeaders(self).forEach(headers.set);
      if (file.gzip) {
        // Never unpacked on request (a stranger could make the phone do
        // it again and again); every browser that runs the app takes gzip.
        headers.set(HttpHeaders.varyHeader, 'Accept-Encoding');
        if (!accepts.contains('gzip')) {
          response.statusCode = HttpStatus.notAcceptable;
          await response.close();
          return;
        }
        headers.set(HttpHeaders.contentEncodingHeader, 'gzip');
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
  WebSocketConnection(this._socket) : _guarded = null;

  /// Wraps a guarded WebSocket (the host's side of a LAN connection).
  WebSocketConnection.guarded(GuardedWebSocket guarded)
    : _socket = guarded.socket,
      _guarded = guarded;

  final WebSocket _socket;
  final GuardedWebSocket? _guarded;
  bool _closed = false;

  @override
  Stream<String> get messages => _socket.map(
    (data) => data is String ? data : throw const FormatException('binary'),
  );

  @override
  void send(String message) {
    // The socket stays "open" for a moment after close(); adding then throws.
    if (_closed || _socket.readyState != WebSocket.open) return;
    final guarded = _guarded;
    if (guarded != null) {
      guarded.send(message);
    } else {
      _socket.add(message);
    }
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
