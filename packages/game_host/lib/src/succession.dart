import 'dart:async';

import 'package:game_host/src/custody.dart';
import 'package:game_host/src/host.dart';
import 'package:game_host/src/player_link.dart';
import 'package:game_host/src/transport.dart';
import 'package:protocol/protocol.dart';

void Function() _realTimer(Duration after, void Function() callback) =>
    Timer(after, callback).cancel;

int _realClock() => DateTime.now().millisecondsSinceEpoch;

/// A player's part in taking over the room when the host goes away, in pure
/// Dart. It watches the [link]:
///
/// * As **successor** (the link holds a [HeldCustody]) it opens the
///   candidate entrance once the host has been missing for [after], waits
///   for the witness's key there, opens the sealed room and hands it to
///   [becomeHost].
/// * As **witness** (the link holds a [HeldWitness]) it hands the key over,
///   but only once it misses the host itself for [after]: its own,
///   independent vote that the host is really gone.
///
/// If the host left on purpose (`GameHost.handOver`) both act at once.
/// The app supplies the network parts; the channel between the two is
/// authenticated both ways by the successor's candidate keys.
class Succession {
  /// Starts watching [link].
  Succession({
    required this.link,
    required this.sealer,
    required this.openEntrance,
    required this.dialSuccessor,
    required this.becomeHost,
    this.after = const Duration(seconds: 6),
    this.retry = const Duration(seconds: 2),
    this.speakWithin = const Duration(seconds: 5),
    this._startTimer = _realTimer,
    this._clock = _realClock,
  }) {
    _subscription = link.changes.listen((_) => _review());
    _review();
  }

  /// The player's link to the host.
  final PlayerLink link;

  /// Opens the sealed room.
  final RoomSealer sealer;

  /// Opens this device's candidate entrance: a transport whose connections
  /// all proved the candidate secret (only the witness knows it). Closing
  /// it withdraws the entrance.
  final Future<Transport> Function() openEntrance;

  /// Connects to the successor's entrance, authenticated with its
  /// candidate keys; fails if it is not there (yet).
  final Future<Connection> Function(Candidate successor) dialSuccessor;

  /// Hosts the opened room from now on (this device takes over).
  final Future<void> Function(String room) becomeHost;

  /// How long the host must be missing before anyone acts.
  final Duration after;

  /// Pause between the witness's attempts to reach the successor.
  final Duration retry;

  /// A connection to the entrance must hand over the key within this time.
  final Duration speakWithin;

  final StartTimer _startTimer;
  final Clock _clock;
  late final StreamSubscription<void> _subscription;

  void Function()? _cancelWait;
  void Function()? _cancelRetry;
  Transport? _entrance;
  bool _opening = false;
  bool _dialing = false;
  bool _closed = false;

  /// This device took over; nothing more to do.
  bool get tookOver => _tookOver;
  bool _tookOver = false;

  /// Epochs whose key this device already handed over.
  final _released = <int>{};

  /// Whether the host has been missing long enough to act.
  bool get _hostGone {
    final since = link.pausedSinceMs;
    return link.status == LinkStatus.paused &&
        since != null &&
        _clock() - since >= after.inMilliseconds;
  }

  void _review() {
    if (_closed || _tookOver) return;
    if (link.status == LinkStatus.ended) return close();
    final gone = _hostGone;
    final custody = link.custody;
    final witness = link.witness;
    if (custody != null && (custody.takeOver || gone)) {
      unawaited(_open());
    } else if (_entrance != null && link.status == LinkStatus.connected) {
      // The host is back before anyone took over: nothing to wait for.
      _closeEntrance();
    }
    if (witness != null &&
        !_released.contains(witness.epoch) &&
        (witness.release || gone)) {
      unawaited(_dial(witness));
    }
    _cancelWait?.call();
    _cancelWait = null;
    final since = link.pausedSinceMs;
    if (!gone && since != null && link.status == LinkStatus.paused) {
      final left = after.inMilliseconds - (_clock() - since);
      _cancelWait = _startTimer(
        Duration(milliseconds: left < 0 ? 0 : left),
        _review,
      );
    }
  }

  Future<void> _open() async {
    if (_entrance != null || _opening) return;
    _opening = true;
    try {
      final entrance = await openEntrance();
      if (_closed || _tookOver) {
        await entrance.close();
        return;
      }
      _entrance = entrance;
      entrance.connections.listen(_visitor);
    } on Object {
      // No entrance possible (no network): another try on the next change.
    } finally {
      _opening = false;
    }
  }

  /// One connection to the entrance: it gets one message and a few seconds
  /// for it, then it is closed whatever it said.
  void _visitor(Connection connection) {
    final cancel = _startTimer(speakWithin, () {
      unawaited(connection.close());
    });
    late final StreamSubscription<String> subscription;
    subscription = connection.messages.listen((raw) async {
      cancel();
      await subscription.cancel();
      await connection.close();
      await _received(raw);
    }, onDone: cancel);
  }

  Future<void> _received(String raw) async {
    final custody = link.custody;
    if (_tookOver || _closed || custody == null) return;
    final Release release;
    try {
      release = Release.parse(raw);
    } on ProtocolError {
      return;
    }
    if (release.epoch != custody.epoch) return;
    final room = await sealer.open(
      custody.sealed,
      release.key,
      epoch: custody.epoch,
    );
    if (room == null || _tookOver || _closed) return;
    _tookOver = true;
    _closeEntrance();
    _cancelWait?.call();
    await becomeHost(room);
  }

  Future<void> _dial(HeldWitness witness) async {
    if (_dialing) return;
    _dialing = true;
    try {
      final connection = await dialSuccessor(witness.successor);
      connection.send(Release(epoch: witness.epoch, key: witness.key).encode());
      _released.add(witness.epoch);
      // The successor hangs up after reading; this is only a backstop.
      _startTimer(speakWithin, () => unawaited(connection.close()));
    } on Object {
      // Not there yet: try again a little later, while it still counts.
      _cancelRetry?.call();
      _cancelRetry = _startTimer(retry, _review);
    } finally {
      _dialing = false;
    }
  }

  void _closeEntrance() {
    final entrance = _entrance;
    _entrance = null;
    if (entrance != null) unawaited(entrance.close());
  }

  /// Stops watching; an open entrance closes.
  void close() {
    if (_closed) return;
    _closed = true;
    _cancelWait?.call();
    _cancelRetry?.call();
    _closeEntrance();
    unawaited(_subscription.cancel());
  }
}
