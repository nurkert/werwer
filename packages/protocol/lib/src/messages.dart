import 'dart:convert';

import 'package:game_core/game_core.dart';
import 'package:protocol/src/reader.dart';
import 'package:protocol/src/settings_codec.dart';
import 'package:protocol/src/view_codec.dart';

/// Version of the message format. Host and player must speak the same one.
///
/// 2: night picks carry a list of targets; hunter's shot, settings and the
/// views for witch, hunter and lovers.
/// 3: door signs (the mark intent, the door sign setting and views).
/// 4: host takeover (candidates in the hello, the room's epoch in the
/// welcome, custody for the successor and the key for the witness).
/// 5: the called night (night mode setting, a step per role), clock
/// sync (times in ping and pong, the phase's start in the state).
/// 6: the narrator's intro (the owner may skip it; when, in the state).
/// 7: ghosts and the runoff (both settings, what ghosts see, the runoff's
/// candidates in the view).
const protocolVersion = 7;

/// Largest clock value a message may carry (milliseconds since the epoch;
/// safely below what JavaScript numbers hold exactly).
const int maxClock = 1125899906842624; // 2^50; no shift: 32 bit on the web

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

List<int>? _readSecret(String? value) {
  if (value == null) return null;
  try {
    final bytes = base64Url.decode(value);
    if (bytes.length == 32) return bytes;
  } on FormatException {
    // Falls through to the error below.
  }
  throw const ProtocolError('bad secret');
}

List<int> _readSign(JsonReader json) => json.integers(
  'sign',
  length: doorSignLength,
  max: doorSignSymbols - 1,
);

/// A player's key pair and secret for taking over the room (see
/// [Custody]): the public half and the secret go to the host, which passes
/// them only to the witness, so the witness can open an authenticated
/// channel to exactly this player.
class Candidate {
  /// Creates a candidate from its public [key] and [secret] (32 bytes each).
  Candidate({required List<int> key, required List<int> secret})
    : key = List.unmodifiable(key),
      secret = List.unmodifiable(secret) {
    if (key.length != 32 || secret.length != 32) {
      throw ArgumentError('a candidate needs a 32-byte key and secret');
    }
  }

  /// The candidate's public key.
  final List<int> key;

  /// The secret a witness shows to the candidate. Never log it.
  final List<int> secret;

  static Candidate? _read(JsonReader json, String key, String secret) {
    final k = json.maybeString(key);
    final s = json.maybeString(secret);
    if (k == null && s == null) return null;
    final keyBytes = _readSecret(k);
    final secretBytes = _readSecret(s);
    if (keyBytes == null || secretBytes == null) {
      throw const ProtocolError('bad candidate');
    }
    return Candidate(key: keyBytes, secret: secretBytes);
  }

  Map<String, Object?> _fields(String key, String secret) => {
    key: base64Url.encode(this.key),
    secret: base64Url.encode(this.secret),
  };
}

/// Largest sealed room in a [Custody] message (base64 characters).
const int maxCustody = 48 * 1024;

