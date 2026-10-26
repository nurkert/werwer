import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

// A small, strict implementation of the Noise Protocol Framework (revision
// 34, https://noiseprotocol.org/noise.html) for exactly two handshake
// patterns, with Curve25519, ChaChaPoly and BLAKE2s. All primitives come from
// the `cryptography` package; this file only does the Noise state machine
// and is checked against the official test vectors.

const _dhLen = 32;
const _hashLen = 32;
const _tagLen = 16;

/// Messages per direction before the key would repeat a nonce (the spec
/// allows 2^64 - 1; Dart integers stop at 2^63 - 1).
const maxNonce = 0x7fffffffffffffff;

/// Largest Noise message (spec: 65535 bytes).
const maxNoiseMessage = 65535;

/// The handshake patterns Whowolf uses.
enum NoisePattern {
  /// No static keys: encryption without authentication. Used when joining
  /// without the QR code; the players compare a check code instead.
  nn('Noise_NN_25519_ChaChaPoly_BLAKE2s'),

  /// The initiator knows the responder's static key (from the QR code) and
  /// both share a pre-shared key (the room secret from the QR code).
  nkPsk2('Noise_NKpsk2_25519_ChaChaPoly_BLAKE2s');

  const NoisePattern(this.protocolName);

  /// The Noise protocol name.
  final String protocolName;
}

/// A handshake or decryption failed: the peer is not who it claims to be, or
/// the data was tampered with. The connection must be closed.
class NoiseError implements Exception {
  /// Creates the error.
  const NoiseError(this.message);

  /// What went wrong.
  final String message;

  @override
  String toString() => 'NoiseError: $message';
}

final _x25519 = X25519();
final _aead = Chacha20.poly1305Aead();
final _blake2s = Blake2s();

/// BLAKE2s works on 64-byte blocks. The `cryptography` package reports 32 for
/// Blake2s, so its `Hmac(Blake2s())` is not the standard HMAC that Noise
/// needs; HMAC is therefore built here exactly as in RFC 2104.
const _blake2sBlock = 64;

Future<Uint8List> _hash(List<int> data) async =>
    Uint8List.fromList((await _blake2s.hash(data)).bytes);

Future<Uint8List> _hmacOf(List<int> key, List<int> data) async {
  final k = Uint8List(_blake2sBlock)
    ..setAll(0, key.length > _blake2sBlock ? await _hash(key) : key);
  final inner = await _hash([for (final b in k) b ^ 0x36, ...data]);
  return _hash([for (final b in k) b ^ 0x5c, ...inner]);
}

/// Noise HKDF with two or three outputs.
Future<List<Uint8List>> _hkdf(List<int> ck, List<int> ikm, int outputs) async {
  final temp = await _hmacOf(ck, ikm);
  final out1 = await _hmacOf(temp, [1]);
  final out2 = await _hmacOf(temp, [...out1, 2]);
  if (outputs == 2) return [out1, out2];
  final out3 = await _hmacOf(temp, [...out2, 3]);
  return [out1, out2, out3];
}

Future<Uint8List> _dh(SimpleKeyPair own, List<int> remote) async {
  final secret = await _x25519.sharedSecretKey(
    keyPair: own,
    remotePublicKey: SimplePublicKey(remote, type: KeyPairType.x25519),
  );
  return Uint8List.fromList(await secret.extractBytes());
}

/// Encrypts or decrypts with one key and a running nonce.
class NoiseCipher {
  NoiseCipher._([this._key]);

  List<int>? _key;
  int _nonce = 0;

  List<int> _nonceBytes() {
    // 32 bits of zeros, then the 64-bit counter little-endian.
    final bytes = ByteData(12)..setUint64(4, _nonce, Endian.little);
    return bytes.buffer.asUint8List();
  }

  /// Encrypts [plaintext] with associated data [ad].
  Future<Uint8List> encrypt(
    List<int> plaintext, [
    List<int> ad = const [],
  ]) async {
    final key = _key;
    if (key == null) return Uint8List.fromList(plaintext);
    if (_nonce >= maxNonce) throw const NoiseError('nonce exhausted');
    final box = await _aead.encrypt(
      plaintext,
      secretKey: SecretKey(key),
      nonce: _nonceBytes(),
      aad: ad,
    );
    _nonce++;
    return Uint8List.fromList([...box.cipherText, ...box.mac.bytes]);
  }

