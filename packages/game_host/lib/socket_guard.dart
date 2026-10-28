/// WebSocket connections whose raw bytes are watched before `dart:io`
/// assembles them: `dart:io` would otherwise buffer a message of any size
/// (across any number of fragments) and queue any amount of output for a
/// peer that stops reading. Used by the relay server and the LAN host.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// What one connection may cost.
class SocketLimits {
  /// Creates limits.
  const SocketLimits({
    required this.burst,
    required this.rate,
    required this.maxMessage,
    required this.maxBacklog,
    this.messageDeadline = const Duration(seconds: 10),
    this.drainDeadline = const Duration(seconds: 15),
  });

  /// Most bytes received at once.
  final int burst;

  /// Bytes per second received over time.
  final int rate;

  /// Largest message, counted over all its fragments.
  final int maxMessage;

  /// Most bytes waiting to go out to this peer.
  final int maxBacklog;

  /// How long a message may stay unfinished (more fragments to come).
  final Duration messageDeadline;

  /// How long output may wait for the peer to read before it is dropped.
  final Duration drainDeadline;
}

/// Answers a WebSocket upgrade by hand (RFC 6455, section 4.2.2), so the
/// raw socket is guarded byte by byte before `dart:io` assembles frames.
/// No compression: inflating an attacker's frame could turn one small
/// message into gigabytes. Throws a [FormatException] for a bad request.
Future<GuardedWebSocket> upgradeGuarded(
  HttpRequest request,
  SocketLimits limits, {
  Duration? pingInterval,
}) async {
  final keys = request.headers['sec-websocket-key'];
  final key = keys?.length == 1 ? keys!.single.trim() : null;
  if (key == null || key.isEmpty || key.length > 64) {
    throw const FormatException('no key');
  }
  final accept = base64.encode(
    sha1
        .convert(ascii.encode('${key}258EAFA5-E914-47DA-95CA-C5AB0DC85B11'))
        .bytes,
  );
  request.response
    ..statusCode = HttpStatus.switchingProtocols
    ..headers.set(HttpHeaders.connectionHeader, 'Upgrade')
    ..headers.set(HttpHeaders.upgradeHeader, 'websocket')
    ..headers.set('Sec-WebSocket-Accept', accept);
  final raw = await request.response.detachSocket();
  final guard = GuardedSocket(raw, limits);
  final socket = WebSocket.fromUpgradedSocket(
    guard,
    serverSide: true,
    compression: CompressionOptions.compressionOff,
  )..pingInterval = pingInterval;
  return GuardedWebSocket._(socket, guard);
}

/// A WebSocket and the guard on its raw socket.
class GuardedWebSocket {
  GuardedWebSocket._(this.socket, this.guard);

  /// The socket.
  final WebSocket socket;

  /// Its guard.
  final GuardedSocket guard;

  /// Sends [data] unless the peer has too much waiting already; then the
  /// connection is dropped. Never throws.
  void send(String data) {
    if (socket.readyState != WebSocket.open) return;
    if (!guard.queue(data.length)) return;
    try {
      socket.add(data);
      // dart:io has no way to ask whether this side already closed the
      // sink; the write tells by throwing. The peer is gone either way.
      // ignore: avoid_catching_errors
    } on StateError {
      return;
    }
  }
}

/// A raw socket that counts what comes in against [SocketLimits] (rate,
/// message size, unfinished messages) by reading the frame headers, and
/// what goes out against the backlog; a peer over any limit is cut off.
class GuardedSocket extends Stream<Uint8List> implements Socket {
  /// Guards [_inner].
  GuardedSocket(this._inner, this.limits) : _tokens = limits.burst.toDouble();

  final Socket _inner;

  /// The limits.
  final SocketLimits limits;

  final _watch = Stopwatch()..start();
  double _tokens;
  bool _destroyed = false;
  final _gone = Completer<void>();

  // The frame being read (client frames are masked; only lengths matter).
  final _header = <int>[];
  int _payloadLeft = 0;
  bool _inMessage = false;
  int _messageBytes = 0;
  Timer? _messageTimer;

  // Output: bytes handed to the WebSocket and bytes the OS has taken.
  int _queued = 0;
  int _sent = 0;
  Timer? _drainTimer;

  /// Whether this connection was cut off.
  bool get destroyed => _destroyed;

  /// Bytes waiting to go out (roughly: frame headers are not counted).
  int get backlog => max(0, _queued - _sent);

  /// Counts [bytes] about to be sent; `false` (and the connection is cut)
  /// if the peer has too much waiting already.
  bool queue(int bytes) {
    if (_destroyed) return false;
    _queued += bytes;
    if (backlog <= limits.maxBacklog) return true;
    destroy();
    return false;
  }

  bool _spend(int bytes) {
    final elapsed = _watch.elapsedMicroseconds;
    _watch.reset();
    _tokens = min(
      limits.burst.toDouble(),
      _tokens + elapsed * limits.rate / 1e6,
    );
    _tokens -= bytes;
    return _tokens >= 0;
  }

