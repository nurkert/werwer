import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:game_host/game_host.dart';
import 'package:sodium/sodium.dart';

// Everything cryptographic here is a documented libsodium construction:
//
// * crypto_kx: the player's fresh key pair and the room's key pair give two
//   session keys (one per direction). Only the holder of the room key can
//   derive them, so the host is authenticated by its public key.
// * crypto_generichash (keyed BLAKE2b): binds the room secret from the QR
//   code into both session keys, so only invited players get a working
//   channel; also hashes the commitment and the check code.
// * crypto_secretstream_xchacha20poly1305: one stream per direction with
//   its own nonces, ordering and tamper detection.
//
// Handshake (version 3), all frames are text. N is 32 fresh random bytes
// from the host for this one connection.
//
//   QR code (host key S and room secret known):
//     player → host  {"secure":3,"p":"qr","e":E}
//     host → player  {"n":N}
//     player → host  header, confirm
//     host → player  header, confirm
//
//   Without QR code (players compare the check code):
//     player → host  {"secure":3,"p":"nn","c":H(E)}
//     host → player  {"s":S,"n":N}
//     player → host  {"e":E}, header, confirm
//     host → player  header, confirm
//
// N goes into both direction keys and into the check code. So a recorded
// connection is worthless later (the replayed confirm does not match a new
// N), and the check code depends on something fresh from the host that
// comes after the player's commitment H(E): a man in the middle cannot
// compute keys that give both sides the same code in advance, only guess
// online (1 in 16^4 per try), and the host lets few such tries in.

const _version = 3;

/// Plaintexts are padded to one of these sizes, so message sizes say
/// nothing about their content (e.g. whether someone is a werewolf).
const paddingSteps = [512, 2048, 8192, 32768, 65000];

/// The host pads everything it sends to at least this size: every view of
/// the game fits, so a werewolf's state (with the pack's picks) looks just
/// like a villager's on the wire.
const hostPadding = 8192;

/// Largest frame accepted from the wire (base64 of the largest step).
const maxFrame = 90000;

/// How long a peer may take for the handshake.
const handshakeTimeout = Duration(seconds: 5);

/// Bytes of the host's fresh value per connection.
const _nonceBytes = 32;

/// At most this many handshakes without the QR code start per minute: a
/// man in the middle would need tens of thousands of tries to match a
/// check code, a table needs a few.
const maxUncheckedJoinsPerMinute = 12;

/// At most this many handshakes run at once; more connections are closed
/// right away, so half-open sockets cannot pile up on the host.
const maxHandshakes = 16;

/// Number of different symbols in a check code.
const checkSymbols = 16;

/// Symbols in a check code.
const checkLength = 4;

/// A handshake or decryption failed: the peer is not who it claims to be, or
/// the data was tampered with. The connection must be closed.
class SecureChannelError implements Exception {
  /// Creates the error.
  const SecureChannelError(this.message);

  /// What went wrong.
  final String message;

  @override
  String toString() => 'SecureChannelError: $message';
}

Future<Sodium>? _sodium;

/// libsodium, loaded once (natively bundled; sodium.js on the web).
Future<Sodium> loadSodium() => _sodium ??= Future(SodiumInit.init);

/// The keys of one room: a key pair and a room secret, both shown only in
/// the QR code at the table.
class HostKeys {
  HostKeys._(this._seed, this._keyPair, this.roomSecret);

  factory HostKeys._fromSeed(
    Sodium sodium,
    Uint8List seed,
    Uint8List secret,
  ) {
    final seedKey = SecureKey.fromList(sodium, seed);
    try {
      return HostKeys._(seed, sodium.crypto.kx.seedKeyPair(seedKey), secret);
    } finally {
      seedKey.dispose();
    }
  }

  /// New random keys for a new room.
  static Future<HostKeys> generate() async {
    final sodium = await loadSodium();
    return HostKeys._fromSeed(
      sodium,
      sodium.randombytes.buf(sodium.crypto.kx.seedBytes),
      sodium.randombytes.buf(32),
    );
  }

