import 'dart:convert';

import 'package:protocol/src/messages.dart';
import 'package:protocol/src/reader.dart';

/// Version of the relay framing between a host and a relay server.
const relayVersion = 1;

/// Characters of relay room ids: lower case without look-alikes.
const relayAlphabet = 'abcdefghjkmnpqrstuvwxyz23456789';

/// Relay room ids are this long (about 40 bits).
const relayRoomIdLength = 8;

/// Most players one relay room forwards to its host.
const maxRelayPeers = 24;

final _roomId = RegExp('^[$relayAlphabet]{$relayRoomIdLength}\$');

/// Whether [id] is a well-formed relay room id.
bool isRelayRoomId(String id) => _roomId.hasMatch(id);

/// A frame between a host and the relay server. Players do not see frames:
/// they talk the normal game protocol, the server wraps and unwraps it. The
/// server never parses game messages and knows nothing about the game.
sealed class RelayFrame {
  const RelayFrame();

  /// Parses and validates [raw]; throws a [ProtocolError] if invalid.
  static RelayFrame parse(String raw) {
    final json = JsonReader.decode(raw, maxBytes: maxHostMessage + 256);
    if (json.integer('rv') != relayVersion) {
      throw const ProtocolError('unsupported relay version');
    }
    int peer() => json.integer('peer', max: 1 << 30);
    return switch (json.string('t', max: 8)) {
      'room' => RoomOpened(_readRoomId(json)),
      'join' => PeerJoined(peer()),
      'data' => PeerData(peer(), json.string('d', max: maxHostMessage)),
      'left' => PeerLeft(peer()),
      _ => throw const ProtocolError('unknown frame'),
    };
  }

  String get _type;

  Map<String, Object?> get _fields;

  /// Encodes this frame for sending.
  String encode() => jsonEncode({'rv': relayVersion, 't': _type, ..._fields});
}

String _readRoomId(JsonReader json) {
  final id = json.string('room', max: relayRoomIdLength);
  if (!isRelayRoomId(id)) throw const ProtocolError('bad room id');
  return id;
}

/// Server → host: your room is open under [roomId].
final class RoomOpened extends RelayFrame {
  /// Creates the frame.
  const RoomOpened(this.roomId);

  /// The id players use to reach this host through the server.
  final String roomId;

  @override
  String get _type => 'room';

  @override
  Map<String, Object?> get _fields => {'room': roomId};
}

/// Server → host: a player connected; [peer] numbers the connection.
final class PeerJoined extends RelayFrame {
  /// Creates the frame.
  const PeerJoined(this.peer);

  /// Connection number within the room.
  final int peer;

  @override
  String get _type => 'join';

  @override
  Map<String, Object?> get _fields => {'peer': peer};
}

/// Either way: one game message from or to [peer].
final class PeerData extends RelayFrame {
  /// Creates the frame.
  const PeerData(this.peer, this.data);

  /// Connection number within the room.
  final int peer;

  /// The game protocol message, untouched.
  final String data;

  @override
  String get _type => 'data';

  @override
  Map<String, Object?> get _fields => {'peer': peer, 'd': data};
}

/// Either way: the connection to [peer] ended (or the host ends it).
final class PeerLeft extends RelayFrame {
  /// Creates the frame.
  const PeerLeft(this.peer);

  /// Connection number within the room.
  final int peer;

  @override
  String get _type => 'left';

  @override
  Map<String, Object?> get _fields => {'peer': peer};
}