  /// Decrypts [ciphertext]; throws a [NoiseError] if it was tampered with.
  Future<Uint8List> decrypt(
    List<int> ciphertext, [
    List<int> ad = const [],
  ]) async {
    final key = _key;
    if (key == null) return Uint8List.fromList(ciphertext);
    if (ciphertext.length < _tagLen) throw const NoiseError('too short');
    final split = ciphertext.length - _tagLen;
    try {
      final plain = await _aead.decrypt(
        SecretBox(
          ciphertext.sublist(0, split),
          nonce: _nonceBytes(),
          mac: Mac(ciphertext.sublist(split)),
        ),
        secretKey: SecretKey(key),
        aad: ad,
      );
      _nonce++;
      return Uint8List.fromList(plain);
    } on SecretBoxAuthenticationError {
      throw const NoiseError('authentication failed');
    }
  }
}

class _SymmetricState {
  _SymmetricState._(this._ck, this._h);

  static Future<_SymmetricState> create(String protocolName) async {
    final name = protocolName.codeUnits;
    final h = name.length <= _hashLen
        ? (Uint8List(_hashLen)..setRange(0, name.length, name))
        : await _hash(name);
    return _SymmetricState._(Uint8List.fromList(h), h);
  }

  Uint8List _ck;
  Uint8List _h;
  final cipher = NoiseCipher._();

  Future<void> mixKey(List<int> ikm) async {
    final out = await _hkdf(_ck, ikm, 2);
    _ck = out[0];
    cipher
      .._key = out[1]
      .._nonce = 0;
  }

  Future<void> mixHash(List<int> data) async {
    _h = await _hash([..._h, ...data]);
  }

  Future<void> mixKeyAndHash(List<int> ikm) async {
    final out = await _hkdf(_ck, ikm, 3);
    _ck = out[0];
    await mixHash(out[1]);
    cipher
      .._key = out[2]
      .._nonce = 0;
  }

  Future<Uint8List> encryptAndHash(List<int> plaintext) async {
    final c = await cipher.encrypt(plaintext, _h);
    await mixHash(c);
    return c;
  }

  Future<Uint8List> decryptAndHash(List<int> ciphertext) async {
    final p = await cipher.decrypt(ciphertext, _h);
    await mixHash(ciphertext);
    return p;
  }

  Future<(NoiseCipher, NoiseCipher)> split() async {
    final out = await _hkdf(_ck, const [], 2);
    return (NoiseCipher._(out[0]), NoiseCipher._(out[1]));
  }
}

enum _Token { e, s, ee, es, psk }

const Map<NoisePattern, List<List<_Token>>> _patterns = {
  NoisePattern.nn: [
    [_Token.e],
    [_Token.e, _Token.ee],
  ],
  NoisePattern.nkPsk2: [
    [_Token.e, _Token.es],
    [_Token.e, _Token.ee, _Token.psk],
  ],
};

/// One side of a Noise handshake. Write and read messages in turn (the
/// initiator writes first) until [isComplete], then [split].
class NoiseHandshake {
  NoiseHandshake._(
    this.pattern,
    this._initiator,
    this._symmetric, {
    SimpleKeyPair? staticKeys,
    List<int>? remoteStatic,
    this._psk = const [],
    SimpleKeyPair? ephemeral,
  }) : _s = staticKeys,
       _rs = remoteStatic,
       _fixedEphemeral = ephemeral;

  /// The connecting side. For [NoisePattern.nkPsk2], [remoteStatic] is the
  /// host's public key and [psk] the 32-byte room secret.
  static Future<NoiseHandshake> initiator(
    NoisePattern pattern, {
    List<int> prologue = const [],
    List<int>? remoteStatic,
    List<int>? psk,
    SimpleKeyPair? ephemeral,
  }) async {
    if (pattern == NoisePattern.nkPsk2 &&
        (remoteStatic?.length != _dhLen || psk?.length != 32)) {
      throw ArgumentError('NKpsk2 needs the host key and a 32-byte secret');
    }
    final symmetric = await _SymmetricState.create(pattern.protocolName);
    await symmetric.mixHash(prologue);
    if (pattern == NoisePattern.nkPsk2) await symmetric.mixHash(remoteStatic!);
    return NoiseHandshake._(
      pattern,
      true,
      symmetric,
      remoteStatic: remoteStatic,
      psk: psk ?? const [],
      ephemeral: ephemeral,
    );
  }