/// Largest room epoch (takeovers in one room).
const int maxEpoch = 1 << 20;

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
  static ClientMessage parse(String raw) => parseNumbered(raw).message;

  /// Like [parse], and also returns the intent's sequence number (`seq`),
  /// if the sender numbered it (see [encode]).
  static ({ClientMessage message, int? seq}) parseNumbered(String raw) {
    final json = JsonReader.decode(raw, maxBytes: maxClientMessage);
    _expectVersion(json);
    final seq = json.maybeInteger('seq', min: 1, max: maxSeq);
    return (message: _parseBody(json), seq: seq);
  }

  static ClientMessage _parseBody(JsonReader json) {
    return switch (json.string('type', max: 16)) {
      'ping' => PingIntent(
        json.integer('version', max: maxSeq),
        sent: json.maybeInteger('sent', max: maxClock),
      ),
      'hello' => Hello._parse(json),
      'start' => const StartGameIntent(),
      'confirm' => const ConfirmRoleIntent(),
      'night' => NightIntent.of([
        for (final target in json.strings('targets', max: 2, maxLength: 16))
          if (_playerId.hasMatch(target))
            PlayerId(target)
          else
            throw const ProtocolError('bad id "targets"'),
      ]),
      'shoot' => ShootIntent(
        json.maybeString('target') == null
            ? null
            : _readPlayerId(json, 'target'),
      ),
      'settings' => SettingsIntent(decodeSettings(json.object('settings'))),
      'vote' => VoteIntent(
        json.maybeString('target') == null
            ? null
            : _readPlayerId(json, 'target'),
      ),
      'endDiscussion' => const EndDiscussionIntent(),
      'skipIntro' => const SkipIntroIntent(),
      'kick' => KickIntent(_readPlayerId(json, 'player')),
      'leave' => const LeaveIntent(),
      'rematch' => const RematchIntent(),
      'persona' => PersonaIntent(json.enumValue('persona', Persona.values)),
      'admit' => AdmitIntent(
        json.integer('id', max: 1 << 20),
        admit: json.boolean('ok'),
      ),
      'swap' => SwapSeatsIntent(
        _readPlayerId(json, 'a'),
        _readPlayerId(json, 'b'),
      ),
      'mark' => MarkIntent(_readPlayerId(json, 'target'), _readSign(json)),
      'sheep' => SheepIntent(
        json.integer('count', min: -maxSheepPerNight, max: maxSheepPerNight),
      ),
      _ => throw const ProtocolError('unknown type'),
    };
  }

  /// The JSON fields of this message, without version and type.
  Map<String, Object?> get _fields => const {};

  String get _type;

  /// Encodes this message for sending. Intents carry a [seq] number per
  /// session, so the host applies each exactly once and confirms it.
  String encode({int? seq}) => jsonEncode({
    'v': protocolVersion,
    'type': _type,
    'seq': ?seq,
    ..._fields,
  });
}

/// Largest sequence or state version number.
const int maxSeq = 1099511627776; // 2^40; no shift: 32 bit on the web

/// "I am still here and have seen state [version]": the host answers with
/// the current state if the player missed one. Keeps the link alive.
final class PingIntent extends ClientMessage {
  /// Creates the message.
  const PingIntent(this.version, {this.sent});

  /// The newest state version this player has.
  final int version;

  /// When the player sent it, on its own clock (milliseconds), so the
  /// host's pong can tell the player how its clock stands to the host's.
  final int? sent;

  @override
  String get _type => 'ping';

  @override
  Map<String, Object?> get _fields => {'version': version, 'sent': ?sent};
}

