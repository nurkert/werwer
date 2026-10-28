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

/// Door codes are this long (about 30 bits), from [relayAlphabet].
const doorCodeLength = 6;

final _doorCode = RegExp('^[$relayAlphabet]{$doorCodeLength}\$');

/// Whether [code] is a well-formed door code (lower case, no spaces).
bool isDoorCode(String code) => _doorCode.hasMatch(code);

/// A door code as a person types it (any case, with spaces or dashes) in
/// its canonical form, or `null` if it cannot be one.
String? normalizeDoorCode(String typed) {
  if (typed.length > 32) return null;
  final code = typed.toLowerCase().replaceAll(RegExp(r'[\s-]'), '');
  return isDoorCode(code) ? code : null;
}

/// A door code for people to read: upper case in two halves (`ABC 234`).
String showDoorCode(String code) {
  final upper = code.toUpperCase();
  return upper.length == doorCodeLength
      ? '${upper.substring(0, 3)} ${upper.substring(3)}'
      : upper;
}

/// The 4-digit room code (as in the hello).
final _roomCode = RegExp('^[0-9]{$roomCodeLength}\$');

/// A web app build's name (as in the server's page path).
final _build = RegExp(r'^[0-9a-z][0-9a-z.-]{0,31}$');

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
      'room' => RoomOpened(
        _readRoomId(json),
        doors: json.maybeBoolean('doors') ?? false,
      ),
      'ask' => DoorAsked(
        room: _matching(json, 'room', _roomCode, roomCodeLength),
        protocol: json.integer('p', min: 1, max: 9999),
        build: _matching(json, 'build', _build, 32),
      ),
      'door' => DoorOpened(
        _matching(json, 'code', _doorCode, doorCodeLength),
        lifetime: Duration(seconds: json.integer('ttl', min: 1, max: 3600)),
      ),
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

String _matching(JsonReader json, String key, RegExp pattern, int max) {
  final value = json.string(key, max: max);
  if (!pattern.hasMatch(value)) throw ProtocolError('bad "$key"');
  return value;
}

/// Server → host: your room is open under [roomId]. With [doors] the
/// server hands out door codes (see [DoorAsked]); older servers leave it
/// out, and older hosts ignore it.
final class RoomOpened extends RelayFrame {
  /// Creates the frame.
  const RoomOpened(this.roomId, {this.doors = false});

  /// The id players use to reach this host through the server.
  final String roomId;

  /// Whether the server gives out door codes for its code page.
  final bool doors;

  @override
  String get _type => 'room';

  @override
  Map<String, Object?> get _fields => {
    'room': roomId,
    if (doors) 'doors': true,
  };
}

/// Host → server: give this room a fresh door code, so people can type it
/// on the server's page instead of scanning the QR code. The server sends
/// them to the page of [protocol] and [build] with the [room] code, never
/// with the room's keys: whoever comes in by code is checked by the game
/// leader like any join without the QR code.
final class DoorAsked extends RelayFrame {
  /// Creates the frame.
  const DoorAsked({
    required this.room,
    required this.protocol,
    required this.build,
  });

  /// The 4-digit room code the players' hello carries.
  final String room;

  /// The host's protocol version (part of the page's path).
  final int protocol;

  /// The host's web app build (part of the page's path).
  final String build;

  @override
  String get _type => 'ask';

  @override
  Map<String, Object?> get _fields => {
    'room': room,
    'p': protocol,
    'build': build,
  };
}

/// Server → host: the room's new door code, valid for [lifetime]. The
/// previous code stays valid until its own time is up.
final class DoorOpened extends RelayFrame {
  /// Creates the frame.
  const DoorOpened(this.code, {required this.lifetime});

  /// The code to show (see [showDoorCode]).
  final String code;

  /// How long the server accepts it.
  final Duration lifetime;

  @override
  String get _type => 'door';

  @override
  Map<String, Object?> get _fields => {
    'code': code,
    'ttl': lifetime.inSeconds,
  };
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
