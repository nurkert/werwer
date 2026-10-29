import 'dart:async';
import 'dart:math';

import 'package:game_core/game_core.dart';
import 'package:game_host/src/clock_sync.dart';
import 'package:game_host/src/host.dart';
import 'package:game_host/src/transport.dart';
import 'package:protocol/protocol.dart';

/// Opens a connection to the host; called again for every reconnect.
typedef Dialer = Future<Connection> Function();

/// Where a player's link to the host stands.
enum LinkStatus {
  /// First connection, not joined yet.
  connecting,

  /// Joined and connected.
  connected,

  /// The host is out of reach: a calm pause, the link keeps trying.
  paused,

  /// Over for good (left, removed, or the host closed the room).
  ended,
}

/// Timings of a [PlayerLink].
class LinkConfig {
  /// Creates a configuration; the defaults suit a table in one Wi-Fi.
  const LinkConfig({
    this.ping = const Duration(seconds: 3),
    this.resend = const Duration(seconds: 2),
    this.answer = const Duration(seconds: 8),
    this.firstRetry = const Duration(milliseconds: 500),
    this.maxRetry = const Duration(seconds: 5),
    this.maxQueue = 64,
    this.joinAttempts = 6,
    this.holderPing = const Duration(seconds: 1),
  });

  /// How often a successor or witness says "still here": the host keeps
  /// moving the game on only while it hears from one of them.
  final Duration holderPing;

  /// How often a connected player says "still here" with its state version.
  final Duration ping;

  /// How often unconfirmed intents are sent again.
  final Duration resend;

  /// A connection that says nothing for this long is given up and redialled.
  final Duration answer;

  /// First pause before redialling; it doubles up to [maxRetry].
  final Duration firstRetry;

  /// Longest pause between redials.
  final Duration maxRetry;

  /// Most unconfirmed intents kept; beyond that new ones are refused.
  final int maxQueue;

  /// How often a first join is tried before giving up (a host that never
  /// answers at all is probably not there).
  final int joinAttempts;
}

/// One player's side of a room, in pure Dart: it joins, keeps the newest
/// state, numbers every intent and resends it until the host confirms it,
/// and reconnects by itself, as long as it takes. The app, the command-line
/// client and the chaos tests all use it.
///
/// The host being gone for a while is a normal state ([LinkStatus.paused]),
/// Most messages a player holds from an unchecked host while the code is
/// compared (states replace each other and count once).
const maxHeldMessages = 16;

/// not an error: the last view stays, nothing typed in the meantime is lost.
class PlayerLink {
  /// Starts joining [roomCode] under the given name through the dialer.
  PlayerLink({
    required this._name,
    required this.roomCode,
    required this._dial,
    this._token,
    this._seat,
    this.candidate,
    this._epoch = 0,
    this.config = const LinkConfig(),
    this.web = false,
    this.onChange,
    this.onWelcome,
    this.onRoomKeys,
    this.onEnded,
    this._startTimer = _timer,
    this._clock = _now,
    Random? random,
  }) : _random = random ?? Random.secure() {
    unawaited(_connect());
  }

  static void Function() _timer(Duration after, void Function() callback) =>
      Timer(after, callback).cancel;

  static int _now() => DateTime.now().millisecondsSinceEpoch;

  /// The room code.
  final String roomCode;

  /// Timings.
  final LinkConfig config;

  /// Called after every change of what the player sees.
  final void Function()? onChange;

  /// Called with the session token and the accepted name once welcomed.
  final void Function(String token, String name)? onWelcome;

  /// Called with the room's key and secret when the host let this player in
  /// after comparing the check code; later dials should use them.
  final void Function(List<int> hostKey, List<int> roomSecret)? onRoomKeys;

  /// Called once when the link ends for good.
  final void Function()? onEnded;

  /// This device's keys for taking over the room, if it can host (see
  /// [Custody]); sent with every hello.
  final Candidate? candidate;

  Dialer _dial;
  final StartTimer _startTimer;
  final Clock _clock;
  final Random _random;

  String _name;
  String? _token;

  /// A one-time code that hands this device an existing seat; sent with
  /// the first hello only, until a token replaces it.
  String? _seat;

  /// This link's join number (see [Hello.join]). Over a checked channel it
  /// claims a seat like a token does, so it comes from a secure random
  /// source unless a test passes its own.
  late final String _join = List.generate(
    tokenLength,
    (_) => _random.nextInt(16).toRadixString(16),
  ).join();
  Connection? _connection;
  StreamSubscription<String>? _subscription;
  final _timers = <void Function()>[];
  void Function()? _cancelRetry;
  void Function()? _cancelSilence;
  int _attempt = 0;
  bool _closed = false;