  /// Keys saved with [toJson], e.g. to restore a room after a crash.
  static Future<HostKeys> fromJson(Map<String, Object?> json) async {
    final seed = base64Url.decode(json['seed']! as String);
    final secret = base64Url.decode(json['secret']! as String);
    final sodium = await loadSodium();
    if (seed.length != sodium.crypto.kx.seedBytes || secret.length != 32) {
      throw const FormatException('bad host keys');
    }
    return HostKeys._fromSeed(sodium, seed, secret);
  }

  final Uint8List _seed;
  final KeyPair _keyPair;

  /// The public key for the QR code.
  Uint8List get publicKey => _keyPair.publicKey;

  /// The room secret for the QR code.
  final Uint8List roomSecret;

  /// The keys as JSON, including the private seed: store on this device only.
  Future<Map<String, Object?>> toJson() async => {
    'seed': base64Url.encode(_seed),
    'secret': base64Url.encode(roomSecret),
  };
}

Uint8List _label(String text) => utf8.encode('whowolf-secure-$_version $text');

Uint8List _concat(List<List<int>> parts) =>
    Uint8List.fromList([for (final p in parts) ...p]);

/// The send key for one direction: the crypto_kx key, keyed with the room
/// secret if there is one.
SecureKey _directionKey(
  Sodium sodium,
  SecureKey kxKey,
  String direction,
  List<int> nonce,
  List<int>? roomSecret,
) {
  final secret = roomSecret == null
      ? null
      : SecureKey.fromList(sodium, Uint8List.fromList(roomSecret));
  try {
    final bytes = kxKey.runUnlockedSync(
      (key) => sodium.crypto.genericHash(
        message: _concat([_label(direction), nonce, key]),
        outLen: sodium.crypto.secretStream.keyBytes,
        key: secret,
      ),
    );
    return SecureKey.fromList(sodium, bytes);
  } finally {
    secret?.dispose();
    kxKey.dispose();
  }
}

Uint8List _commitment(Sodium sodium, List<int> playerKey) => sodium.crypto
    .genericHash(message: _concat([_label('commit'), playerKey]), outLen: 32);

List<int> _checkCode(
  Sodium sodium,
  List<int> playerKey,
  List<int> hostKey,
  List<int> nonce,
) {
  final hash = sodium.crypto.genericHash(
    message: _concat([_label('check'), playerKey, hostKey, nonce]),
    outLen: 16,
  );
  return [for (var i = 0; i < checkLength; i++) hash[i] % checkSymbols];
}

Uint8List _pad(String message, {int minimum = 0}) {
  final data = utf8.encode(message);
  final needed = max(data.length + 4, minimum);
  final size = paddingSteps.firstWhere(
    (s) => s >= needed,
    orElse: () => throw const SecureChannelError('message too large'),
  );
  final out = Uint8List(size);
  ByteData.sublistView(out).setUint32(0, data.length);
  out.setAll(4, data);
  return out;
}

String _unpad(Uint8List padded) {
  if (!paddingSteps.contains(padded.length)) {
    throw const SecureChannelError('bad padding');
  }
  final length = ByteData.sublistView(padded).getUint32(0);
  if (length > padded.length - 4) {
    throw const SecureChannelError('bad padding');
  }
  return utf8.decode(padded.sublist(4, 4 + length));
}

Uint8List _decodeFrame(String frame) {
  if (frame.length > maxFrame) throw const SecureChannelError('too long');
  return base64Url.decode(frame);
}

