import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:game_core/game_core.dart';
import 'package:game_host/game_host.dart';
import 'package:game_host/lan.dart';
import 'package:protocol/protocol.dart';
import 'package:secure_channel/secure_channel.dart';
import 'package:whowolf/src/net/dial.dart';
import 'package:whowolf/src/net/discovery.dart';
import 'package:whowolf/src/net/hosted_room.dart';
import 'package:whowolf/src/net/takeover.dart';

/// Opens a connection to the host; called again to reconnect.
typedef Dial = Dialer;

/// Where the connection to the host stands, as the screens show it.
enum SessionStatus { connecting, connected, reconnecting, ended }

/// This app's side of one game, for the screens: a [ChangeNotifier] over the
/// pure-Dart [PlayerLink], which numbers intents, resends them until the
/// host confirms, keeps the newest state and reconnects by itself.
class GameSession extends ChangeNotifier {
  GameSession({
    required String name,
    required this.roomCode,
    required Dial dial,
    String? token,
    String? seat,
    void Function(String token, String name)? onWelcome,
    void Function(List<int> hostKey, List<int> roomSecret)? onRoomKeys,
    void Function()? onEnded,
    LinkConfig config = const LinkConfig(),
    TakeoverKit? takeover,
    HostedRoom? hosted,
    this.relayServer,
    this.notice,
  }) {
    _hosted = hosted;
    _link = PlayerLink(
      name: name,
      roomCode: roomCode,
      dial: dial,
      token: token,
      seat: seat,
      config: config,
      candidate: takeover?.candidate,
      web: kIsWeb,
      onChange: _changed,
      onWelcome: onWelcome,
      onRoomKeys: onRoomKeys,
      onEnded: onEnded,
    );
    if (takeover != null) {
      _succession = Succession(
        link: _link,
        sealer: takeover.sealer,
        openEntrance: () =>
            takeover.openEntrance(room: roomCode, name: _link.name),
        dialSuccessor: (successor) =>
            TakeoverKit.dialSuccessor(roomCode, successor),
        becomeHost: _becomeHost,
      );
    }
    _watchHosting();
    HostLocator.shared.changes.addListener(_announced);
  }

  /// A room with our code was announced while the host is out of reach
  /// (it came back, or someone took over): dial now instead of waiting for
  /// the next retry. The handshake decides whether it is really ours.
  void _announced() {
    if (_link.status != LinkStatus.paused || _hosted != null) return;
    if (HostLocator.shared.newest(roomCode, null) == null) return;
    _link.reconnectNow();
  }

  late final PlayerLink _link;
  Succession? _succession;
  final String roomCode;
  bool _disposed = false;

  /// The relay server a room taken over by this device should use.
  final Uri? relayServer;

  /// The notification text that keeps a hosted room alive (Android).
  final String Function(String room)? notice;

  /// The room this device hosts: the one it opened or restored (passed in
  /// as `hosted`), or the one it took over when the host went away. `null`
  /// on a plain player's device. The session closes it when it ends, or
  /// hands it over when the player leaves.
  HostedRoom? get hosted => _hosted;
  HostedRoom? _hosted;
  Timer? _hostingCheck;
  bool _checking = false;

  /// This device took over the room (for a short note on screen).
  bool tookOver = false;

  Future<void> _becomeHost(String room) async {
    final me = _link.you;
    if (me == null || _disposed) return;
    final hosted = await HostedRoom.takeOver(
      room,
      newOwner: me,
      // Still the old host's clock: this link has not met a new host yet.
      oldClockAhead: _link.clock.offset,
      hostName: _link.name,
      relayServer: relayServer,
      notice: notice,
    );
    if (_disposed) {
      await hosted.close();
      return;
    }
    _hosted = hosted;
    tookOver = true;
    _link.redirect(() async => hosted.host.connectOwner());
    _watchHosting();
    _changed();
  }

