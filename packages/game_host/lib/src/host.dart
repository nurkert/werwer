import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:game_core/game_core.dart';
import 'package:game_host/src/transport.dart';
import 'package:protocol/protocol.dart';

/// Starts a timer that calls [callback] after [after]; returns a function
/// that cancels it. Injected so tests control time.
typedef StartTimer =
    void Function() Function(Duration after, void Function() callback);

/// Current time in milliseconds. Injected so tests control time.
typedef Clock = int Function();

void Function() _realTimer(Duration after, void Function() callback) =>
    Timer(after, callback).cancel;

int _realClock() => DateTime.now().millisecondsSinceEpoch;

/// Timings and limits of a room. The times of the game's phases are part of
/// the game's settings ([GameSettings], see `timeLimit`).
class HostConfig {
  /// Creates a configuration; the defaults suit a table of friends.
  const HostConfig({
    this.revealTime = const Duration(seconds: 90),
    this.helloTimeout = const Duration(seconds: 5),
    this.renameTimeout = const Duration(minutes: 2),
    this.maxConnections = 40,
    this.maxMessagesPerSecond = 20,
    this.maxBadMessages = 3,
    this.maxPending = 6,
  });

  /// How long players have to look at their role before the first night
  /// falls anyway, so one absent phone cannot hold up the table.
  final Duration revealTime;

  /// A new connection must say hello within this time.
  final Duration helloTimeout;

  /// After a refused name, how long the player has to send another one.
  final Duration renameTimeout;

  /// Most simultaneous connections, joined or not.
  final int maxConnections;

  /// More messages than this per second end the connection.
  final int maxMessagesPerSecond;

  /// More malformed messages than this end the connection.
  final int maxBadMessages;

  /// Most joins without the QR code waiting for the owner at once.
  final int maxPending;
}

class _Session {
  _Session(
    this.token,
    this.player, {
    required this.owner,
    this.lastSeq = 0,
    this.join,
  });

  /// The join number of the hello that created this session.
  final String? join;

  final String token;
  final PlayerId player;
  final bool owner;
  _Link? link;

  /// Highest intent number applied for this session: each intent counts
  /// exactly once, however often it arrives.
  int lastSeq;
}

class _Pending {
  _Pending(this.id, this.link, this.name);

  final int id;
  final _Link link;
  String name;
}

class _Link {
  _Link(this.connection, {required this.owner});

  final Connection connection;
  final bool owner;
  _Session? session;
  void Function()? cancelHello;
  // Cancelled in GameHost._drop.
  // ignore: cancel_subscriptions
  StreamSubscription<String>? subscription;
  int windowStart = 0;
  int windowCount = 0;
  int badMessages = 0;
  bool closed = false;
}

/// Runs one room: it owns the authoritative [GameState], turns player intents
/// into game actions and sends every player only their own view.
///
/// Players are identified by their session token, never by the connection,
/// so they can drop out and come back with exactly their state. Pure Dart:
/// it runs in the app on the host device and could run on a server later.
class GameHost {
  /// Creates a room with [roomCode] and the lobby's first [settings]. The
  /// random source deals roles and makes session tokens, so it must be
  /// cryptographically secure outside of tests.
  GameHost({
    required this.roomCode,
    required this._random,
    this.roomSecret,
    this.config = const HostConfig(),
    GameSettings settings = const GameSettings(),
    this._startTimer = _realTimer,
    this._clock = _realClock,
  }) : _state = GameState.lobby(settings: settings);

