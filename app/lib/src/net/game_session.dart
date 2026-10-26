import 'package:flutter/foundation.dart';
import 'package:game_core/game_core.dart';
import 'package:game_host/game_host.dart';
import 'package:protocol/protocol.dart';

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
  }) {
    _link = PlayerLink(
      name: name,
      roomCode: roomCode,
      dial: dial,
      token: token,
      config: config,
      onChange: _changed,
      onWelcome: onWelcome,
      onRoomKeys: onRoomKeys,
      onEnded: onEnded,
    );
  }

  late final PlayerLink _link;
  final String roomCode;
  bool _disposed = false;

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

  /// Leaves for good: tells the host (in the lobby) and closes.
  void leave() => _link.leave();

  @override
  void dispose() {
    _disposed = true;
    _link.close();
    super.dispose();
  }
}