  /// Reads frame headers in [chunk]; `false` if a limit is broken.
  bool _inspect(Uint8List chunk) {
    var i = 0;
    while (i < chunk.length) {
      if (_payloadLeft > 0) {
        final skip = min(_payloadLeft, chunk.length - i);
        _payloadLeft -= skip;
        i += skip;
        continue;
      }
      _header.add(chunk[i++]);
      if (_header.length < 2) continue;
      final len7 = _header[1] & 0x7F;
      final masked = (_header[1] & 0x80) != 0;
      final extra = len7 == 126 ? 2 : (len7 == 127 ? 8 : 0);
      final need = 2 + extra + (masked ? 4 : 0);
      if (_header.length < need) continue;
      var length = len7;
      if (extra > 0) {
        length = 0;
        for (var k = 2; k < 2 + extra; k++) {
          // A length beyond the message limit ends it here, before the
          // number can grow past what an int holds.
          if (length > limits.maxMessage) return false;
          length = (length << 8) | _header[k];
        }
      }
      final fin = (_header[0] & 0x80) != 0;
      final opcode = _header[0] & 0x0F;
      _header.clear();
      if (opcode >= 8) {
        // Control frames are short and never fragmented (RFC 6455, 5.5).
        if (!fin || length > 125) return false;
      } else {
        final continuation = opcode == 0;
        if (continuation != _inMessage) return false;
        _messageBytes += length;
        if (_messageBytes > limits.maxMessage) return false;
        if (fin) {
          _inMessage = false;
          _messageBytes = 0;
          _messageTimer?.cancel();
          _messageTimer = null;
        } else if (!_inMessage) {
          _inMessage = true;
          _messageTimer = Timer(limits.messageDeadline, destroy);
        }
      }
      _payloadLeft = length;
    }
    return true;
  }

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _inner
      .where((chunk) {
        if (!_destroyed && _spend(chunk.length) && _inspect(chunk)) {
          return true;
        }
        destroy();
        return false;
      })
      .listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );

  /// Output goes to the OS in steps; while the peer does not read, the
  /// WebSocket's own buffer holds it, counted by [queue] against the
  /// backlog, and a peer that reads nothing for [SocketLimits.drainDeadline]
  /// is cut off.
  @override
  Future<void> addStream(Stream<List<int>> stream) {
    final done = Completer<void>();
    late final StreamSubscription<List<int>> subscription;
    void finish() {
      if (!done.isCompleted) done.complete();
    }

    Future<void> drain(int bytes) async {
      _drainTimer = Timer(limits.drainDeadline, destroy);
      try {
        // A destroyed socket may never finish its flush: stop waiting then.
        await Future.any([_inner.flush(), _gone.future]);
        _sent += bytes;
      } on Object {
        destroy();
      } finally {
        _drainTimer?.cancel();
        _drainTimer = null;
      }
    }

    subscription = stream.listen(
      (chunk) {
        if (_destroyed) {
          unawaited(subscription.cancel());
          finish();
          return;
        }
        try {
          _inner.add(chunk);
        } on Object {
          destroy();
          unawaited(subscription.cancel());
          finish();
          return;
        }
        subscription.pause();
        unawaited(
          drain(chunk.length).whenComplete(() {
            if (_destroyed) {
              unawaited(subscription.cancel());
              finish();
            } else {
              subscription.resume();
            }
          }),
        );
      },
      onError: (Object _) {
        destroy();
        finish();
      },
      onDone: finish,
      cancelOnError: true,
    );
    return done.future;
  }

  @override
  void destroy() {
    if (_destroyed) return;
    _destroyed = true;
    _gone.complete();
    _messageTimer?.cancel();
    _drainTimer?.cancel();
    _inner.destroy();
  }

  @override
  Encoding get encoding => _inner.encoding;

  @override
  set encoding(Encoding value) => _inner.encoding = value;

  @override
  InternetAddress get address => _inner.address;

  @override
  InternetAddress get remoteAddress => _inner.remoteAddress;

  @override
  int get port => _inner.port;

  @override
  int get remotePort => _inner.remotePort;

  @override
  bool setOption(SocketOption option, bool enabled) =>
      _inner.setOption(option, enabled);

  @override
  Uint8List getRawOption(RawSocketOption option) => _inner.getRawOption(option);

  @override
  void setRawOption(RawSocketOption option) => _inner.setRawOption(option);

  @override
  void add(List<int> data) => _inner.add(data);

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _inner.addError(error, stackTrace);

  /// Closes, or cuts off a socket that is still flushing to a peer who
  /// does not read (closing a sink in mid-flush throws).
  @override
  Future<void> close() async {
    if (_destroyed || _drainTimer != null) return destroy();
    try {
      await _inner.close();
    } on Object {
      destroy();
    }
  }

  @override
  Future<void> get done => _inner.done;

  @override
  Future<void> flush() => _inner.flush();

  @override
  void write(Object? object) => _inner.write(object);

  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) =>
      _inner.writeAll(objects, separator);

  @override
  void writeCharCode(int charCode) => _inner.writeCharCode(charCode);

  @override
  void writeln([Object? object = '']) => _inner.writeln(object);
}