  /// Restores a room from a [snapshot] written earlier (e.g. before the host
  /// app crashed). Players come back with their tokens and find exactly
  /// their state; a running phase timer goes on with the time it had left.
  ///
  /// Throws a [ProtocolError] if the snapshot is not valid.
  factory GameHost.restore(
    String snapshot, {
    required Random random,
    List<int>? roomSecret,
    HostConfig config = const HostConfig(),
    StartTimer startTimer = _realTimer,
    Clock clock = _realClock,
  }) {
    final json = JsonReader.decode(snapshot, maxBytes: 1 << 20);
    if (json.integer('v') != _snapshotVersion) {
      throw const ProtocolError('unsupported snapshot');
    }
    final room = json.string('room', max: roomCodeLength);
    final host = GameHost(
      roomCode: room,
      random: random,
      roomSecret: roomSecret,
      config: config,
      startTimer: startTimer,
      clock: clock,
    );
    final state = decodeState(json.object('state'));
    final sessions = {
      for (final s in json.objects('sessions', max: maxPlayers))
        s.string('token', max: tokenLength): _Session(
          s.string('token', max: tokenLength),
          PlayerId(s.string('player', max: 16)),
          owner: s.boolean('owner'),
          lastSeq: s.maybeInteger('lastSeq', max: maxSeq) ?? 0,
          join: s.maybeString('join', max: tokenLength),
        ),
    };
    if (sessions.values.any((s) => state.player(s.player) == null)) {
      throw const ProtocolError('session for unknown player');
    }
    final remaining = json.maybeInteger('phaseLeftMs');
    return host
      .._state = state
      .._nextId = json.integer('nextId', min: 1, max: 1 << 20)
      .._version = json.maybeInteger('version', max: maxSeq) ?? 0
      .._sessions.addAll(sessions)
      .._schedulePhaseTimer(
        remaining: remaining == null ? null : Duration(milliseconds: remaining),
      );
  }

  /// The code players type to join.
  final String roomCode;

  /// The room secret from the QR code. Players the host let in without it
  /// (after comparing the check code) get it with their welcome, so they
  /// come back over a verified channel. Opaque to the host.
  final List<int>? roomSecret;

  /// Timings and limits.
  final HostConfig config;

  final Random _random;
  final StartTimer _startTimer;
  final Clock _clock;

  GameState _state;
  final _sessions = <String, _Session>{};
  final _links = <_Link>{};
  final _transports = <Transport>[];
  final _ownerTransport = MemoryTransport();
  int _nextId = 1;
  final _pending = <int, _Pending>{};
  int _nextPending = 1;
  void Function()? _cancelPhaseTimer;
  int? _phaseDeadline;
  bool _closed = false;

  /// Counts every broadcast state, so players drop states that arrive late.
  int _version = 0;

  static const _snapshotVersion = 3;

  /// Called with a fresh [snapshot] after every change, so the app can save
  /// it. It holds every secret of the game: keep it on the host device only.
  void Function(String snapshot)? onSnapshot;

  /// The whole room (game state and sessions) as text, for [GameHost.restore].
  String snapshot() => jsonEncode({
    'v': _snapshotVersion,
    'room': roomCode,
    'nextId': _nextId,
    'version': _version,
    'phaseLeftMs': ?_phaseLeft(),
    'state': encodeState(_state),
    'sessions': [
      for (final s in _sessions.values)
        {
          'token': s.token,
          'player': s.player.value,
          'owner': s.owner,
          'lastSeq': s.lastSeq,
          'join': ?s.join,
        },
    ],
  });

  int? _phaseLeft() {
    final deadline = _phaseDeadline;
    return deadline == null ? null : max(0, deadline - _clock());
  }

  /// The session token of the room owner, so the host player's own app can
  /// rejoin a restored room.
  String? get ownerToken =>
      _sessions.values.where((s) => s.owner).firstOrNull?.token;

  /// The authoritative state (for the host's diagnostics and tests only;
  /// never show it to the host player).
  GameState get state => _state;

  /// Accepts connections from [transport] until [close].
  void serve(Transport transport) {
    _transports.add(transport);
    transport.connections.listen(
      (c) => _accept(c, owner: false),
      // A transport replaced by a new one (the app came back and rebound
      // its socket) is forgotten once it is closed.
      onDone: () => _transports.remove(transport),
    );
  }

  /// A connection for the host player's own app. Whoever joins through it
  /// owns the room: they may start, kick and end the discussion. They still
  /// only see their own view.
  Connection connectOwner() {
    if (!_transports.contains(_ownerTransport)) {
      _transports.add(_ownerTransport);
      _ownerTransport.connections.listen((c) => _accept(c, owner: true));
    }
    return _ownerTransport.connect();
  }