  /// The accepting side (the host). For [NoisePattern.nkPsk2], [staticKeys]
  /// is the host's key pair and [psk] the room secret.
  static Future<NoiseHandshake> responder(
    NoisePattern pattern, {
    List<int> prologue = const [],
    SimpleKeyPair? staticKeys,
    List<int>? psk,
    SimpleKeyPair? ephemeral,
  }) async {
    if (pattern == NoisePattern.nkPsk2 &&
        (staticKeys == null || psk?.length != 32)) {
      throw ArgumentError('NKpsk2 needs the host keys and a 32-byte secret');
    }
    final symmetric = await _SymmetricState.create(pattern.protocolName);
    await symmetric.mixHash(prologue);
    if (pattern == NoisePattern.nkPsk2) {
      await symmetric.mixHash((await staticKeys!.extractPublicKey()).bytes);
    }
    return NoiseHandshake._(
      pattern,
      false,
      symmetric,
      staticKeys: staticKeys,
      psk: psk ?? const [],
      ephemeral: ephemeral,
    );
  }

  /// The pattern in use.
  final NoisePattern pattern;
  final bool _initiator;
  final _SymmetricState _symmetric;
  final SimpleKeyPair? _s;
  final SimpleKeyPair? _fixedEphemeral;
  final List<int> _psk;
  late SimpleKeyPair _e;
  final List<int>? _rs;
  late List<int> _re;
  int _step = 0;

  bool get _hasPsk => pattern == NoisePattern.nkPsk2;

  /// Whether all handshake messages have been exchanged.
  bool get isComplete => _step >= _patterns[pattern]!.length;

  /// Whether it is this side's turn to write.
  bool get isMyTurn => (_step.isEven) == _initiator;

  /// The handshake hash: identical on both sides after a successful
  /// handshake, so it can derive a check code.
  Uint8List get handshakeHash => _symmetric._h;

  Future<void> _dhToken(_Token token) async {
    final local = token == _Token.ee || (token == _Token.es && _initiator)
        ? _e
        : _s!;
    final remote = token == _Token.ee || (token == _Token.es && !_initiator)
        ? _re
        : _rs!;
    await _symmetric.mixKey(await _dh(local, remote));
  }

  /// Writes the next handshake message carrying [payload].
  Future<Uint8List> writeMessage([List<int> payload = const []]) async {
    if (isComplete || !isMyTurn) throw const NoiseError('not my turn');
    final out = <int>[];
    for (final token in _patterns[pattern]![_step]) {
      switch (token) {
        case _Token.e:
          final e = _fixedEphemeral ?? await _x25519.newKeyPair();
          _e = e;
          final pub = (await e.extractPublicKey()).bytes;
          out.addAll(pub);
          await _symmetric.mixHash(pub);
          if (_hasPsk) await _symmetric.mixKey(pub);
        case _Token.s:
          throw const NoiseError('unsupported token');
        case _Token.ee || _Token.es:
          await _dhToken(token);
        case _Token.psk:
          await _symmetric.mixKeyAndHash(_psk);
      }
    }
    out.addAll(await _symmetric.encryptAndHash(payload));
    _step++;
    return Uint8List.fromList(out);
  }

  /// Reads the next handshake message; returns its payload. Throws a
  /// [NoiseError] if the peer is not authentic.
  Future<Uint8List> readMessage(List<int> message) async {
    if (isComplete || isMyTurn) throw const NoiseError('not their turn');
    if (message.length > maxNoiseMessage) throw const NoiseError('too long');
    var offset = 0;
    for (final token in _patterns[pattern]![_step]) {
      switch (token) {
        case _Token.e:
          if (message.length < offset + _dhLen) {
            throw const NoiseError('too short');
          }
          final re = message.sublist(offset, offset + _dhLen);
          offset += _dhLen;
          _re = re;
          await _symmetric.mixHash(re);
          if (_hasPsk) await _symmetric.mixKey(re);
        case _Token.s:
          throw const NoiseError('unsupported token');
        case _Token.ee || _Token.es:
          await _dhToken(token);
        case _Token.psk:
          await _symmetric.mixKeyAndHash(_psk);
      }
    }
    final payload = await _symmetric.decryptAndHash(message.sublist(offset));
    _step++;
    return payload;
  }

  /// The two transport ciphers: (to send, to receive) from this side's view.
  Future<(NoiseCipher send, NoiseCipher receive)> split() async {
    if (!isComplete) throw const NoiseError('handshake not complete');
    final (c1, c2) = await _symmetric.split();
    return _initiator ? (c1, c2) : (c2, c1);
  }
}