  /// While this device hosts: has someone else taken the room over in the
  /// meantime (this device was away, its players moved on)? Announcements
  /// and hellos only hint at it; joining the newer host with this room's
  /// keys and the owner's token proves it, and only then this device steps
  /// down and plays on as a player.
  void _watchHosting() {
    _hostingCheck?.cancel();
    final hosted = _hosted;
    if (hosted == null) return;
    hosted.host.onNewerEpoch = (_) => unawaited(_checkSuperseded());
    HostLocator.shared.warmUp();
    _hostingCheck = Timer.periodic(
      const Duration(seconds: 4),
      (_) => unawaited(_checkSuperseded()),
    );
  }

  Future<void> _checkSuperseded() async {
    final hosted = _hosted;
    final token = _link.token;
    if (hosted == null || token == null || _checking || _disposed) return;
    final mine = hosted.host.epoch;
    // Announcements are only hints: anyone on the Wi-Fi can announce this
    // room with a higher epoch. This device's own view stays where it is
    // until a newer host proved itself on a connection of its own.
    final newer = [
      for (final r in HostLocator.shared.matching(roomCode, hosted.hostKey))
        if (r.epoch > mine) r.lan,
    ];
    if (newer.isEmpty) return;
    _checking = true;
    try {
      final proven = await _proveNewer(
        newer,
        keys: RoomKeys(hostKey: hosted.hostKey, roomSecret: hosted.roomSecret),
        token: token,
        epoch: mine,
      );
      if (proven == null || _disposed || !identical(_hosted, hosted)) return;
      _link.redirect(
        dialerFor(
          keys: RoomKeys(
            hostKey: hosted.hostKey,
            roomSecret: hosted.roomSecret,
          ),
          room: roomCode,
          lan: proven,
          locator: HostLocator.shared,
        ),
        epoch: mine + 1,
      );
      final end = DateTime.now().add(const Duration(seconds: 8));
      while (DateTime.now().isBefore(end) && !_disposed) {
        if (_link.status == LinkStatus.connected && _link.epoch > mine) {
          // The room lives on elsewhere. Close ours without a goodbye
          // (nobody is left on it) and forget its save.
          _hostingCheck?.cancel();
          _hosted = null;
          await hosted.close(quietly: true);
          _changed();
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
      // Not reached after all: stay the host.
      _link.redirect(() async => hosted.host.connectOwner(), epoch: mine);
    } finally {
      _checking = false;
    }
  }

  /// Which of [places] runs this room with a higher epoch than [epoch]:
  /// the encrypted handshake proves the room's key, the welcome to this
  /// player's [token] the epoch. A false announcement fails the handshake;
  /// `null` if none proves itself within a few seconds.
  Future<LanAddress?> _proveNewer(
    List<LanAddress> places, {
    required RoomKeys keys,
    required String token,
    required int epoch,
  }) async {
    Future<Connection> Function() probe(LanAddress at) => () async {
      final connection = await connectSecure(
        await dialHost(at.ip, at.port, timeout: const Duration(seconds: 3)),
        hostKey: keys.hostKey,
        roomSecret: keys.roomSecret,
      );
      try {
        connection.send(
          Hello(
            name: _link.name,
            room: roomCode,
            token: token,
            epoch: epoch,
          ).encode(),
        );
        final first = await connection.messages.first.timeout(
          const Duration(seconds: 3),
        );
        final message = HostMessage.parse(first);
        if (message is Welcome && message.epoch > epoch) {
          return _Proof(connection, at);
        }
      } on Object {
        // Not a host of this room, or an older one.
      }
      await connection.close();
      throw StateError('not newer');
    };
    try {
      final proof =
          await firstConnection([for (final at in places) probe(at)]) as _Proof;
      await proof.close();
      return proof.at;
    } on Object {
      return null;
    }
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  String get name => _link.name;

  SessionStatus get status => switch (_link.status) {
    LinkStatus.connecting => SessionStatus.connecting,
    LinkStatus.connected => SessionStatus.connected,
    LinkStatus.paused => SessionStatus.reconnecting,
    LinkStatus.ended => SessionStatus.ended,
  };

  /// Why the host ended the session; `null` if it just could not be reached.
  ByeReason? get byeReason => _link.byeReason;

  /// The host's protocol version when it speaks another one.
  int? get hostVersion => _link.hostVersion;

  /// Joined without the QR code's secret: waiting for the host's check.
  bool get waitingForHost => _link.waitingForHost;

  /// Joined without the QR code: the player still has to confirm that the
  /// host's screen shows the same symbols.
  bool get needsCodeConfirmation => _link.needsCodeConfirmation;

  /// The host says this player is let in; the code still needs the
  /// player's own comparison (see [PlayerLink.hostSaysAdmitted]).
  bool get hostSaysAdmitted => _link.hostSaysAdmitted;

  /// The host's screen shows the same symbols as ours.
  void confirmCheckCode() => _link.confirmCheckCode();

  /// Symbols to compare with the host, from the encrypted handshake.
  List<int> get checkCode => _link.checkCode;

  /// For the room owner: people waiting to be let in.
  List<PendingJoin> get pending => _link.pending;

  /// In the lobby: who plays in a browser, without the app.
  List<PlayerId> get inBrowser => _link.inBrowser;

  /// Whose phones play no sound (as of this phase's start).
  List<PlayerId> get silent => _link.silent;

  /// In the discussion: who is ready to vote.
  List<PlayerId> get ready => _link.ready;

  /// By day: whose device is not connected.
  List<PlayerId> get offline => _link.offline;

  /// The game leader paused the clock.
  bool get paused => _link.paused;

  /// The newest view of the game (kept while the host is away).
  PlayerView? get view => _link.view;

  /// Whether this player opened the room.
  bool get isOwner => _link.isOwner;

  /// The host refused the name; [rename] tries another.
  bool get nameRefused => _link.nameRefused;

  /// Intents sent but not yet confirmed by the host.
  int get unconfirmed => _link.unconfirmed;

  /// The last refused intent; the screen clears it after showing it.
  Violation? get refused => _link.refused;
  set refused(Violation? value) => _link.refused = value;

  /// Whose phones play sound right now, as the host sees it (connected,
  /// heard from lately, not silent); empty in the lobby.
  List<PlayerId> get voices => _link.voices;

  /// When the current phase began, on this device's clock (synced with
  /// the host's), or `null` until the clocks are in step.
  int? get phaseStartedAtMs => _link.phaseStartedAtMs;

  /// When the room owner skipped the narrator's intro (this device's
  /// clock), if they did in this role reveal.
  int? get introSkippedAtMs => _link.introSkippedAtMs;

  /// When the phase timer runs out, on this device's clock.
  DateTime? get phaseEndsAt {
    final ms = _link.phaseEndsAtMs;
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Sends an intent; it arrives exactly once, even across reconnects.
  /// `false` if too many are still waiting for the host.
  bool send(ClientMessage message) => _link.send(message);

  void rename(String name) => _link.rename(name);

  /// The app came back to the front or the network changed: redial now.
  void reconnectNow() => _link.reconnectNow();

  /// Leaves for good: tells the host (in the lobby) and closes. A device
  /// that hosts hands the room to another player first, if one can take it.
  Future<void> leave() async {
    final hosted = _hosted;
    _hosted = null;
    _hostingCheck?.cancel();
    _succession?.close();
    if (hosted != null) {
      await hosted.leave();
      _link.close();
    } else {
      _link.leave();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    HostLocator.shared.changes.removeListener(_announced);
    _hostingCheck?.cancel();
    _succession?.close();
    _link.close();
    final hosted = _hosted;
    _hosted = null;
    if (hosted != null) unawaited(hosted.close());
    super.dispose();
  }
}

/// A connection that proved a newer host at [at]; only closed again.
class _Proof implements Connection {
  _Proof(this._inner, this.at);

  final Connection _inner;
  final LanAddress at;

  @override
  Stream<String> get messages => _inner.messages;

  @override
  void send(String message) => _inner.send(message);

  @override
  Future<void> close() => _inner.close();
}
