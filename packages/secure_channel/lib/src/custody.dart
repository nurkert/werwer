import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:game_host/game_host.dart';
import 'package:secure_channel/src/channel.dart';
import 'package:sodium/sodium.dart';

// The successor's copy of the room is one crypto_secretstream_xchacha20poly1305
// message with the final tag: the documented way to encrypt a single message
// with a fresh key. The epoch and a label go in as additional data, so a
// sealed room only opens for the takeover it was made for.

/// Seals rooms for a host's successor with libsodium (see [RoomSealer]).
class SodiumSealer implements RoomSealer {
  /// Creates the sealer; the sodium instance comes from [loadSodium].
  SodiumSealer(this._sodium);

  final Sodium _sodium;

  Uint8List _context(int epoch) =>
      utf8.encode('whowolf-custody-1 epoch $epoch');

  @override
  List<int> newKey() {
    final key = _sodium.crypto.secretStream.keygen();
    try {
      return key.extractBytes();
    } finally {
      key.dispose();
    }
  }

  @override
  Future<String> seal(String room, List<int> key, {required int epoch}) async {
    final secure = SecureKey.fromList(_sodium, Uint8List.fromList(key));
    try {
      final parts = await _sodium.crypto.secretStream
          .pushEx(
            messageStream: Stream.value(
              SecretStreamPlainMessage(
                utf8.encode(room),
                additionalData: _context(epoch),
                tag: SecretStreamMessageTag.finalPush,
              ),
            ),
            key: secure,
          )
          .toList();
      // The header, then the one message.
      return parts.map((p) => base64Url.encode(p.message)).join('.');
    } finally {
      secure.dispose();
    }
  }

  @override
  Future<String?> open(
    String sealed,
    List<int> key, {
    required int epoch,
  }) async {
    final parts = sealed.split('.');
    if (parts.length != 2 ||
        key.length != _sodium.crypto.secretStream.keyBytes) {
      return null;
    }
    final secure = SecureKey.fromList(_sodium, Uint8List.fromList(key));
    try {
      final plain = await _sodium.crypto.secretStream
          .pullEx(
            cipherStream: Stream.fromIterable([
              SecretStreamCipherMessage(base64Url.decode(parts[0])),
              SecretStreamCipherMessage(
                base64Url.decode(parts[1]),
                additionalData: _context(epoch),
              ),
            ]),
            key: secure,
          )
          .toList();
      if (plain.length != 1 ||
          plain.single.tag != SecretStreamMessageTag.finalPush) {
        return null;
      }
      return utf8.decode(plain.single.message);
    } on Object {
      // Wrong key, wrong epoch or tampered: it simply does not open.
      return null;
    } finally {
      secure.dispose();
    }
  }
}

/// The successor's entrance: encrypted connections over the inner
/// transport with the candidate's keys. Only those pass that proved the
/// candidate secret (the QR pattern of the handshake): only the witness was
/// told the secret, and only the candidate can complete the handshake for
/// its key, so both ends are authenticated. Everyone else is hung up on.
class CandidateEntrance implements Transport {
  /// Opens the entrance.
  CandidateEntrance(Transport inner, HostKeys keys)
    : _secure = SecureTransport(inner, keys) {
    _secure.connections.listen((connection) {
      if (connection case PeerTrust(verified: true) when !_out.isClosed) {
        _out.add(connection);
      } else {
        unawaited(connection.close());
      }
    }, onDone: () => unawaited(_out.close()));
  }

  final SecureTransport _secure;
  final _out = StreamController<Connection>();

  @override
  Stream<Connection> get connections => _out.stream;

  @override
  Future<void> close() => _secure.close();
}
