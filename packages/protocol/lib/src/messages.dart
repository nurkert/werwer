import 'dart:convert';

import 'package:game_core/game_core.dart';
import 'package:protocol/src/reader.dart';
import 'package:protocol/src/view_codec.dart';

/// Version of the message format. Host and player must speak the same one.
const protocolVersion = 1;

/// Largest message a player may send.
const maxClientMessage = 1024;

/// Largest message a host may send.
const int maxHostMessage = 64 * 1024;

/// Room codes are this many digits.
const roomCodeLength = 4;

/// Session tokens are this many hex characters (128 bit).
const tokenLength = 32;

final _playerId = RegExp(r'^[a-z0-9]{1,16}$');
final _digits = RegExp(r'^[0-9]+$');
final _hex = RegExp(r'^[0-9a-f]+$');

PlayerId _readPlayerId(JsonReader json, String key) {
  final value = json.string(key, max: 16);
  if (!_playerId.hasMatch(value)) throw ProtocolError('bad id "$key"');
  return PlayerId(value);
}

String _readToken(JsonReader json, String key) {
  final value = json.string(key, max: tokenLength);
  if (value.length != tokenLength || !_hex.hasMatch(value)) {
    throw const ProtocolError('bad token');
  }
  return value;
}

void _expectVersion(JsonReader json) {
  if (json.integer('v') != protocolVersion) {
    throw const ProtocolError('unsupported version');
  }
}

/// Something a player sends to the host.
sealed class ClientMessage {
  const ClientMessage();

  /// Parses and validates [raw]. Throws a [ProtocolError] for anything that
  /// is not exactly a valid message.
  static ClientMessage parse(String raw) {
    final json = JsonReader.decode(raw, maxBytes: maxClientMessage);
    _expectVersion(json);
    return switch (json.string('type', max: 16)) {
      'hello' => Hello._parse(json),
      'start' => const StartGameIntent(),
      'confirm' => const ConfirmRoleIntent(),
      'night' => NightIntent(_readPlayerId(json, 'target')),
      'vote' => VoteIntent(
        json.maybeString('target') == null
            ? null
            : _readPlayerId(json, 'target'),
      ),
      'endDiscussion' => const EndDiscussionIntent(),
      'kick' => KickIntent(_readPlayerId(json, 'player')),
      'leave' => const LeaveIntent(),
      'rematch' => const RematchIntent(),
      'sheep' => SheepIntent(
        json.integer('count', min: -maxSheepPerNight, max: maxSheepPerNight),
      ),
      _ => throw const ProtocolError('unknown type'),
    };
  }

  /// The JSON fields of this message, without version and type.
  Map<String, Object?> get _fields => const {};

  String get _type;

  /// Encodes this message for sending.
  String encode() =>
      jsonEncode({'v': protocolVersion, 'type': _type, ..._fields});
}

/// First message on every connection: join a room, or come back with a token.
final class Hello extends ClientMessage {
  /// Creates the message.
  const Hello({required this.name, required this.room, this.token});

  factory Hello._parse(JsonReader json) {
    final room = json.string('room', max: roomCodeLength);
    if (room.length != roomCodeLength || !_digits.hasMatch(room)) {
      throw const ProtocolError('bad room');
    }
    return Hello(
      name: json.string('name', max: maxNameLength * 2),
      room: room,
      token: json.maybeString('token') == null
          ? null
          : _readToken(json, 'token'),
    );
  }

  /// Display name for a new player.
  final String name;

  /// The room code shown on the host.
  final String room;

  /// Session token from an earlier `Welcome`, to rejoin as the same player.
  final String? token;

  @override
  String get _type => 'hello';

  @override
  Map<String, Object?> get _fields => {
    'name': name,
    'room': room,
    'token': ?token,
  };
}

/// Room owner: deal the roles and start.
final class StartGameIntent extends ClientMessage {
  /// Creates the message.
  const StartGameIntent();

  @override
  String get _type => 'start';
}

/// I have seen my role.
final class ConfirmRoleIntent extends ClientMessage {
  /// Creates the message.
  const ConfirmRoleIntent();

  @override
  String get _type => 'confirm';
}

/// My pick tonight. The same message for every role, so the network does not
/// tell who is who; the host decides what the pick means.
final class NightIntent extends ClientMessage {
  /// Creates the message.
  const NightIntent(this.target);

  /// Whom I pick.
  final PlayerId target;

  @override
  String get _type => 'night';

  @override
  Map<String, Object?> get _fields => {'target': target.value};
}

/// My vote; `null` abstains.
final class VoteIntent extends ClientMessage {
  /// Creates the message.
  const VoteIntent(this.target);