/// Both directions of encrypted frames: one secretstream each way.
class _Streams {
  _Streams(
    Sodium sodium,
    Connection wire,
    StreamIterator<String> frames, {
    required SecureKey sendKey,
    required SecureKey receiveKey,
  }) : _wire = wire,
       _frames = frames {
    final stream = sodium.crypto.secretStream;
    _push.stream
        .transform(stream.createPushEx(sendKey))
        .listen((cipher) => _wire.send(base64Url.encode(cipher.message)));
    // Both transformers copy their key when they are listened to, so listen
    // before the keys are wiped.
    _pull.stream
        .transform(stream.createPullEx(receiveKey, requireFinalized: false))
        .listen(
          (plain) => _plain.add(plain.message),
          onError: _plain.addError,
          onDone: _plain.close,
        );
    sendKey.dispose();
    receiveKey.dispose();
  }

  final Connection _wire;
  final StreamIterator<String> _frames;
  final _push = StreamController<SecretStreamPlainMessage>();
  final _pull = StreamController<SecretStreamCipherMessage>();
  final _plain = StreamController<Uint8List>();

  /// The handshake's confirm message, bound to the protocol version.
  static final Uint8List _confirm = _label('confirm');

  void sendConfirm() => _push.add(
    SecretStreamPlainMessage(_confirm, additionalData: _confirm),
  );

  void send(Uint8List data) => _push.add(SecretStreamPlainMessage(data));

  /// Reads the peer's header and confirm message from the wire: only the
  /// right keys decrypt it.
  Future<StreamIterator<Uint8List>> receiveConfirm() async {
    final plain = StreamIterator(_plain.stream);
    for (var i = 0; i < 2; i++) {
      if (!await _frames.moveNext()) {
        throw const SecureChannelError('connection closed');
      }
      _pull.add(
        SecretStreamCipherMessage(
          _decodeFrame(_frames.current),
          additionalData: i == 1 ? _confirm : null,
        ),
      );
    }
    if (!await plain.moveNext()) throw const SecureChannelError('no confirm');
    if (!_same(plain.current, _confirm)) {
      throw const SecureChannelError('bad confirm');
    }
    return plain;
  }

  /// Feeds the rest of the wire into the decryption.
  void pump() {
    unawaited(() async {
      try {
        while (await _frames.moveNext()) {
          // Closed from our side while a frame was on its way.
          if (_pull.isClosed) return;
          _pull.add(SecretStreamCipherMessage(_decodeFrame(_frames.current)));
        }
      } on Object catch (error) {
        if (!_pull.isClosed) _pull.addError(error);
      }
      await _pull.close();
    }());
  }

  Future<void> close() async {
    await _push.close();
    await _pull.close();
  }
}

bool _same(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}

/// An encrypted [Connection]: every message is padded and encrypted with
/// keys only the two ends know. A relay or eavesdropper sees same-sized
/// noise.
class SecureConnection implements Connection, PeerTrust {
  SecureConnection._(
    this._wire,
    this._streams,
    StreamIterator<Uint8List> plain, {
    required this.verified,
    required this.checkCode,
    this.hostKey,
  }) {
    unawaited(_read(plain));
    _streams.pump();
  }

  final Connection _wire;
  final _Streams _streams;
  final _messages = StreamController<String>();
  bool _closed = false;

  @override
  final bool verified;

  @override
  final List<int> checkCode;

  /// The host's public key as seen in the handshake (player side only).
  /// After the host let this player in, it is the authentic room key.
  final Uint8List? hostKey;

  @override
  List<int>? get peerKey => hostKey;

  @override
  Stream<String> get messages => _messages.stream;

  Future<void> _read(StreamIterator<Uint8List> plain) async {
    try {
      while (await plain.moveNext()) {
        if (_closed) return;
        _messages.add(_unpad(plain.current));
      }
    } on Object {
      // Tampered, replayed, reordered or garbage: not trustworthy anymore.
    }
    await _close();
  }

  @override
  void send(String message) {
    if (_closed) return;
    try {
      // The host's messages all share one size; a player's stay small.
      _streams.send(_pad(message, minimum: hostKey == null ? hostPadding : 0));
    } on SecureChannelError {
      unawaited(_close());
    }
  }