  /// Intents not yet confirmed, oldest first. They get their number only
  /// once the host has welcomed this link, so numbers always continue the
  /// host's count without gaps.
  final _queue = <_Queued>[];

  /// Intents the host confirmed, newest last, kept for a while: if the
  /// host dies before its successor's copy holds them, the successor's
  /// count is lower and they go to the new host again (its numbers make
  /// that safe: nothing counts twice). At most [LinkConfig.maxQueue].
  final _confirmedIntents = <_Queued>[];

  /// The highest number the host has confirmed.
  int _confirmed = 0;
  bool _joined = false;

  /// Where the link stands.
  LinkStatus status = LinkStatus.connecting;

  /// The newest view of the game (kept during a pause).
  PlayerView? view;

  /// Version of [view]; older states are dropped.
  int version = -1;

  /// The room epoch [version] counts in: a new host after a takeover
  /// counts from its own (older) copy, so its states are taken whatever
  /// their number.
  late int _versionEpoch = _epoch;

  /// Whether this player opened the room.
  bool isOwner = false;

  /// For the owner: people waiting to be let in.
  List<PendingJoin> pending = const [];

  /// In the lobby: who plays in a browser, without the app.
  List<PlayerId> inBrowser = const [];

  /// Whose phones play no sound, as of this phase's start (the host's).
  List<PlayerId> silent = const [];

  /// In the discussion: who is ready to vote.
  List<PlayerId> ready = const [];

  /// By day: whose device is not connected.
  List<PlayerId> offline = const [];

  /// In a running game: whose phones play sound right now (see
  /// [StateMessage.voices]).
  List<PlayerId> voices = const [];

  /// A state that shows at an agreed moment, and its timer.
  StateMessage? _upcoming;
  void Function()? _cancelUpcoming;

  /// When the next phase shows, on this device's clock, while it is still
  /// ahead: the step on screen is over, taps on it come too late.
  int? get switchingAtMs {
    final at = _upcoming?.showAt;
    return at == null ? null : clock.toLocal(at);
  }

  /// The game leader paused the clock.
  bool paused = false;

  /// The game leader locked the room: nobody new may ask to join.
  bool locked = false;

  /// This player is in a browser (the host shows it in the lobby).
  final bool web;

  /// When the phase timer runs out, on this device's clock (milliseconds):
  /// the host's agreed end once the clocks are in step, until then counted
  /// from when the state arrived.
  int? get phaseEndsAtMs {
    final at = _phaseEndsAtHost;
    return (at == null ? null : clock.toLocal(at)) ?? _phaseEndsAtArrival;
  }

  int? _phaseEndsAtHost;
  int? _phaseEndsAtArrival;

  /// Joined without the QR code's secret, or into a running game: waiting
  /// for the game leader's check.
  bool waitingForHost = false;

  /// While [waitingForHost]: the game is under way, so the game leader
  /// decides by day; the wait may last through a night.
  bool waitingForDay = false;

  /// Symbols to compare with the host, from the encrypted handshake.
  List<int> checkCode = const [];

  /// Joining over a channel nobody checked (no QR code): until the player
  /// confirms that the host's screen shows the same [checkCode], nothing
  /// from the host counts. Someone in the middle could otherwise answer in
  /// the host's place, skip the comparison and hand over keys of his own.
  bool get needsCodeConfirmation => _unchecked && !_codeConfirmed;

  /// The host (or whoever answers in its place) says the player is let
  /// in, while the code still waits for the player's own comparison. Only
  /// for the wording on screen: nothing counts until [confirmCheckCode].
  bool get hostSaysAdmitted => needsCodeConfirmation && _held.isNotEmpty;

  bool _unchecked = false;
  bool _codeConfirmed = false;

  /// Until then (this device's clock) refusals are not shown: they answer
  /// intents replayed to a new host.
  int _quietUntil = 0;

  /// Messages that arrived on an unchecked channel before the player
  /// confirmed the check code; they count once [confirmCheckCode] is called.
  final _held = <String>[];

  /// Where the held state is in [_held], if one is held.
  int? _heldStateAt;

  /// The host refused the name; [rename] tries another one.
  bool nameRefused = false;

  /// The last refused intent; the UI clears it after showing it.
  Violation? refused;