  /// Whom I vote for.
  final PlayerId? target;

  @override
  String get _type => 'vote';

  @override
  Map<String, Object?> get _fields => {'target': target?.value};
}

/// Room owner: the discussion is over, start the vote.
final class EndDiscussionIntent extends ClientMessage {
  /// Creates the message.
  const EndDiscussionIntent();

  @override
  String get _type => 'endDiscussion';
}

/// Room owner: remove a player from the lobby.
final class KickIntent extends ClientMessage {
  /// Creates the message.
  const KickIntent(this.player);

  /// Who is removed.
  final PlayerId player;

  @override
  String get _type => 'kick';

  @override
  Map<String, Object?> get _fields => {'player': player.value};
}

/// I leave the lobby.
final class LeaveIntent extends ClientMessage {
  /// Creates the message.
  const LeaveIntent();

  @override
  String get _type => 'leave';
}

/// How many sheep I have counted tonight (running total).
final class SheepIntent extends ClientMessage {
  /// Creates the message.
  const SheepIntent(this.count);

  /// Tonight's running total.
  final int count;

  @override
  String get _type => 'sheep';

  @override
  Map<String, Object?> get _fields => {'count': count};
}

/// Room owner: after a game, play again with the same players.
final class RematchIntent extends ClientMessage {
  /// Creates the message.
  const RematchIntent();

  @override
  String get _type => 'rematch';
}

/// Why the host ends a connection.
enum ByeReason {
  /// The room code was wrong.
  wrongRoom,

  /// The game already started; only known players can come back.
  gameRunning,

  /// The token is unknown.
  unknownSession,

  /// The name was refused or the room is full.
  refused,

  /// The room owner removed this player.
  kicked,

  /// The player left.
  left,

  /// The same player connected again from elsewhere.
  replaced,

  /// The room was closed.
  closed,

  /// The connection broke the rules (too many or bad messages).
  misbehaved,
}

/// Something the host sends to a player.
sealed class HostMessage {
  const HostMessage();

  /// Parses and validates [raw]. Throws a [ProtocolError] for anything that
  /// is not exactly a valid message.
  static HostMessage parse(String raw) {
    final json = JsonReader.decode(raw, maxBytes: maxHostMessage);
    _expectVersion(json);
    return switch (json.string('type', max: 16)) {
      'welcome' => Welcome(
        token: _readToken(json, 'token'),
        you: _readPlayerId(json, 'you'),
      ),
      'state' => StateMessage(
        view: decodeView(json.object('view')),
        isOwner: json.boolean('owner'),
        phaseEndsInMs: json.maybeInteger('endsIn'),
      ),
      'refused' => Refused(json.enumValue('reason', Violation.values)),
      'bye' => Bye(json.enumValue('reason', ByeReason.values)),
      _ => throw const ProtocolError('unknown type'),
    };
  }

  String get _type;

  Map<String, Object?> get _fields;

  /// Encodes this message for sending.
  String encode() =>
      jsonEncode({'v': protocolVersion, 'type': _type, ..._fields});
}

/// You are in: keep the token to come back after a disconnect.
final class Welcome extends HostMessage {
  /// Creates the message.
  const Welcome({required this.token, required this.you});

  /// Secret session token. Never log or show it.
  final String token;

  /// Your player id.
  final PlayerId you;

  @override
  String get _type => 'welcome';

  @override
  Map<String, Object?> get _fields => {'token': token, 'you': you.value};
}

/// The game as you may see it.
final class StateMessage extends HostMessage {
  /// Creates the message.
  const StateMessage({
    required this.view,
    required this.isOwner,
    this.phaseEndsInMs,
  });

  /// Your filtered view.
  final PlayerView view;

  /// Whether you opened the room (may start, kick and end the discussion).
  final bool isOwner;

  /// Milliseconds until the phase timer runs out, if one runs.
  final int? phaseEndsInMs;

  @override
  String get _type => 'state';

  @override
  Map<String, Object?> get _fields => {
    'view': encodeView(view),
    'owner': isOwner,
    'endsIn': ?phaseEndsInMs,
  };
}

/// Your last intent was refused; nothing changed.
final class Refused extends HostMessage {
  /// Creates the message.
  const Refused(this.reason);

  /// Why.
  final Violation reason;

  @override
  String get _type => 'refused';

  @override
  Map<String, Object?> get _fields => {'reason': reason.name};
}

/// The host ends this connection.
final class Bye extends HostMessage {
  /// Creates the message.
  const Bye(this.reason);

  /// Why.
  final ByeReason reason;

  @override
  String get _type => 'bye';

  @override
  Map<String, Object?> get _fields => {'reason': reason.name};
}
