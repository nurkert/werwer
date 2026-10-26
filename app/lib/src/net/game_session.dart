import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:game_core/game_core.dart';
import 'package:game_host/game_host.dart';
import 'package:protocol/protocol.dart';
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
      config: config,
      candidate: takeover?.candidate,
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

  /// The room this device hosts: the one it opened, or the one it took
  /// over when the host went away. `null` on a plain player's device.
  HostedRoom? get hosted => _hosted;
  HostedRoom? _hosted;
  Timer? _hostingCheck;
  bool _checking = false;

  /// This device took over the room (for a short note on screen).
  bool tookOver = false;

  /// This device hosts [room] (it opened or restored it); the session
  /// closes it when it ends, or hands it over when the player leaves.
  void adopt(HostedRoom room) {
    if (identical(_hosted, room)) return;
    _hosted = room;
    _watchHosting();
  }

  Future<void> _becomeHost(String room) async {
    final me = _link.you;
    if (me == null || _disposed) return;
    final hosted = await HostedRoom.takeOver(
      room,
      newOwner: me,
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
    if (hosted == null || _checking || _disposed) return;
    final mine = hosted.host.epoch;
    final newer = HostLocator.shared.newest(roomCode, hosted.hostKey);
    if (newer == null || newer.epoch <= mine) return;
    _checking = true;
    try {
      _link.redirect(
        dialerFor(
          keys: RoomKeys(
            hostKey: hosted.hostKey,
            roomSecret: hosted.roomSecret,
          ),
          room: roomCode,
          lan: newer.lan,
          locator: HostLocator.shared,
        ),
        epoch: mine + 1,
      );
      final end = DateTime.now().add(const Duration(seconds: 8));
      while (DateTime.now().isBefore(end) && !_disposed) {
        if (_link.status == LinkStatus.connected && _link.epoch > mine) {
          // Proven: the room lives on elsewhere. Close ours without a
          // goodbye (nobody is left on it) and forget its save.
          _hostingCheck?.cancel();
          _hosted = null;
          await hosted.close(quietly: true);
          _changed();
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
      // Not confirmed: stay the host.
      _link.redirect(() async => hosted.host.connectOwner(), epoch: mine);
    } finally {
      _checking = false;
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

  /// Joined without the QR code's secret: waiting for the host's check.
  bool get waitingForHost => _link.waitingForHost;

  /// Joined without the QR code: the player still has to confirm that the
  /// host's screen shows the same symbols.
  bool get needsCodeConfirmation => _link.needsCodeConfirmation;

  /// The host's screen shows the same symbols as ours.
  void confirmCheckCode() => _link.confirmCheckCode();

  /// Symbols to compare with the host, from the encrypted handshake.
  List<int> get checkCode => _link.checkCode;

  /// For the room owner: people waiting to be let in.
  List<PendingJoin> get pending => _link.pending;

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

  /// When the current phase began, on this device's clock (synced with
  /// the host's), or `null` until the clocks are in step.
  int? get phaseStartedAtMs => _link.phaseStartedAtMs;

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