  Future<void> _close() async {
    if (_closed) return;
    _closed = true;
    await _wire.close();
    unawaited(_streams.close());
    unawaited(_messages.close());
  }

  @override
  Future<void> close() => _close();
}

/// Opens an encrypted channel to the host over [raw]. With [hostKey] and
/// [roomSecret] (from the QR code) the host is authenticated and the channel
/// is [SecureConnection.verified]; without them the channel is encrypted but
/// the players must compare the check code.
///
/// Throws a [SecureChannelError] if the host is not who the QR code says.
Future<SecureConnection> connectSecure(
  Connection raw, {
  List<int>? hostKey,
  List<int>? roomSecret,
  Duration timeout = handshakeTimeout,
}) async {
  final sodium = await loadSodium();
  final kx = sodium.crypto.kx;
  final qr = hostKey != null && roomSecret != null;
  if (qr && (hostKey.length != kx.publicKeyBytes || roomSecret.length != 32)) {
    throw ArgumentError('the QR code needs the host key and a 32-byte secret');
  }
  final mine = kx.keyPair();
  final frames = StreamIterator(raw.messages);
  try {
    return await () async {
      final Uint8List serverKey;
      final Uint8List nonce;
      Future<String> next() async {
        if (!await frames.moveNext()) {
          throw const SecureChannelError('host closed the connection');
        }
        return frames.current;
      }

      if (qr) {
        serverKey = Uint8List.fromList(hostKey);
        raw.send(
          jsonEncode({
            'secure': _version,
            'p': 'qr',
            'e': base64Url.encode(mine.publicKey),
          }),
        );
        nonce = _readKey(await next(), 'n', _nonceBytes);
      } else {
        raw.send(
          jsonEncode({
            'secure': _version,
            'p': 'nn',
            'c': base64Url.encode(_commitment(sodium, mine.publicKey)),
          }),
        );
        final reply = await next();
        serverKey = _readKey(reply, 's', kx.publicKeyBytes);
        nonce = _readKey(reply, 'n', _nonceBytes);
        raw.send(jsonEncode({'e': base64Url.encode(mine.publicKey)}));
      }
      final keys = kx.clientSessionKeys(
        clientPublicKey: mine.publicKey,
        clientSecretKey: mine.secretKey,
        serverPublicKey: serverKey,
      );
      final secret = qr ? roomSecret : null;
      final streams = _Streams(
        sodium,
        raw,
        frames,
        sendKey: _directionKey(sodium, keys.tx, 'to host', nonce, secret),
        receiveKey: _directionKey(sodium, keys.rx, 'to player', nonce, secret),
      )..sendConfirm();
      final plain = await streams.receiveConfirm();
      return SecureConnection._(
        raw,
        streams,
        plain,
        verified: qr,
        checkCode: _checkCode(sodium, mine.publicKey, serverKey, nonce),
        hostKey: serverKey,
      );
    }().timeout(timeout);
  } on Object catch (error) {
    await frames.cancel();
    await raw.close();
    if (error is SecureChannelError) rethrow;
    throw SecureChannelError('handshake failed: $error');
  } finally {
    mine.secretKey.dispose();
  }
}

Uint8List _readKey(String frame, String field, int length) {
  if (frame.length > 1024) throw const SecureChannelError('frame too large');
  final json = jsonDecode(frame);
  final value = json is Map<String, Object?> ? json[field] : null;
  if (value is! String) throw const SecureChannelError('bad handshake');
  final key = base64Url.decode(value);
  if (key.length != length) throw const SecureChannelError('bad key');
  return key;
}