  /// Why the link ended, if the host said so.
  ByeReason? byeReason;

  /// The host's protocol version, if it said it speaks another one (then
  /// [byeReason] is [ByeReason.version]).
  int? hostVersion;

  /// How many times the room changed hands, as far as this link knows. A
  /// host with a smaller epoch is out of date and not joined.
  int get epoch => _epoch;
  int _epoch;

  /// How this device's clock stands to the host's (from timed pings).
  final clock = ClockSync();

  /// When the current phase began, on the host's clock.
  int? phaseStartedAtHostMs;

  /// When the current phase began, on this device's clock: shared moments
  /// planned from it sound at the same instant on every phone. `null`
  /// until the clocks are in step.
  int? get phaseStartedAtMs {
    final at = phaseStartedAtHostMs;
    return at == null ? null : clock.toLocal(at);
  }

  /// When the room owner skipped the narrator's intro, on the host's clock.
  int? introSkippedAtHostMs;

  /// The same on this device's clock; `null` unless skipped (and while the
  /// clocks are not in step).
  int? get introSkippedAtMs {
    final at = introSkippedAtHostMs;
    return at == null ? null : clock.toLocal(at);
  }

  /// For the successor: the sealed room, if the host chose this player.
  HeldCustody? custody;

  /// For the witness: the key to the successor's room and how to reach it.
  HeldWitness? witness;

  /// Since when the host has been out of reach (this device's clock), or
  /// `null` while connected.
  int? pausedSinceMs;

  final _changes = StreamController<void>.broadcast(sync: true);

  /// Fires after every change, like [onChange], for more than one listener
  /// (the takeover watches the link too).
  Stream<void> get changes => _changes.stream;

  /// The session token, once welcomed. Never log or show it.
  String? get token => _token;

  /// This player's id, once welcomed.
  PlayerId? you;

  /// The name this player joins with.
  String get name => _name;

  /// Number of intents still waiting for the host's confirmation.
  int get unconfirmed => _queue.length;

  /// The highest intent number the host has confirmed.
  int get confirmed => _confirmed;

  void _changed() {
    onChange?.call();
    if (!_changes.isClosed) _changes.add(null);
  }

  Future<void> _connect() async {
    if (_closed) return;
    final Connection connection;
    try {
      connection = await _dial();
    } on Object {
      return _lost();
    }
    if (_closed) {
      await connection.close();
      return;
    }
    _unchecked = false;
    _codeConfirmed = false;
    _held.clear();
    _heldStateAt = null;
    if (connection case final PeerTrust trust) {
      checkCode = trust.checkCode;
      // Every unchecked channel has its own code: it is confirmed anew.
      _unchecked = !trust.verified;
      // A token never goes over a channel nobody checked: someone in the
      // middle could take it and play as us.
      if (_token != null && !trust.verified) {
        await connection.close();
        return _end(ByeReason.unknownSession);
      }
    }
    _connection = connection;
    _subscription = connection.messages.listen(
      (raw) => _receive(connection, raw),
      onDone: () => _dropped(connection),
      onError: (Object _) => _dropped(connection),
      cancelOnError: true,
    );
    _expectAnswer(connection);
    connection.send(
      Hello(
        name: _name,
        room: roomCode,
        token: _token,
        join: _join,
        candidate: candidate,
        epoch: _epoch,
        web: web,
        handover: _token == null ? _seat : null,
      ).encode(),
    );
  }

  /// Redials if [connection] stays silent: a half-dead link (e.g. after the
  /// phone slept) is noticed without waiting for the operating system.
  void _expectAnswer(Connection connection) {
    _cancelSilence?.call();
    _cancelSilence = _startTimer(config.answer, () {
      if (_connection == connection) unawaited(connection.close());
    });
  }

