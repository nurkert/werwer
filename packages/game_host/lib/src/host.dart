import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:game_core/game_core.dart';
import 'package:game_host/src/custody.dart';
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
    this.candidate,
  });

  /// The join number of the hello that created this session.
  final String? join;

  final String token;
  final PlayerId player;
  bool owner;

  /// This player's device can take over the room (see [Candidate]).
  Candidate? candidate;
  _Link? link;

  /// Highest intent number applied for this session: each intent counts
  /// exactly once, however often it arrives.
  int lastSeq;

  /// This player's phone plays no sound (muted or at zero volume).
  bool silent = false;
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

  /// The player said hello from a browser.
  bool web = false;
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
    GameSettings? settings,
    this._startTimer = _realTimer,
    this._clock = _realClock,
  }) : _state = GameState.lobby(settings: settings ?? defaultSettings);

  /// Restores a room from a [snapshot] written earlier (e.g. before the host
  /// app crashed). Players come back with their tokens and find exactly
  /// their state; a running phase timer goes on with the time it had left.
  ///
  /// Throws a [ProtocolError] if the snapshot is not valid.
  ///
  /// With [takeOver] this device takes the room over from a host that went
  /// away: the epoch counts up (players never go back to the old host) and
  /// [newOwner], this device's player, becomes the room owner.
  factory GameHost.restore(
    String snapshot, {
    required Random random,
    List<int>? roomSecret,
    bool takeOver = false,
    PlayerId? newOwner,
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
          candidate: _readCandidate(s),
        ),
    };
    if (sessions.values.any((s) => state.player(s.player) == null)) {
      throw const ProtocolError('session for unknown player');
    }
    final epoch = json.maybeInteger('epoch', max: maxEpoch) ?? 0;
    if (takeOver) {
      if (epoch >= maxEpoch) throw const ProtocolError('too many takeovers');
      for (final s in sessions.values) {
        s.owner = s.player == newOwner;
        // This device hosts now; it is nobody's successor any more.
        if (s.owner) s.candidate = null;
      }
    }
    final remaining = json.maybeInteger('phaseLeftMs');
    return host
      .._state = state
      .._nextId = json.integer('nextId', min: 1, max: 1 << 20)
      .._version = json.maybeInteger('version', max: maxSeq) ?? 0
      ..epoch = takeOver ? epoch + 1 : epoch
      .._sessions.addAll(sessions)
      .._schedulePhaseTimer(
        remaining: remaining == null ? null : Duration(milliseconds: remaining),
      );
  }

  /// What a new room starts with: werewolf as everyone knows it (the
  /// narrator calls the roles, eyes closed, no sheep). Whowolf's extras are
  /// one tap away in the settings.
  static final GameSettings defaultSettings = Preset.classic.settings;

  static Candidate? _readCandidate(JsonReader json) {
    final key = json.maybeString('ck');
    final secret = json.maybeString('cs');
    if (key == null || secret == null) return null;
    try {
      return Candidate(
        key: base64Url.decode(key),
        secret: base64Url.decode(secret),
      );
    } on Object {
      throw const ProtocolError('bad candidate');
    }
  }

  /// The code players type to join.
  final String roomCode;

  /// How many times this room changed hands (see [GameHost.restore]).
  int epoch = 0;

  /// Lets another player take over if this host goes away; without it
  /// nobody can.
  CustodyConfig? custody;

  /// Called when a player says it has seen a newer epoch: maybe this host
  /// was replaced while it was away. Only a hint, anyone can claim it; the
  /// app checks by connecting to the newer host with the room keys.
  void Function(int epoch)? onNewerEpoch;

  _Session? _successor;
  _Session? _witness;
  List<int>? _custodyKey;
  int _sealedVersion = -1;
  bool _sealing = false;
  bool _resealAgain = false;

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

  /// When the current phase or night step began (host clock).
  int _phaseStartedAt = 0;

  /// When the owner skipped the narrator's intro in this role reveal.
  int? _introSkippedAt;

  /// One-time codes that hand a seat to another device, with when they
  /// run out (host clock).
  final _handovers = <String, ({PlayerId player, int until})>{};

  /// How long a handover code works.
  static const handoverTime = Duration(minutes: 2);

  /// In the discussion: who is ready to vote.
  final _ready = <PlayerId>{};

  /// Most of the living are ready: the vote follows shortly.
  bool _voteSoon = false;

  /// The game leader paused the clock with this much left.
  int? _pausedLeft;

  /// How much the leader added to this phase already.
  Duration _extended = Duration.zero;

  /// How long a called night step goes on after its last pick, so the
  /// picker sees the result (the pack's choice standing).
  static const lastPickTime = Duration(seconds: 3);

  /// The same for the seer: time to take in her vision.
  static const seerLookTime = Duration(seconds: 7);

  /// How long the table hears "the vote is coming" before it does.
  static const voteWarning = Duration(seconds: 5);

  /// Most the leader can add to one phase.
  static const maxExtension = Duration(minutes: 5);

  /// The silent phones as of the start of this phase: the narrator's walk
  /// is planned from them, and a change in the middle of a night must not
  /// show (the lobby shows changes at once).
  Set<PlayerId> _silentAtPhase = const {};

  Set<PlayerId> get _silentNow => {
    for (final s in _sessions.values)
      if (s.silent) s.player,
  };
  bool _closed = false;

  /// Counts every broadcast state, so players drop states that arrive late.
  int _version = 0;

  static const _snapshotVersion = 4;

  /// Called with a fresh [snapshot] after every change, so the app can save
  /// it. It holds every secret of the game: keep it on the host device only.
  void Function(String snapshot)? onSnapshot;

  /// The whole room (game state and sessions) as text, for [GameHost.restore].
  String snapshot() => jsonEncode({
    'v': _snapshotVersion,
    'room': roomCode,
    'epoch': epoch,
    'nextId': _nextId,
    'version': _version,
    'phaseLeftMs': ?(_pausedLeft ?? _phaseLeft()),
    'state': encodeState(_state),
    'sessions': [
      for (final s in _sessions.values)
        {
          'token': s.token,
          'player': s.player.value,
          'owner': s.owner,
          'lastSeq': s.lastSeq,
          'join': ?s.join,
          if (s.candidate case final c?) ...{
            'ck': base64Url.encode(c.key),
            'cs': base64Url.encode(c.secret),
          },
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
  ///
  /// [quietly] closes without the goodbye: the players see a lost host and
  /// look for it again (after [handOver], they find the successor).
  Future<void> close({bool quietly = false}) async {
    if (_closed) return;
    _closed = true;
    _cancelPhaseTimer?.call();
    for (final link in [..._links]) {
      if (quietly) {
        _drop(link);
      } else {
        _bye(link, ByeReason.closed);
      }
    }
    await Future.wait([for (final t in _transports) t.close()]);
  }

  /// Before this host goes away on purpose: gives the successor the newest
  /// room and tells both successor and witness to take over now, without
  /// waiting for the host to be missed. With [leave] in the lobby, the
  /// owner's own seat goes too. Returns whether someone takes over; then
  /// [close] quietly.
  Future<bool> handOver({bool leave = false}) async {
    final custody = this.custody;
    if (_closed || custody == null) return false;
    if (leave && _state.phase == Phase.lobby) {
      final owner = _sessions.values.where((s) => s.owner).firstOrNull;
      if (owner != null) {
        try {
          _state = apply(_state, RemovePlayer(owner.player)).state;
          _sessions.remove(owner.token);
        } on RuleViolation {
          // Not removable: the seat just stays empty.
        }
      }
    }
    _reviewSuccession();
    final successor = _successor;
    final witness = _witness;
    final key = _custodyKey;
    final candidate = successor?.candidate;
    if (successor == null || witness == null || key == null) return false;
    if (candidate == null) return false;
    final sealed = await custody.sealer.seal(
      custody.room(snapshot()),
      key,
      epoch: epoch,
    );
    final s = successor.link;
    final w = witness.link;
    if (_closed || s == null || w == null) return false;
    s.connection.send(
      Custody(
        epoch: epoch,
        version: _version,
        sealed: sealed,
        takeOver: true,
      ).encode(),
    );
    w.connection.send(
      Witness(
        epoch: epoch,
        key: key,
        successor: candidate,
        release: true,
      ).encode(),
    );
    return true;
  }

  /// Picks successor and witness: the first two players, in seat order,
  /// whose devices can host and are connected (never this device's own
  /// player). A new pair gets a new key; whoever loses a part is told to
  /// forget it.
  void _reviewSuccession() {
    final custody = this.custody;
    if (custody == null || _closed) return;
    final order = <_Session>[
      for (final p in _state.players)
        for (final s in _sessions.values)
          if (s.player == p.id &&
              s.candidate != null &&
              s.link != null &&
              !s.link!.owner)
            s,
    ];
    final successor = order.elementAtOrNull(0);
    final witness = order.elementAtOrNull(1);
    if (!identical(successor, _successor) || !identical(witness, _witness)) {
      final before = (_successor, _witness);
      _successor = successor;
      _witness = witness;
      if (before.$1 != null && !identical(before.$1, successor)) {
        before.$1!.link?.connection.send(Custody.drop(epoch: epoch).encode());
      }
      if (before.$2 != null && !identical(before.$2, witness)) {
        before.$2!.link?.connection.send(Witness(epoch: epoch).encode());
      }
      _custodyKey = successor != null && witness != null
          ? custody.sealer.newKey()
          : null;
      _sealedVersion = -1;
      _sendWitness();
    }
    _reseal();
  }

  void _sendWitness() {
    final key = _custodyKey;
    final candidate = _successor?.candidate;
    if (key == null || candidate == null) return;
    _witness?.link?.connection.send(
      Witness(epoch: epoch, key: key, successor: candidate).encode(),
    );
  }

  /// Seals the newest state for the successor; one sealing at a time, the
  /// newest wins.
  void _reseal() {
    final custody = this.custody;
    final key = _custodyKey;
    final successor = _successor;
    if (custody == null || key == null || successor == null) return;
    if (_sealedVersion == _version) return;
    if (_sealing) {
      _resealAgain = true;
      return;
    }
    _sealing = true;
    final version = _version;
    unawaited(
      custody.sealer
          .seal(custody.room(snapshot()), key, epoch: epoch)
          .then((sealed) {
            if (_closed ||
                !identical(_successor, successor) ||
                !identical(_custodyKey, key)) {
              return;
            }
            successor.link?.connection.send(
              Custody(epoch: epoch, version: version, sealed: sealed).encode(),
            );
            _sealedVersion = version;
          })
          .catchError((Object _) {})
          .whenComplete(() {
            _sealing = false;
            if (_resealAgain) {
              _resealAgain = false;
              _reseal();
            }
          }),
    );
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
    if (link.session?.link == link) {
      link.session!.link = null;
      // By day the table sees who is missing (never at night).
      final phase = _state.phase;
      if (!_closed &&
          (phase == Phase.lobby || phase == Phase.day || phase == Phase.vote)) {
        _broadcast();
      }
    }
    unawaited(link.connection.close());
    _reviewSuccession();
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
      final sent = message.sent;
      if (message.version < _version) _sendState(session);
      // A timed ping always gets its pong: it keeps the player's clock in
      // step with the host's.
      if (sent != null || message.version >= _version) {
        link.connection.send(
          Pong(
            _version,
            echo: sent,
            at: sent == null ? null : _clock(),
          ).encode(),
        );
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
    link.web = hello.web;
    if (hello.epoch > epoch) onNewerEpoch?.call(hello.epoch);
    final connection = link.connection;
    final unverified = switch (connection) {
      PeerTrust(verified: false) => true,
      _ => false,
    };
    final seat = hello.handover;
    if (seat != null) {
      // Only with the QR code's secret: the code came from the owner's
      // screen, not from someone guessing on the Wi-Fi.
      if (unverified && !link.owner) {
        return _bye(link, ByeReason.unknownSession);
      }
      return _takeSeat(link, seat, hello.candidate);
    }
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
      _bind(link, session, candidate: hello.candidate);
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
      _bind(link, again, candidate: hello.candidate);
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
    _join(link, hello.name, join: hello.join, candidate: hello.candidate);
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

  void _join(
    _Link link,
    String name, {
    String? join,
    Candidate? candidate,
  }) {
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
    _bind(link, session, candidate: candidate);
    _broadcast();
  }

  void _bind(_Link link, _Session session, {Candidate? candidate}) {
    link.cancelHello?.call();
    link.session = session;
    session.link = link;
    // The device may have changed (or lost its keys) since the last time.
    if (!link.owner) session.candidate = candidate;
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
        epoch: epoch,
      ).encode(),
    );
    // A successor or witness that came back may have lost what it held.
    if (identical(session, _successor)) _sealedVersion = -1;
    if (identical(session, _witness)) _sendWitness();
    if (_pending.length != waited) {
      _broadcast();
    } else {
      _sendState(session);
      _reviewSuccession();
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
        case SkipIntroIntent():
          _ownerOnly(session);
          if (_state.phase != Phase.roleReveal || _introSkippedAt != null) {
            throw const RuleViolation(Violation.wrongPhase);
          }
          _introSkippedAt = _clock();
          _broadcast();
        case SilentIntent(:final silent):
          // Only ever this player's own phone, from their own session.
          if (session.silent == silent) return;
          session.silent = silent;
          if (_state.phase == Phase.lobby) _broadcast();
        case HandoverIntent(:final player, :final code):
          _ownerOnly(session);
          _offerSeat(player, code);
        case ReadyIntent(:final ready):
          _readyToVote(me, ready: ready);
        case LeaderIntent(:final action):
          _ownerOnly(session);
          _lead(action);
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

  /// The owner made [code] to hand [player]'s seat to another device.
  /// Each seat has at most one code, and only a few are open at once.
  void _offerSeat(PlayerId player, String code) {
    final session = _sessions.values
        .where((s) => s.player == player)
        .firstOrNull;
    if (session == null) throw const RuleViolation(Violation.unknownPlayer);
    // The host's own seat stays on the host's device.
    if (session.owner) throw const RuleViolation(Violation.invalidTarget);
    final now = _clock();
    _handovers.removeWhere((_, h) => h.player == player || h.until <= now);
    if (_handovers.length >= 4) {
      throw const RuleViolation(Violation.outOfRange);
    }
    _handovers[code] = (
      player: player,
      until: now + handoverTime.inMilliseconds,
    );
  }

  /// A device brings a handover code: it gets the seat with a new token,
  /// the old device is let go and its token no longer works. Each code
  /// works once.
  void _takeSeat(_Link link, String code, Candidate? candidate) {
    final offer = _handovers.remove(code);
    final old = offer == null
        ? null
        : _sessions.values.where((s) => s.player == offer.player).firstOrNull;
    if (offer == null || offer.until <= _clock() || old == null) {
      return _bye(link, ByeReason.unknownSession);
    }
    _sessions.remove(old.token);
    final previous = old.link;
    if (previous != null && previous != link) {
      _bye(previous, ByeReason.replaced);
    }
    final fresh = _Session(_newToken(), old.player, owner: false)
      ..candidate = old.candidate;
    _sessions[fresh.token] = fresh;
    _bind(link, fresh, candidate: candidate);
    _broadcast();
  }

  /// A living player is (no longer) ready to vote. Once more than half
  /// of the living are, everyone hears the vote is coming, and it starts
  /// [voteWarning] later.
  void _readyToVote(PlayerId player, {required bool ready}) {
    if (_state.phase != Phase.day) {
      throw const RuleViolation(Violation.wrongPhase);
    }
    if (!(_state.player(player)?.isAlive ?? false)) {
      throw const RuleViolation(Violation.notYourAction);
    }
    final changed = ready ? _ready.add(player) : _ready.remove(player);
    if (!changed) return;
    final alive = _state.alive.length;
    if (!_voteSoon && _ready.length * 2 > alive && _pausedLeft == null) {
      _voteSoon = true;
      final left = _phaseLeft();
      if (left == null || left > voteWarning.inMilliseconds) {
        _schedulePhaseTimer(remaining: voteWarning, sameStep: true);
      }
    }
    _broadcast();
  }

  /// The game leader's clock: pause and resume any timed phase; extend or
  /// end only the discussion and the vote (at night the leader may be one
  /// of those called, and a night's length must tell nobody anything).
  void _lead(LeaderAction action) {
    final talk = _state.phase == Phase.day || _state.phase == Phase.vote;
    switch (action) {
      case LeaderAction.pause:
        final left = _phaseLeft();
        if (left == null || _pausedLeft != null) {
          throw const RuleViolation(Violation.wrongPhase);
        }
        _cancelPhaseTimer?.call();
        _cancelPhaseTimer = null;
        _phaseDeadline = null;
        _pausedLeft = left;
      case LeaderAction.resume:
        final left = _pausedLeft;
        if (left == null) throw const RuleViolation(Violation.wrongPhase);
        _pausedLeft = null;
        _schedulePhaseTimer(
          remaining: Duration(milliseconds: left),
          sameStep: true,
          beyondLimit: true,
        );
      case LeaderAction.extend:
        final left = _phaseLeft();
        if (!talk || left == null || _extended >= maxExtension) {
          throw const RuleViolation(Violation.wrongPhase);
        }
        const more = Duration(seconds: 30);
        _extended += more;
        _voteSoon = false;
        _schedulePhaseTimer(
          remaining: Duration(milliseconds: left) + more,
          sameStep: true,
          beyondLimit: true,
        );
      case LeaderAction.end:
        if (!talk) throw const RuleViolation(Violation.wrongPhase);
        _pausedLeft = null;
        _commit(apply(_state, const PhaseTimeout()));
        return;
    }
    _broadcast();
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
    // A runoff is a vote of its own: its own time, its own shared start.
    if (before.phase != _state.phase ||
        before.round != _state.round ||
        before.nightStep != _state.nightStep ||
        before.runoff.isEmpty != _state.runoff.isEmpty) {
      if (before.phase != _state.phase) _introSkippedAt = null;
      _silentAtPhase = _silentNow;
      _ready.clear();
      _voteSoon = false;
      _pausedLeft = null;
      _extended = Duration.zero;
      _schedulePhaseTimer();
    } else if (_state.phase == Phase.night &&
        timeLimit(before) != timeLimit(_state)) {
      // The same step with a new limit (nobody in a called step is left to
      // decide): counted from the step's start, not from now.
      final limit = timeLimit(_state);
      if (limit != null) {
        final left = _phaseStartedAt + limit.inMilliseconds - _clock();
        // Whoever just decided still gets a moment to see what came of it
        // (the seer her vision) before eyes close: the step never ends
        // right on the last pick.
        final settle = _state.nightStep == NightStep.inspect
            ? seerLookTime
            : lastPickTime;
        _schedulePhaseTimer(
          remaining: Duration(
            milliseconds: max(left, settle.inMilliseconds),
          ),
          sameStep: true,
        );
      }
    }
    _broadcast();
  }

  void _schedulePhaseTimer({
    Duration? remaining,
    bool sameStep = false,
    bool beyondLimit = false,
  }) {
    if (!sameStep) _phaseStartedAt = _clock();
    _cancelPhaseTimer?.call();
    _cancelPhaseTimer = null;
    _phaseDeadline = null;
    final full = _state.phase == Phase.roleReveal
        ? config.revealTime
        : timeLimit(_state);
    if (full == null) return;
    final duration = remaining == null || (remaining > full && !beyondLimit)
        ? full
        : remaining;
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
    _reviewSuccession();
  }

  void _sendState(_Session session) {
    final link = session.link;
    if (link == null) return;
    link.connection.send(
      StateMessage(
        version: _version,
        view: viewFor(_state, session.player),
        isOwner: session.owner,
        // In the called night only whoever is called sees the time: its
        // changes would tell the others when someone picked.
        phaseEndsInMs:
            _state.phase == Phase.night &&
                _state.settings.nightMode == NightMode.called &&
                nightTask(_state, session.player) == null
            ? null
            : _phaseLeft(),
        phaseAt: _phaseStartedAt == 0 ? null : _phaseStartedAt,
        introSkippedAt: _state.phase == Phase.roleReveal
            ? _introSkippedAt
            : null,
        inBrowser: _state.phase == Phase.lobby
            ? [
                for (final s in _sessions.values)
                  if (s.link?.web ?? false) s.player,
              ]
            : const [],
        silent: [
          ...(_state.phase == Phase.lobby ? _silentNow : _silentAtPhase),
        ],
        ready: _state.phase == Phase.day ? [..._ready] : const [],
        // Who is missing shows by day, never at night (it could hint at
        // who was awake).
        offline:
            _state.phase == Phase.lobby ||
                _state.phase == Phase.day ||
                _state.phase == Phase.vote
            ? [
                for (final s in _sessions.values)
                  if (s.link == null) s.player,
              ]
            : const [],
        paused: _pausedLeft != null,
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