/// Accepts encrypted connections from an inner transport (LAN, relay, …).
/// Peers who show the room secret come in as verified; others come in
/// unverified and need the host's approval.
class SecureTransport implements Transport {
  /// Wraps [_inner] with the room's [_keys]. [clock] (milliseconds) is
  /// injectable for tests.
  SecureTransport(this._inner, this._keys, {int Function()? clock})
    : _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch) {
    _inner.connections.listen(
      (raw) => unawaited(_accept(raw)),
      onDone: () => unawaited(_incoming.close()),
    );
  }

  final Transport _inner;
  final HostKeys _keys;
  final int Function() _clock;
  final _incoming = StreamController<Connection>();

  /// When the recent handshakes without QR code started.
  final _unchecked = <int>[];

  /// Whether one more handshake without QR code may start now.
  bool _allowUnchecked() {
    final now = _clock();
    _unchecked.removeWhere((at) => now - at > 60000);
    if (_unchecked.length >= maxUncheckedJoinsPerMinute) return false;
    _unchecked.add(now);
    return true;
  }

  @override
  Stream<Connection> get connections => _incoming.stream;

  int _handshakes = 0;

  Future<void> _accept(Connection raw) async {
    if (_handshakes >= maxHandshakes) {
      await raw.close();
      return;
    }
    _handshakes++;
    final frames = StreamIterator(raw.messages);
    try {
      final connection = await _handshake(raw, frames).timeout(
        handshakeTimeout,
      );
      if (_incoming.isClosed) {
        await connection.close();
        return;
      }
      _incoming.add(connection);
    } on Object {
      // Wrong secret, garbage or too slow: drop silently.
      await frames.cancel();
      await raw.close();
    } finally {
      _handshakes--;
    }
  }

  Future<SecureConnection> _handshake(
    Connection raw,
    StreamIterator<String> frames,
  ) async {
    final sodium = await loadSodium();
    final kxBytes = sodium.crypto.kx.publicKeyBytes;
    if (!await frames.moveNext()) throw const SecureChannelError('closed');
    final hello = frames.current;
    if (hello.length > 1024) throw const SecureChannelError('hello too large');
    final json = jsonDecode(hello);
    if (json is! Map<String, Object?> || json['secure'] != _version) {
      throw const SecureChannelError('not a handshake');
    }
    final qr = switch (json['p']) {
      'qr' => true,
      'nn' => false,
      _ => throw const SecureChannelError('unknown pattern'),
    };
    final nonce = sodium.randombytes.buf(_nonceBytes);
    final Uint8List playerKey;
    if (qr) {
      playerKey = _readKey(hello, 'e', kxBytes);
      raw.send(jsonEncode({'n': base64Url.encode(nonce)}));
    } else {
      if (!_allowUnchecked()) throw const SecureChannelError('too many');
      final commitment = _readKey(hello, 'c', 32);
      raw.send(
        jsonEncode({
          's': base64Url.encode(_keys.publicKey),
          'n': base64Url.encode(nonce),
        }),
      );
      if (!await frames.moveNext()) throw const SecureChannelError('closed');
      playerKey = _readKey(frames.current, 'e', kxBytes);
      if (!_same(_commitment(sodium, playerKey), commitment)) {
        throw const SecureChannelError('commitment broken');
      }
    }
    final keys = sodium.crypto.kx.serverSessionKeys(
      serverPublicKey: _keys.publicKey,
      serverSecretKey: _keys._keyPair.secretKey,
      clientPublicKey: playerKey,
    );
    final secret = qr ? _keys.roomSecret : null;
    final streams = _Streams(
      sodium,
      raw,
      frames,
      sendKey: _directionKey(sodium, keys.tx, 'to player', nonce, secret),
      receiveKey: _directionKey(sodium, keys.rx, 'to host', nonce, secret),
    );
    // The player proves the room secret (or, without QR code, just a
    // working key) before the host says anything encrypted.
    final plain = await streams.receiveConfirm();
    streams.sendConfirm();
    return SecureConnection._(
      raw,
      streams,
      plain,
      verified: qr,
      checkCode: _checkCode(sodium, playerKey, _keys.publicKey, nonce),
    );
  }

  @override
  Future<void> close() => _inner.close();
}