  void _receive(Connection connection, String raw) {
    if (_closed || _connection != connection) return;
    final HostMessage message;
    try {
      message = HostMessage.parse(raw);
    } on ProtocolError {
      // The host speaks another version: no use waiting for it.
      final theirs = parseVersionNotice(raw);
      if (theirs != null && theirs != protocolVersion) {
        hostVersion = theirs;
        _end(ByeReason.version);
      }
      return;
    }
    // Until the code is confirmed, the host's answers wait: a welcome,
    // state or keys from an unchecked channel could come from anyone.
    if (needsCodeConfirmation &&
        message is! Waiting &&
        message is! Bye &&
        message is! Refused) {
      _cancelSilence?.call();
      // Bounded: only the latest state counts, and a host that keeps
      // sending anything else while the code is compared is not one to
      // wait for (an unchecked host could be anyone on the Wi-Fi).
      final state = message is StateMessage;
      final last = _heldStateAt;
      if (state && last != null) {
        _held[last] = raw;
      } else {
        if (_held.length >= maxHeldMessages) {
          unawaited(connection.close());
          return;
        }
        if (state) _heldStateAt = _held.length;
        _held.add(raw);
      }
      _changed();
      return;
    }
    // While the owner compares the code nothing more comes; that silence is
    // expected, not a dead connection.
    if (message is Waiting) {
      _cancelSilence?.call();
    } else {
      _expectAnswer(connection);
    }
    switch (message) {
      case Waiting(:final running):
        waitingForHost = true;
        waitingForDay = running;
      case Welcome(
        :final token,
        :final roomSecret,
        :final lastSeq,
        epoch: final hostEpoch,
        you: final me,
      ):
        // One welcome per connection; a late copy would rewind the count.
        if (_joined) return;
        // A host from before a takeover (it came back late): not ours any
        // more. Hang up and keep looking for the current one.
        if (hostEpoch < _epoch) {
          unawaited(connection.close());
          return;
        }
        if (hostEpoch > _epoch) {
          _epoch = hostEpoch;
          // Whatever we held belonged to the old host.
          custody = null;
          witness = null;
        }
        if (hostEpoch > _versionEpoch) {
          _versionEpoch = hostEpoch;
          version = -1;
          // Another host, another clock. The same host after a reconnect
          // keeps its clock, so its times are right at once.
          clock.reset();
          // The new host may be a few steps behind what we saw: what it
          // refuses of our replayed intents is no news for the player.
          _quietUntil = _clock() + config.resend.inMilliseconds * 3;
        }
        you = me;
        _welcomed(connection, token, roomSecret, lastSeq);
      case Custody(
        :final epoch,
        :final version,
        :final sealed,
        :final takeOver,
      ):
        if (epoch != _epoch) return;
        if (sealed.isEmpty) {
          custody = null;
        } else if (custody == null || version >= custody!.version || takeOver) {
          custody = HeldCustody(
            epoch: epoch,
            version: version,
            sealed: sealed,
            takeOver: takeOver,
          );
        }
      case Witness(:final epoch, :final key, :final successor, :final release):
        if (epoch != _epoch) return;
        witness = key == null || successor == null
            ? null
            : HeldWitness(
                epoch: epoch,
                key: key,
                successor: successor,
                release: release,
              );
      case Ack(:final seq, version: final hostVersion):
        _queue.removeWhere((q) {
          final done = q.seq != null && q.seq! <= seq;
          if (done) _confirmedIntents.add(q);
          return done;
        });
        final over = _confirmedIntents.length - config.maxQueue;
        if (over > 0) _confirmedIntents.removeRange(0, over);
        _confirmed = max(_confirmed, seq);
        if (hostVersion > version) _ping();
        return;
      case Pong(version: final hostVersion, :final echo, :final at):
        if (echo != null && at != null) {
          clock.add(sent: echo, hostAt: at, received: _clock());
        }
        if (hostVersion > version) _ping();
        return;
      case StateMessage():
        if (message.version < version) return;
        // The host claimed the room anew (its pair was out of reach): what
        // this device held for the old epoch is void, new parts follow.
        if (message.epoch > _epoch) {
          _epoch = message.epoch;
          _versionEpoch = max(_versionEpoch, message.epoch);
          custody = null;
          witness = null;
        }
        version = message.version;
        _cancelUpcoming?.call();
        _cancelUpcoming = null;
        _upcoming = null;
        final showAt = message.showAt;
        final at = showAt == null ? null : clock.toLocal(showAt);
        final wait = at == null ? 0 : at - _clock();
        if (wait > 0) {
          // Decided, shown at the agreed moment, on every phone at once;
          // also if this link drops in between. What the host refuses
          // meanwhile answers taps on the step that is over.
          final state = message;
          _upcoming = state;
          _quietUntil = max(_quietUntil, at! + config.resend.inMilliseconds);
          _cancelUpcoming = _startTimer(Duration(milliseconds: wait), () {
            if (_closed || !identical(_upcoming, state)) return;
            _upcoming = null;
            _cancelUpcoming = null;
            _show(state);
            _changed();
          });
        } else {
          _show(message);
        }
      case Refused(:final reason):
        if (reason == Violation.invalidName && _token == null) {
          nameRefused = true;
        } else if (_clock() >= _quietUntil) {
          refused = reason;
        }
      case Bye(:final reason):
        return _end(reason);
    }
    _changed();
  }