  /// Ends the room: says goodbye to everyone and closes all transports.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _cancelPhaseTimer?.call();
    for (final link in [..._links]) {
      _bye(link, ByeReason.closed);
    }
    await Future.wait([for (final t in _transports) t.close()]);
  }

  void _accept(Connection connection, {required bool owner}) {
    if (_closed || _links.length >= config.maxConnections) {
      unawaited(connection.close());
      return;
    }
    final link = _Link(connection, owner: owner);
    _links.add(link);
    link
      ..cancelHello = _startTimer(config.helloTimeout, () {
        if (link.session == null) _drop(link);
      })
      ..subscription = connection.messages.listen(
        (raw) => _receive(link, raw),
        onDone: () => _drop(link),
        onError: (Object _) => _drop(link),
        cancelOnError: true,
      );
  }

  void _drop(_Link link) {
    if (link.closed) return;
    link.closed = true;
    link.cancelHello?.call();
    unawaited(link.subscription?.cancel());
    _links.remove(link);
    final before = _pending.length;
    _pending.removeWhere((_, p) => p.link == link);
    if (_pending.length != before && !_closed) _broadcast();
    if (link.session?.link == link) link.session!.link = null;
    unawaited(link.connection.close());
  }

  void _bye(_Link link, ByeReason reason) {
    link.connection.send(Bye(reason).encode());
    _drop(link);
  }

  bool _overLimit(_Link link) {
    final now = _clock();
    if (now - link.windowStart >= 1000) {
      link
        ..windowStart = now
        ..windowCount = 0;
    }
    link.windowCount++;
    return link.windowCount > config.maxMessagesPerSecond;
  }

  void _receive(_Link link, String raw) {
    if (link.closed) return;
    if (_overLimit(link)) return _bye(link, ByeReason.misbehaved);
    final ClientMessage message;
    final int? seq;
    try {
      (:message, :seq) = ClientMessage.parseNumbered(raw);
    } on ProtocolError {
      link.badMessages++;
      if (link.badMessages > config.maxBadMessages) {
        _bye(link, ByeReason.misbehaved);
      }
      return;
    }
    final session = link.session;
    if (session == null) {
      if (message is Hello) return _hello(link, message);
      return _bye(link, ByeReason.misbehaved);
    }
    if (message is PingIntent) {
      if (message.version < _version) {
        _sendState(session);
      } else {
        link.connection.send(Pong(_version).encode());
      }
      return;
    }
    if (seq == null) return _intent(link, session, message);
    if (seq <= session.lastSeq) {
      // Already applied (resent after a reconnect, or doubled on the way):
      // confirm again, never apply twice.
      link.connection.send(Ack(seq, version: _version).encode());
      return;
    }
    // A gap means an earlier intent got lost; the player resends in order.
    if (seq != session.lastSeq + 1) return;
    // Counted before applying, so the snapshot written while applying already
    // knows it: a restored host never applies it a second time.
    session.lastSeq = seq;
    _intent(link, session, message);
    // Saved before confirming, also for refused intents (which change no
    // state and so broadcast nothing): confirmed always means saved.
    onSnapshot?.call(snapshot());
    if (!link.closed) {
      link.connection.send(Ack(seq, version: _version).encode());
    }
  }

  void _hello(_Link link, Hello hello) {
    if (hello.room != roomCode) return _bye(link, ByeReason.wrongRoom);
    final connection = link.connection;
    final unverified = switch (connection) {
      PeerTrust(verified: false) => true,
      _ => false,
    };
    final token = hello.token;
    if (token != null) {
      // A token over an unchecked channel may have been read by someone in
      // the middle; players who were let in come back with the room secret.
      if (unverified && !link.owner) {
        return _bye(link, ByeReason.unknownSession);
      }
      final session = _sessions[token];
      if (session == null) return _bye(link, ByeReason.unknownSession);
      final previous = session.link;
      if (previous != null && previous != link) {
        _bye(previous, ByeReason.replaced);
      }
      _bind(link, session);
      return;
    }
    // The same join attempt again (its welcome got lost on the way): bind to
    // the seat it already has. Only over checked channels, like a token.
    final again = hello.join == null || unverified
        ? null
        : _sessions.values.where((s) => s.join == hello.join).firstOrNull;
    if (again != null) {
      final previous = again.link;
      if (previous != null && previous != link) _drop(previous);
      _bind(link, again);
      return;
    }
    if (_state.phase != Phase.lobby) return _bye(link, ByeReason.gameRunning);
    // Joined without the QR code's secret: the host checks the code first.
    if (!link.owner && unverified) {
      if (!_nameAvailable(link, hello.name)) return;
      final waiting = _pending.values.where((p) => p.link == link).firstOrNull;
      if (waiting != null) {
        // A new name does not buy more time on the waiting list.
        waiting.name = hello.name;
      } else {
        // A few may wait at once; strangers cannot fill every slot.
        if (_pending.length >= config.maxPending) {
          return _bye(link, ByeReason.refused);
        }
        final id = _nextPending++;
        _pending[id] = _Pending(id, link, hello.name);
        link
          ..cancelHello?.call()
          ..cancelHello = _startTimer(config.renameTimeout, () {
            if (link.session == null) _drop(link);
          });
      }
      connection.send(const Waiting().encode());
      _broadcast();
      return;
    }
    _join(link, hello.name, join: hello.join);
  }

  /// Checks [name] without joining; on a taken name the player may retry.
  bool _nameAvailable(_Link link, String name) {
    try {
      apply(_state, AddPlayer(const PlayerId('probe'), name));
      return true;
    } on RuleViolation catch (violation) {
      if (violation.reason != Violation.invalidName) {
        _bye(link, ByeReason.refused);
        return false;
      }
      link
        ..cancelHello?.call()
        ..cancelHello = _startTimer(config.renameTimeout, () {
          if (link.session == null) _drop(link);
        })
        ..connection.send(const Refused(Violation.invalidName).encode());
      return false;
    }
  }

  void _admit(int id, {required bool admit}) {
    final pending = _pending.remove(id);
    if (pending == null) throw const RuleViolation(Violation.unknownPlayer);
    if (pending.link.closed) return _broadcast();
    if (!admit) {
      _bye(pending.link, ByeReason.refused);
      return _broadcast();
    }
    if (pending.link.session != null) return _broadcast();
    if (_state.phase != Phase.lobby) {
      _bye(pending.link, ByeReason.gameRunning);
      return _broadcast();
    }
    _join(pending.link, pending.name);
  }

  void _join(_Link link, String name, {String? join}) {
    final id = PlayerId('p${_nextId++}');
    try {
      _state = apply(_state, AddPlayer(id, name)).state;
    } on RuleViolation catch (violation) {
      if (violation.reason != Violation.invalidName) {
        return _bye(link, ByeReason.refused);
      }
      // Name taken or invalid: keep the connection so the player can pick
      // another name without starting over.
      link
        ..cancelHello?.call()
        ..cancelHello = _startTimer(config.renameTimeout, () {
          if (link.session == null) _drop(link);
        })
        ..connection.send(const Refused(Violation.invalidName).encode());
      return;
    }
    final hasOwner = _sessions.values.any((s) => s.owner);
    final session = _Session(
      _newToken(),
      id,
      owner: link.owner && !hasOwner,
      join: join,
    );
    _sessions[session.token] = session;
    _bind(link, session);
    _broadcast();
  }

  void _bind(_Link link, _Session session) {
    link.cancelHello?.call();
    link.session = session;
    session.link = link;
    final waited = _pending.length;
    _pending.removeWhere((_, p) => p.link == link);
    final unverified = switch (link.connection) {
      PeerTrust(verified: false) => true,
      _ => false,
    };
    link.connection.send(
      Welcome(
        token: session.token,
        you: session.player,
        roomSecret: unverified ? roomSecret : null,
        lastSeq: session.lastSeq,
      ).encode(),
    );
    if (_pending.length != waited) {
      _broadcast();
    } else {
      _sendState(session);
    }
  }

  String _newToken() {
    final buffer = StringBuffer();
    for (var i = 0; i < tokenLength; i++) {
      buffer.write(_random.nextInt(16).toRadixString(16));
    }
    return buffer.toString();
  }

  void _intent(_Link link, _Session session, ClientMessage message) {
    final me = session.player;
    try {
      switch (message) {
        case Hello():
          throw const RuleViolation(Violation.alreadyActed);
        case PingIntent():
          return;
        case StartGameIntent():
          _ownerOnly(session);
          _commit(apply(_state, StartGame(random: _random)));
        case ConfirmRoleIntent():
          _commit(apply(_state, ConfirmRole(me)));
        case NightIntent(:final targets):
          _commit(apply(_state, nightAction(_state, me, targets)));
        case ShootIntent(:final target):
          _commit(apply(_state, HunterShoot(me, target)));
        case SettingsIntent(:final settings):
          _ownerOnly(session);
          _commit(apply(_state, ChangeSettings(settings)));
        case VoteIntent(:final target):
          _commit(apply(_state, CastVote(me, target)));
        case EndDiscussionIntent():
          _ownerOnly(session);
          _commit(apply(_state, const EndDiscussion()));
        case KickIntent(:final player):
          _ownerOnly(session);
          if (player == me) throw const RuleViolation(Violation.invalidTarget);
          final update = apply(_state, RemovePlayer(player));
          _endSession(player, ByeReason.kicked);
          _commit(update);
        case LeaveIntent():
          final update = apply(_state, RemovePlayer(me));
          _endSession(me, ByeReason.left);
          _commit(update);
        case AdmitIntent(:final id, :final admit):
          _ownerOnly(session);
          _admit(id, admit: admit);
        case SwapSeatsIntent(:final first, :final second):
          _ownerOnly(session);
          _commit(apply(_state, SwapSeats(first, second)));
        case PersonaIntent(:final persona):
          _commit(apply(_state, ChoosePersona(me, persona)));
        case MarkIntent(:final target, :final sign):
          _commit(apply(_state, MarkDoor(me, target, sign)));
        case SheepIntent(:final count):
          _commit(apply(_state, CountSheep(me, count)));
        case RematchIntent():
          _ownerOnly(session);
          _rematch();
      }
    } on RuleViolation catch (violation) {
      link.connection.send(Refused(violation.reason).encode());
    }
  }

  void _ownerOnly(_Session session) {
    if (!session.owner) throw const RuleViolation(Violation.notYourAction);
  }

  void _endSession(PlayerId player, ByeReason reason) {
    final session = _sessions.values
        .where((s) => s.player == player)
        .firstOrNull;
    if (session == null) return;
    _sessions.remove(session.token);
    final link = session.link;
    if (link != null) _bye(link, reason);
  }

  void _rematch() {
    if (_state.phase != Phase.ended) {
      throw const RuleViolation(Violation.wrongPhase);
    }
    var next = GameState.lobby(settings: _state.settings);
    for (final p in _state.players) {
      next = apply(next, AddPlayer(p.id, p.name, persona: p.persona)).state;
    }
    _commit(GameUpdate(next));
  }

  void _commit(GameUpdate update) {
    final before = _state;
    _state = update.state;
    if (before.phase != _state.phase ||
        before.round != _state.round ||
        before.nightStep != _state.nightStep) {
      _schedulePhaseTimer();
    }
    _broadcast();
  }

  void _schedulePhaseTimer({Duration? remaining}) {
    _cancelPhaseTimer?.call();
    _cancelPhaseTimer = null;
    _phaseDeadline = null;
    final full = _state.phase == Phase.roleReveal
        ? config.revealTime
        : timeLimit(_state);
    if (full == null) return;
    final duration = remaining == null || remaining > full ? full : remaining;
    final (phase, round, step) = (
      _state.phase,
      _state.round,
      _state.nightStep,
    );
    _phaseDeadline = _clock() + duration.inMilliseconds;
    _cancelPhaseTimer = _startTimer(duration, () {
      if (_closed ||
          _state.phase != phase ||
          _state.round != round ||
          _state.nightStep != step) {
        return;
      }
      _commit(apply(_state, const PhaseTimeout()));
    });
  }

  void _broadcast() {
    _version++;
    onSnapshot?.call(snapshot());
    _sessions.values.forEach(_sendState);
  }

  void _sendState(_Session session) {
    final link = session.link;
    if (link == null) return;
    link.connection.send(
      StateMessage(
        version: _version,
        view: viewFor(_state, session.player),
        isOwner: session.owner,
        phaseEndsInMs: _phaseLeft(),
        pending: session.owner
            ? [
                for (final p in _pending.values)
                  PendingJoin(
                    id: p.id,
                    name: p.name,
                    checkCode: switch (p.link.connection) {
                      final PeerTrust trust => trust.checkCode,
                      _ => const [],
                    },
                  ),
              ]
            : const [],
      ).encode(),
    );
  }
}
