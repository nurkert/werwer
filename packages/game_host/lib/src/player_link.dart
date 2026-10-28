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
  });

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
/// not an error: the last view stays, nothing typed in the meantime is lost.
class PlayerLink {
  /// Starts joining [roomCode] under the given name through the dialer.
  PlayerLink({
    required this._name,
    required this.roomCode,
    required this._dial,
    this._token,
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

  /// The highest number the host has confirmed.
  int _confirmed = 0;
  bool _joined = false;

  /// Where the link stands.
  LinkStatus status = LinkStatus.connecting;

  /// The newest view of the game (kept during a pause).
  PlayerView? view;

  /// Version of [view]; older states are dropped.
  int version = -1;

  /// Whether this player opened the room.
  bool isOwner = false;

  /// For the owner: people waiting to be let in.
  List<PendingJoin> pending = const [];

  /// In the lobby: who plays in a browser, without the app.
  List<PlayerId> inBrowser = const [];

  /// This player is in a browser (the host shows it in the lobby).
  final bool web;

  /// When the phase timer runs out, on this device's clock (milliseconds).
  int? phaseEndsAtMs;

  /// Joined without the QR code's secret: waiting for the host's check.
  bool waitingForHost = false;

  /// Symbols to compare with the host, from the encrypted handshake.
  List<int> checkCode = const [];

  /// Joining over a channel nobody checked (no QR code): until the player
  /// confirms that the host's screen shows the same [checkCode], nothing
  /// from the host counts. Someone in the middle could otherwise answer in
  /// the host's place, skip the comparison and hand over keys of his own.
  bool get needsCodeConfirmation => _unchecked && !_codeConfirmed;

  bool _unchecked = false;
  bool _codeConfirmed = false;

  /// Messages that arrived on an unchecked channel before the player
  /// confirmed the check code; they count once [confirmCheckCode] is called.
  final _held = <String>[];

  /// The host refused the name; [rename] tries another one.
  bool nameRefused = false;

  /// The last refused intent; the UI clears it after showing it.
  Violation? refused;

  /// Why the link ended, if the host said so.
  ByeReason? byeReason;

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
    // Possibly another host now (after a takeover): another clock.
    clock.reset();
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
      return;
    }
    // Until the code is confirmed, the host's answers wait: a welcome,
    // state or keys from an unchecked channel could come from anyone.
    if (needsCodeConfirmation &&
        message is! Waiting &&
        message is! Bye &&
        message is! Refused) {
      _cancelSilence?.call();
      _held.add(raw);
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
      case Waiting():
        waitingForHost = true;
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
        _queue.removeWhere((q) => q.seq != null && q.seq! <= seq);
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
        version = message.version;
        view = message.view;
        isOwner = message.isOwner;
        pending = message.pending;
        inBrowser = message.inBrowser;
        phaseStartedAtHostMs = message.phaseAt;
        introSkippedAtHostMs = message.introSkippedAt;
        final endsIn = message.phaseEndsInMs;
        phaseEndsAtMs = endsIn == null ? null : _clock() + endsIn;
      case Refused(:final reason):
        if (reason == Violation.invalidName && _token == null) {
          nameRefused = true;
        } else {
          refused = reason;
        }
      case Bye(:final reason):
        return _end(reason);
    }
    _changed();
  }

  void _welcomed(
    Connection connection,
    String token,
    List<int>? roomSecret,
    int lastSeq,
  ) {
    waitingForHost = false;
    nameRefused = false;
    if (connection case PeerTrust(
      verified: false,
      :final peerKey?,
    ) when roomSecret != null) {
      onRoomKeys?.call(peerKey, roomSecret);
    }
    _token = token;
    _attempt = 0;
    status = LinkStatus.connected;
    pausedSinceMs = null;
    // Everything up to lastSeq arrived. If the host lost some confirmed
    // intents (restored from an older save), the rest continues from its
    // count instead of leaving a gap it would wait for forever.
    if (lastSeq >= _confirmed) {
      _queue.removeWhere((q) => q.seq != null && q.seq! <= lastSeq);
    }
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