  /// Shows [message]: the view and everything that goes with it.
  void _show(StateMessage message) {
    view = message.view;
    voices = message.voices;
    isOwner = message.isOwner;
    pending = message.pending;
    inBrowser = message.inBrowser;
    silent = message.silent;
    ready = message.ready;
    offline = message.offline;
    paused = message.paused;
    locked = message.locked;
    phaseStartedAtHostMs = message.phaseAt;
    introSkippedAtHostMs = message.introSkippedAt;
    final endsIn = message.phaseEndsInMs;
    _phaseEndsAtArrival = endsIn == null ? null : _clock() + endsIn;
    _phaseEndsAtHost = endsIn == null ? null : message.phaseEndsAt;
  }

  void _welcomed(
    Connection connection,
    String token,
    List<int>? roomSecret,
    int lastSeq,
  ) {
    waitingForHost = false;
    waitingForDay = false;
    nameRefused = false;
    if (connection case PeerTrust(
      verified: false,
      :final peerKey?,
    ) when roomSecret != null) {
      onRoomKeys?.call(peerKey, roomSecret);
    }
    _token = token;
    _seat = null;
    _attempt = 0;
    status = LinkStatus.connected;
    pausedSinceMs = null;
    // Everything up to lastSeq arrived. A host with a lower count (a
    // successor whose copy was older) lacks some confirmed intents: they
    // go again, in order, before the rest; numbered on from its count,
    // there is no gap it would wait for forever.
    _queue.removeWhere((q) => q.seq != null && q.seq! <= lastSeq);
    final lost = [
      for (final q in _confirmedIntents)
        if (q.seq! > lastSeq) q,
    ];
    _confirmedIntents.removeWhere((q) => q.seq! > lastSeq);
    _queue.insertAll(0, lost);
    _confirmed = lastSeq;
    for (final (i, q) in _queue.indexed) {
      q.seq = lastSeq + 1 + i;
    }
    _joined = true;
    _flush();
    _startLoops(connection);
    onWelcome?.call(token, _name);
  }

  void _startLoops(Connection connection) {
    _stopLoops();
    void every(Duration period, void Function() action) {
      void tick() {
        if (_closed || _connection != connection) return;
        action();
        _timers.add(_startTimer(period, tick));
      }

      _timers.add(_startTimer(period, tick));
    }

    every(config.ping, _ping);
    every(config.holderPing, () {
      if (custody != null || witness != null) _ping();
    });
    // A few quick pings at the start put the clocks in step at once.
    for (final ms in const [0, 250, 600]) {
      _timers.add(
        _startTimer(Duration(milliseconds: ms), () {
          if (!_closed && _connection == connection) _ping();
        }),
      );
    }
    every(config.resend, _flush);
  }

  void _stopLoops() {
    for (final cancel in _timers) {
      cancel();
    }
    _timers.clear();
  }

  void _flush() {
    if (!_joined) return;
    for (final q in _queue) {
      _connection?.send(q.intent.encode(seq: q.seq));
    }
  }

  void _send(ClientMessage message) => _connection?.send(message.encode());

  /// "Still here", with this device's time for the clock sync.
  void _ping() => _send(PingIntent(max(version, 0), sent: _clock()));

  void _dropped(Connection connection) {
    if (_connection != connection) return;
    _lost();
  }

  void _lost() {
    if (_closed) return;
    unawaited(_subscription?.cancel());
    _subscription = null;
    _connection = null;
    _joined = false;
    _cancelSilence?.call();
    _stopLoops();
    // Never joined: a few more tries (the first hello may just have been
    // lost), then there is nothing to wait for. A link that already saw its
    // seat (only the welcome got lost) has a place to come back to.
    final joining = _token == null && !waitingForHost && view == null;
    if (joining && _attempt + 1 >= config.joinAttempts) return _end(null);
    if (!joining) {
      status = LinkStatus.paused;
      pausedSinceMs ??= _clock();
    }
    _changed();
    // Back off with some randomness, so a table of phones does not hammer a
    // host that just came back all at the same moment.
    final base = config.firstRetry.inMilliseconds * pow(2, min(_attempt, 8));
    final capped = min(base.toInt(), config.maxRetry.inMilliseconds);
    final delay = (capped * (0.5 + _random.nextDouble() / 2)).round();
    _attempt++;
    _cancelRetry?.call();
    _cancelRetry = _startTimer(Duration(milliseconds: delay), () {
      if (!_closed && _connection == null) unawaited(_connect());
    });
  }

