import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:game_host/game_host.dart';
import 'package:secure_channel/src/noise.dart';

/// Bound into every handshake, so keys from other protocols never fit.
const _prologue = 'whowolf-secure-1';

/// Plaintexts are padded to one of these sizes, so message sizes say
/// nothing about their content (e.g. whether someone is a werewolf).
const paddingSteps = [512, 2048, 8192, 32768, 65000];

/// How long a peer may take for the handshake.
const handshakeTimeout = Duration(seconds: 5);

/// Number of different symbols in a check code.
const checkSymbols = 16;

/// Symbols in a check code.
const checkLength = 3;

/// The keys of one room: a fresh key pair and a room secret, both shown only
/// in the QR code at the table.
class HostKeys {
  HostKeys._(this.keyPair, this.publicKey, this.roomSecret);

  /// New random keys for a new room.
  static Future<HostKeys> generate() async {
    final keyPair = await X25519().newKeyPair();
    final random = Random.secure();
    return HostKeys._(
      keyPair,
      (await keyPair.extractPublicKey()).bytes,
      List.generate(32, (_) => random.nextInt(256)),
    );
  }

  /// Keys saved with [toJson], e.g. to restore a room after a crash.
  static Future<HostKeys> fromJson(Map<String, Object?> json) async {
    final private = base64Url.decode(json['private']! as String);
    final secret = base64Url.decode(json['secret']! as String);
    if (private.length != 32 || secret.length != 32) {
      throw const FormatException('bad host keys');
    }
    final keyPair = await X25519().newKeyPairFromSeed(private);
    return HostKeys._(
      keyPair,
      (await keyPair.extractPublicKey()).bytes,
      secret,
    );
  }

  /// The key pair.
  final SimpleKeyPair keyPair;

  /// The public key for the QR code.
  final List<int> publicKey;

  /// The room secret for the QR code.
  final List<int> roomSecret;

  /// The keys as JSON, including the private key: store on this device only.
  Future<Map<String, Object?>> toJson() async => {
    'private': base64Url.encode(await keyPair.extractPrivateKeyBytes()),
    'secret': base64Url.encode(roomSecret),
  };
}

List<int> _checkCode(List<int> handshakeHash) => [
  for (var i = 0; i < checkLength; i++) handshakeHash[i] % checkSymbols,
];

Uint8List _pad(String message) {
  final data = utf8.encode(message);
  final needed = data.length + 4;
  final size = paddingSteps.firstWhere(
    (s) => s >= needed,
    orElse: () => throw ArgumentError('message too large'),
  );
  final out = Uint8List(size);
  ByteData.view(out.buffer).setUint32(0, data.length);
  out.setAll(4, data);
  return out;
}

String _unpad(Uint8List padded) {
  if (padded.length < 4 || !paddingSteps.contains(padded.length)) {
    throw const NoiseError('bad padding');
  }
  final length = ByteData.view(padded.buffer).getUint32(0);
  if (length > padded.length - 4) throw const NoiseError('bad padding');
  return utf8.decode(padded.sublist(4, 4 + length));
}

/// An encrypted [Connection]: every message is padded and encrypted with
/// keys only the two ends know. A relay or eavesdropper sees same-sized
/// noise.
class SecureConnection implements Connection, PeerTrust {
  SecureConnection._(
    this._inner,
    this._send,
    this._receive, {
    required this.verified,
    required this.checkCode,
  }) {
    _subscription = _inner.messages.listen(
      (frame) => _queue = _queue.then((_) => _decrypt(frame)),
      onDone: () => _queue = _queue.then((_) => _close()),
      onError: (Object _) => _queue = _queue.then((_) => _close()),
    );
  }

  final Connection _inner;
  final NoiseCipher _send;
  final NoiseCipher _receive;
  final _messages = StreamController<String>();
  late final StreamSubscription<String> _subscription;
  Future<void> _queue = Future.value();
  Future<void> _sending = Future.value();
  bool _closed = false;

  @override
  final bool verified;

  @override
  final List<int> checkCode;

  @override
  Stream<String> get messages => _messages.stream;

  Future<void> _decrypt(String frame) async {
    if (_closed) return;
    try {
      final bytes = base64Url.decode(frame);
      if (bytes.length > maxNoiseMessage) throw const NoiseError('too long');
      _messages.add(_unpad(await _receive.decrypt(bytes)));
    } on Object {
      // Tampered, replayed or garbage: the channel is not trustworthy.
      await _close();
    }
  }

  @override
  void send(String message) {
    if (_closed) return;
    // Encryption is async; keep the order (nonces must stay in sequence).
    _sending = _sending.then((_) async {
      if (_closed) return;
      _inner.send(base64Url.encode(await _send.encrypt(_pad(message))));
    });
  }

  Future<void> _close() async {
    if (_closed) return;
    _closed = true;
    // Close the wire first: that ends the incoming stream, so cancelling the
    // subscription afterwards never waits on a read that cannot finish.
    await _inner.close();
    unawaited(_subscription.cancel());
    unawaited(_messages.close());
  }

