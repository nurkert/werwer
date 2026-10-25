import 'dart:async';
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

/// Timings and limits of a room.
class HostConfig {
  /// Creates a configuration; the defaults suit a table of friends.
  const HostConfig({
    this.nightTime = const Duration(seconds: 90),
    this.dayTime = const Duration(minutes: 8),
    this.voteTime = const Duration(minutes: 2),
    this.helloTimeout = const Duration(seconds: 5),
    this.renameTimeout = const Duration(minutes: 2),
    this.maxConnections = 40,
    this.maxMessagesPerSecond = 20,
    this.maxBadMessages = 3,
  });

  /// How long a night may take before it resolves with what was picked.
  final Duration nightTime;

  /// How long the discussion may take before the vote starts.
  final Duration dayTime;

  /// How long the vote may take.
  final Duration voteTime;

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
}

class _Session {
  _Session(this.token, this.player, {required this.owner});

  final String token;
  final PlayerId player;
  final bool owner;
  _Link? link;
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
  /// Creates a room with [roomCode]. The random source deals roles and makes
  /// session tokens, so it must be cryptographically secure outside of tests.
  GameHost({
    required this.roomCode,
    required this._random,
    this.config = const HostConfig(),
    this._startTimer = _realTimer,
    this._clock = _realClock,
  });

  /// The code players type to join.
  final String roomCode;

  /// Timings and limits.
  final HostConfig config;

  final Random _random;
  final StartTimer _startTimer;
  final Clock _clock;

  GameState _state = GameState.lobby();
  final _sessions = <String, _Session>{};
  final _links = <_Link>{};
  final _transports = <Transport>[];
  final _ownerTransport = MemoryTransport();
  int _nextId = 1;
  void Function()? _cancelPhaseTimer;
  int? _phaseDeadline;
  bool _closed = false;

  /// The authoritative state (for the host's diagnostics and tests only;
  /// never show it to the host player).
  GameState get state => _state;

  /// Accepts connections from [transport] until [close].
  void serve(Transport transport) {
    _transports.add(transport);
    transport.connections.listen((c) => _accept(c, owner: false));
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
    try {
      message = ClientMessage.parse(raw);
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
    _intent(link, session, message);
  }

  void _hello(_Link link, Hello hello) {
    if (hello.room != roomCode) return _bye(link, ByeReason.wrongRoom);
    final token = hello.token;
    if (token != null) {
      final session = _sessions[token];
      if (session == null) return _bye(link, ByeReason.unknownSession);
      final previous = session.link;
      if (previous != null && previous != link) {
        _bye(previous, ByeReason.replaced);
      }
      _bind(link, session);
      return;
    }
    if (_state.phase != Phase.lobby) return _bye(link, ByeReason.gameRunning);
    final id = PlayerId('p${_nextId++}');
    try {
      _state = apply(_state, AddPlayer(id, hello.name)).state;
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
    final session = _Session(_newToken(), id, owner: link.owner && !hasOwner);
    _sessions[session.token] = session;
    _bind(link, session);
    _broadcast();
  }

  void _bind(_Link link, _Session session) {
    link.cancelHello?.call();
    link.session = session;
    session.link = link;
    link.connection.send(
      Welcome(token: session.token, you: session.player).encode(),
    );
    _sendState(session);
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
        case StartGameIntent():
          _ownerOnly(session);
          _commit(apply(_state, StartGame(random: _random)));
        case ConfirmRoleIntent():
          _commit(apply(_state, ConfirmRole(me)));
        case NightIntent(:final target):
          final role = _state.player(me)?.role;
          if (role == null) throw const RuleViolation(Violation.wrongPhase);
          _commit(apply(_state, nightAction(role, me, target)));
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
        case PersonaIntent(:final persona):
          _commit(apply(_state, ChoosePersona(me, persona)));
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
    if (before.phase != _state.phase || before.round != _state.round) {
      _schedulePhaseTimer();
    }
    _broadcast();
  }

  void _schedulePhaseTimer() {
    _cancelPhaseTimer?.call();
    _cancelPhaseTimer = null;
    _phaseDeadline = null;
    final duration = switch (_state.phase) {
      Phase.night => config.nightTime,
      Phase.day => config.dayTime,
      Phase.vote => config.voteTime,
      _ => null,
    };
    if (duration == null) return;
    final phase = _state.phase;
    final round = _state.round;
    _phaseDeadline = _clock() + duration.inMilliseconds;
    _cancelPhaseTimer = _startTimer(duration, () {
      if (_closed || _state.phase != phase || _state.round != round) return;
      _commit(apply(_state, const PhaseTimeout()));
    });
  }

  void _broadcast() {
    _sessions.values.forEach(_sendState);
  }

  void _sendState(_Session session) {
    final link = session.link;
    if (link == null) return;
    final deadline = _phaseDeadline;
    link.connection.send(
      StateMessage(
        view: viewFor(_state, session.player),
        isOwner: session.owner,
        phaseEndsInMs: deadline == null ? null : max(0, deadline - _clock()),
      ).encode(),
    );
  }
}