  void _end(ByeReason? reason) {
    if (_closed) return;
    byeReason ??= reason;
    status = LinkStatus.ended;
    _closed = true;
    _cancelUpcoming?.call();
    custody = null;
    witness = null;
    _stopLoops();
    _cancelRetry?.call();
    _cancelSilence?.call();
    unawaited(_subscription?.cancel());
    unawaited(_connection?.close());
    _connection = null;
    onEnded?.call();
    _changed();
  }

  /// Sends an intent; it is numbered and sent again until the host confirms
  /// it, across reconnects, and applied exactly once.
  /// Returns whether the intent was taken (false when the link ended or too
  /// many intents are still unconfirmed).
  bool send(ClientMessage intent) {
    if (_closed) return false;
    if (intent is Hello || intent is PingIntent) {
      _send(intent);
      return true;
    }
    // Full: refuse the new one rather than drop an old one, which would
    // leave a gap in the numbers.
    if (_queue.length >= config.maxQueue) return false;
    final q = _Queued(intent);
    _queue.add(q);
    if (_joined) {
      q.seq = _confirmed + _queue.length;
      _connection?.send(intent.encode(seq: q.seq));
    }
    return true;
  }

  /// The player saw the same symbols on the host's screen: what the host
  /// sent meanwhile counts now, and the join goes on.
  void confirmCheckCode() {
    final connection = _connection;
    if (!needsCodeConfirmation || connection == null) return;
    _codeConfirmed = true;
    final held = [..._held];
    _held.clear();
    _heldStateAt = null;
    for (final raw in held) {
      _receive(connection, raw);
    }
    _changed();
  }

  /// Joins with another name after the host refused the first one.
  void rename(String name) {
    _name = name.trim();
    nameRefused = false;
    _send(Hello(name: _name, room: roomCode, join: _join, web: web));
    _changed();
  }

  /// Redials at once if the host is out of reach (the app came back to the
  /// front, or the network changed).
  void reconnectNow() {
    if (_closed || _connection != null) return;
    _cancelRetry?.call();
    _attempt = 0;
    unawaited(_connect());
  }

  /// From now on dials through [dial] (this device took over the room and
  /// hosts it itself), at once. Queued intents go to the new host. With
  /// [epoch] only a host of at least that epoch is joined from now on.
  void redirect(Dialer dial, {int? epoch}) {
    if (_closed) return;
    _dial = dial;
    if (epoch != null) _epoch = epoch;
    final connection = _connection;
    if (connection != null) {
      unawaited(connection.close());
    } else {
      reconnectNow();
    }
  }

  /// Leaves for good: tells the host (in the lobby) and stops.
  void leave() {
    if (view?.phase == Phase.lobby) _send(const LeaveIntent());
    _end(ByeReason.left);
  }

  /// Stops without telling the host (the app is closing this screen).
  void close() {
    if (_closed) return;
    _closed = true;
    _cancelUpcoming?.call();
    custody = null;
    witness = null;
    unawaited(_changes.close());
    _stopLoops();
    _cancelRetry?.call();
    _cancelSilence?.call();
    unawaited(_subscription?.cancel());
    unawaited(_connection?.close());
  }
}

class _Queued {
  _Queued(this.intent);

  final ClientMessage intent;
  int? seq;
}

/// The successor's copy of the room: sealed, so only the witness's key
/// opens it.
class HeldCustody {
  /// Creates the copy.
  const HeldCustody({
    required this.epoch,
    required this.version,
    required this.sealed,
    this.takeOver = false,
  });

  /// The room epoch it belongs to.
  final int epoch;

  /// The state version inside.
  final int version;

  /// The sealed room.
  final String sealed;

  /// The host left on purpose: take over without waiting.
  final bool takeOver;
}

/// The witness's part: the key and the successor to give it to.
class HeldWitness {
  /// Creates the part.
  const HeldWitness({
    required this.epoch,
    required this.key,
    required this.successor,
    this.release = false,
  });

  /// The room epoch it belongs to.
  final int epoch;

  /// The key to the sealed room. Never log it.
  final List<int> key;

  /// How to reach the successor.
  final Candidate successor;

  /// The host left on purpose: hand the key over without waiting.
  final bool release;
}