  @override
  Future<void> close() async {
    await _sending;
    await _close();
  }
}

/// Opens an encrypted channel to the host over [raw]. With [hostKey] and
/// [roomSecret] (from the QR code) the host is authenticated and the channel
/// is [SecureConnection.verified]; without them the channel is encrypted but
/// the players must compare the check code.
///
/// Throws a [NoiseError] if the host is not who the QR code says.
Future<SecureConnection> connectSecure(
  Connection raw, {
  List<int>? hostKey,
  List<int>? roomSecret,
  Duration timeout = handshakeTimeout,
}) async {
  final pattern = hostKey != null && roomSecret != null
      ? NoisePattern.nkPsk2
      : NoisePattern.nn;
  final handshake = await NoiseHandshake.initiator(
    pattern,
    prologue: utf8.encode('$_prologue ${pattern.name}'),
    remoteStatic: hostKey,
    psk: roomSecret,
  );
  final replies = StreamIterator(raw.messages);
  try {
    final first = await handshake.writeMessage();
    raw.send(
      jsonEncode({'noise': 1, 'p': pattern.name, 'm': base64Url.encode(first)}),
    );
    if (!await replies.moveNext().timeout(timeout)) {
      throw const NoiseError('host closed the connection');
    }
    await handshake.readMessage(base64Url.decode(replies.current));
  } on NoiseError {
    await raw.close();
    rethrow;
  } on Object catch (error) {
    await raw.close();
    throw NoiseError('handshake failed: $error');
  }
  final (send, receive) = await handshake.split();
  // The rest of the stream belongs to the secure connection.
  return SecureConnection._(
    _IteratorConnection(raw, replies),
    send,
    receive,
    verified: pattern == NoisePattern.nkPsk2,
    checkCode: _checkCode(handshake.handshakeHash),
  );
}

/// Accepts encrypted connections from an inner transport (LAN, relay, …).
/// Peers who show the room secret come in as verified; others come in
/// unverified and need the host's approval.
class SecureTransport implements Transport {
  /// Wraps [_inner] with the room's [_keys].
  SecureTransport(this._inner, this._keys) {
    _inner.connections.listen(
      (raw) => unawaited(_accept(raw)),
      onDone: () => unawaited(_incoming.close()),
    );
  }

  final Transport _inner;
  final HostKeys _keys;
  final _incoming = StreamController<Connection>();

  @override
  Stream<Connection> get connections => _incoming.stream;

  Future<void> _accept(Connection raw) async {
    final frames = StreamIterator(raw.messages);
    try {
      if (!await frames.moveNext().timeout(handshakeTimeout)) return;
      final hello = frames.current;
      if (hello.length > 1024) throw const NoiseError('hello too large');
      final json = jsonDecode(hello);
      if (json is! Map<String, Object?> || json['noise'] != 1) {
        throw const NoiseError('not a handshake');
      }
      final pattern = switch (json['p']) {
        'nn' => NoisePattern.nn,
        'nkPsk2' => NoisePattern.nkPsk2,
        _ => throw const NoiseError('unknown pattern'),
      };
      final handshake = await NoiseHandshake.responder(
        pattern,
        prologue: utf8.encode('$_prologue ${pattern.name}'),
        staticKeys: pattern == NoisePattern.nkPsk2 ? _keys.keyPair : null,
        psk: pattern == NoisePattern.nkPsk2 ? _keys.roomSecret : null,
      );
      await handshake.readMessage(base64Url.decode(json['m']! as String));
      raw.send(base64Url.encode(await handshake.writeMessage()));
      final (send, receive) = await handshake.split();
      if (_incoming.isClosed) return raw.close();
      _incoming.add(
        SecureConnection._(
          _IteratorConnection(raw, frames),
          send,
          receive,
          verified: pattern == NoisePattern.nkPsk2,
          checkCode: _checkCode(handshake.handshakeHash),
        ),
      );
    } on Object {
      // Wrong secret, garbage or too slow: drop silently.
      await frames.cancel();
      await raw.close();
    }
  }

  @override
  Future<void> close() => _inner.close();
}

/// A connection whose first messages were already read through `_frames`
/// during the handshake; it hands on the rest.
class _IteratorConnection implements Connection {
  _IteratorConnection(this._raw, this._frames);

  final Connection _raw;
  final StreamIterator<String> _frames;

  @override
  Stream<String> get messages {
    final out = StreamController<String>();
    Future<void> pump() async {
      try {
        while (await _frames.moveNext()) {
          out.add(_frames.current);
        }
      } on Object {
        // The wire broke; the stream simply ends.
      }
      await out.close();
    }

    out.onListen = () => unawaited(pump());
    return out.stream;
  }

  @override
  void send(String message) => _raw.send(message);

  @override
  Future<void> close() async {
    await _raw.close();
    unawaited(_frames.cancel());
  }
}