/// First message on every connection: join a room, or come back with a token.
final class Hello extends ClientMessage {
  /// Creates the message.
  const Hello({
    required this.name,
    required this.room,
    this.token,
    this.join,
    this.candidate,
    this.epoch = 0,
  });

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
      join: json.maybeString('join') == null ? null : _readToken(json, 'join'),
      candidate: Candidate._read(json, 'ck', 'cs'),
      epoch: json.maybeInteger('epoch', max: maxEpoch) ?? 0,
    );
  }

  /// This device can take over the room if the host goes away: its
  /// candidate keys. Only apps that can host on the local network send it.
  final Candidate? candidate;

  /// The newest room epoch this player has seen. Only a hint: a host never
  /// trusts it without checking (see the host takeover in ARCHITECTURE).
  final int epoch;

  /// Display name for a new player.
  final String name;

  /// The room code shown on the host.
  final String room;

  /// Session token from an earlier `Welcome`, to rejoin as the same player.
  final String? token;

  /// A random number for this join attempt (same length as a token). If the
  /// welcome got lost and the player says hello again, the host recognises
  /// the attempt instead of seating the player twice.
  final String? join;

  @override
  String get _type => 'hello';

  @override
  Map<String, Object?> get _fields => {
    'name': name,
    'room': room,
    'token': ?token,
    'join': ?join,
    ...?candidate?._fields('ck', 'cs'),
    if (epoch > 0) 'epoch': epoch,
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

/// My pick in this night step. The same message for every role, so the
/// network does not tell who is who; the host decides what the pick means
/// (see `nightAction`).
final class NightIntent extends ClientMessage {
  /// Picks one player, the usual night choice.
  NightIntent(PlayerId target) : targets = List.unmodifiable([target]);

  /// Picks [targets]: two for cupid's couple; for the witch tonight's
  /// victim to heal and/or someone else to poison, or none at all.
  NightIntent.of(Iterable<PlayerId> targets)
    : targets = List.unmodifiable(targets);

  /// Whom I pick (at most two).
  final List<PlayerId> targets;

  @override
  String get _type => 'night';

  @override
  Map<String, Object?> get _fields => {
    'targets': [for (final t in targets) t.value],
  };
}

/// As the dying hunter: whom I take along; `null` spares everyone.
final class ShootIntent extends ClientMessage {
  /// Creates the message.
  const ShootIntent(this.target);

  /// Whom I shoot.
  final PlayerId? target;

  @override
  String get _type => 'shoot';

  @override
  Map<String, Object?> get _fields => {'target': target?.value};
}

/// Room owner, in the lobby: play with these settings (pick a [Preset] and
/// send its settings, or change single values).
final class SettingsIntent extends ClientMessage {
  /// Creates the message.
  const SettingsIntent(this.settings);

  /// The new settings, as a whole.
  final GameSettings settings;

  @override
  String get _type => 'settings';

  @override
  Map<String, Object?> get _fields => {'settings': encodeSettings(settings)};
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

/// Room owner: cut the narrator's intro short and go on to the roles.
final class SkipIntroIntent extends ClientMessage {
  /// Creates the message.
  const SkipIntroIntent();

  @override
  String get _type => 'skipIntro';
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

/// In the lobby: I want to appear as this persona.
final class PersonaIntent extends ClientMessage {
  /// Creates the message.
  const PersonaIntent(this.persona);

  /// The persona.
  final Persona persona;

  @override
  String get _type => 'persona';

  @override
  Map<String, Object?> get _fields => {'persona': persona.name};
}

/// Room owner: let a waiting player in (after comparing the check code at
/// the table) or turn them away.
final class AdmitIntent extends ClientMessage {
  /// Creates the message.
  const AdmitIntent(this.id, {required this.admit});

  /// The waiting join's id from [PendingJoin.id].
  final int id;

  /// Whether to let them in.
  final bool admit;

  @override
  String get _type => 'admit';

  @override
  Map<String, Object?> get _fields => {'id': id, 'ok': admit};
}

/// Room owner: swap the seats of two players in the lobby.
final class SwapSeatsIntent extends ClientMessage {
  /// Creates the message.
  const SwapSeatsIntent(this.first, this.second);

  /// One player.
  final PlayerId first;

  /// The other player.
  final PlayerId second;

  @override
  String get _type => 'swap';

  @override
  Map<String, Object?> get _fields => {'a': first.value, 'b': second.value};
}

/// As a werewolf: the pack's door sign guess of tonight on [target]'s door
/// (see [GameSettings.doorSigns]).
final class MarkIntent extends ClientMessage {
  /// Creates the message.
  MarkIntent(this.target, Iterable<int> sign) : sign = List.unmodifiable(sign);

  /// Whose door.
  final PlayerId target;

  /// The guessed sign: [doorSignLength] symbols.
  final List<int> sign;

  @override
  String get _type => 'mark';

  @override
  Map<String, Object?> get _fields => {'target': target.value, 'sign': sign};
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
        roomSecret: _readSecret(json.maybeString('secret')),
        lastSeq: json.maybeInteger('lastSeq', max: maxSeq) ?? 0,
        epoch: json.maybeInteger('epoch', max: maxEpoch) ?? 0,
      ),
      'custody' => Custody(
        epoch: json.integer('epoch', max: maxEpoch),
        version: json.integer('version', max: maxSeq),
        sealed: json.string('sealed', max: maxCustody),
        takeOver: json.maybeBoolean('takeOver') ?? false,
      ),
      'witness' => Witness(
        epoch: json.integer('epoch', max: maxEpoch),
        key: _readSecret(json.maybeString('key')),
        successor: Candidate._read(json, 'sk', 'ss'),
        release: json.maybeBoolean('release') ?? false,
      ),
      'ack' => Ack(
        json.integer('seq', min: 1, max: maxSeq),
        version: json.integer('version', max: maxSeq),
      ),
      'state' => StateMessage(
        version: json.maybeInteger('version', max: maxSeq) ?? 0,
        view: decodeView(json.object('view')),
        isOwner: json.boolean('owner'),
        phaseEndsInMs: json.maybeInteger('endsIn'),
        phaseAt: json.maybeInteger('phaseAt', max: maxClock),
        introSkippedAt: json.maybeInteger('skippedAt', max: maxClock),
        pending: [
          for (final p in json.objects('pending', max: 40))
            PendingJoin(
              id: p.integer('id', max: 1 << 20),
              name: p.string('name', max: maxNameLength * 2),
              checkCode: [
                for (final c in p.strings('code', max: 8, maxLength: 2))
                  int.tryParse(c) ?? (throw const ProtocolError('code')),
              ],
            ),
        ],
      ),
      'waiting' => const Waiting(),
      'pong' => Pong(
        json.integer('version', max: maxSeq),
        echo: json.maybeInteger('echo', max: maxClock),
        at: json.maybeInteger('at', max: maxClock),
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
  const Welcome({
    required this.token,
    required this.you,
    this.roomSecret,
    this.lastSeq = 0,
    this.epoch = 0,
  });

  /// How many times the room changed hands. A player never goes back to a
  /// host with a smaller epoch than one it has seen.
  final int epoch;

  /// The highest intent number the host has applied for this session, so a
  /// returning player knows which of its queued intents arrived.
  final int lastSeq;

  /// Secret session token. Never log or show it.
  final String token;

  /// Your player id.
  final PlayerId you;

  /// The room secret (32 bytes), only for players the host let in after
  /// comparing the check code: with it they come back over a channel that
  /// proves the room key, never again over an unchecked one. Never log it.
  final List<int>? roomSecret;

  @override
  String get _type => 'welcome';

  @override
  Map<String, Object?> get _fields => {
    'token': token,
    'you': you.value,
    'secret': ?(roomSecret == null ? null : base64Url.encode(roomSecret!)),
    'lastSeq': lastSeq,
    if (epoch > 0) 'epoch': epoch,
  };
}

/// For the successor: the whole room, sealed with a key only the witness
/// holds. Kept in memory and replaced by every newer [version]; an empty
/// [sealed] means "you are no longer the successor, forget it".
final class Custody extends HostMessage {
  /// Creates the message.
  const Custody({
    required this.epoch,
    required this.version,
    required this.sealed,
    this.takeOver = false,
  });

  /// Tells a former successor to drop what it holds.
  const Custody.drop({required this.epoch})
    : version = 0,
      sealed = '',
      takeOver = false;

  /// The room epoch this belongs to.
  final int epoch;

  /// The state version sealed inside.
  final int version;

  /// The sealed room (opaque to everyone but the holder of the key).
  final String sealed;

  /// The host is leaving on purpose: take over now, without waiting.
  final bool takeOver;

  @override
  String get _type => 'custody';

  @override
  Map<String, Object?> get _fields => {
    'epoch': epoch,
    'version': version,
    'sealed': sealed,
    if (takeOver) 'takeOver': true,
  };
}

/// For the witness: the key to the successor's sealed room and how to
/// reach the successor. Without a [key] it means "forget it".
final class Witness extends HostMessage {
  /// Creates the message.
  const Witness({
    required this.epoch,
    this.key,
    this.successor,
    this.release = false,
  });

  /// The room epoch this belongs to.
  final int epoch;

  /// The key (32 bytes). Never log it.
  final List<int>? key;

  /// The successor's candidate keys, to open a channel to it.
  final Candidate? successor;

  /// The host is leaving on purpose: hand the key over now.
  final bool release;

  @override
  String get _type => 'witness';

  @override
  Map<String, Object?> get _fields => {
    'epoch': epoch,
    'key': ?(key == null ? null : base64Url.encode(key!)),
    ...?successor?._fields('sk', 'ss'),
    if (release) 'release': true,
  };
}

/// What the witness sends the successor over the candidate channel: the
/// key to the sealed room of [epoch]. The only message on that channel.
class Release {
  /// Creates the message.
  const Release({required this.epoch, required this.key});

  /// Parses and validates [raw]; throws a [ProtocolError] otherwise.
  factory Release.parse(String raw) {
    final json = JsonReader.decode(raw, maxBytes: 512);
    _expectVersion(json);
    if (json.string('type', max: 16) != 'release') {
      throw const ProtocolError('unknown type');
    }
    final key = _readSecret(json.string('key'));
    return Release(
      epoch: json.integer('epoch', max: maxEpoch),
      key: key!,
    );
  }

  /// The room epoch the key belongs to.
  final int epoch;

  /// The key (32 bytes). Never log it.
  final List<int> key;

  /// Encodes this message for sending.
  String encode() => jsonEncode({
    'v': protocolVersion,
    'type': 'release',
    'epoch': epoch,
    'key': base64Url.encode(key),
  });
}

/// Answer to a [PingIntent] when the player is up to date.
final class Pong extends HostMessage {
  /// Creates the message.
  const Pong(this.version, {this.echo, this.at});

  /// The host's current state version.
  final int version;

  /// The ping's own time, sent back.
  final int? echo;

  /// The host's clock when it answered (milliseconds).
  final int? at;

  @override
  String get _type => 'pong';

  @override
  Map<String, Object?> get _fields => {
    'version': version,
    'echo': ?echo,
    'at': ?at,
  };
}

/// The host applied (or had already applied) intent [seq].
final class Ack extends HostMessage {
  /// Creates the message.
  const Ack(this.seq, {required this.version});

  /// The confirmed intent number.
  final int seq;

  /// The host's current state version, to notice a missed state.
  final int version;

  @override
  String get _type => 'ack';

  @override
  Map<String, Object?> get _fields => {'seq': seq, 'version': version};
}

/// Someone who wants to join without the QR code's secret.
class PendingJoin {
  /// Creates a pending join.
  const PendingJoin({
    required this.id,
    required this.name,
    required this.checkCode,
  });

  /// Id to answer with an [AdmitIntent].
  final int id;

  /// The name they want.
  final String name;

  /// The check code their device shows.
  final List<int> checkCode;
}

/// The game as you may see it.
final class StateMessage extends HostMessage {
  /// Creates the message.
  const StateMessage({
    required this.view,
    required this.isOwner,
    this.version = 0,
    this.phaseEndsInMs,
    this.phaseAt,
    this.introSkippedAt,
    this.pending = const [],
  });

  /// When the room owner skipped the narrator's intro, on the host's
  /// clock (milliseconds); only during the role reveal.
  final int? introSkippedAt;

  /// When the current phase (or night step) began, on the host's clock
  /// (milliseconds): every phone plans shared moments from it, e.g. the
  /// morning yawn, so they sound at the same instant everywhere.
  final int? phaseAt;

  /// For the room owner: people waiting to be let in.
  final List<PendingJoin> pending;

  /// Counts up with every change; older states arriving late are dropped.
  final int version;

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
    'version': version,
    'endsIn': ?phaseEndsInMs,
    'phaseAt': ?phaseAt,
    'skippedAt': ?introSkippedAt,
    'pending': [
      for (final p in pending)
        {
          'id': p.id,
          'name': p.name,
          'code': [for (final c in p.checkCode) '$c'],
        },
    ],
  };
}

/// You are encrypted but not verified: wait until the host lets you in.
final class Waiting extends HostMessage {
  /// Creates the message.
  const Waiting();

  @override
  String get _type => 'waiting';

  @override
  Map<String, Object?> get _fields => const {};
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
