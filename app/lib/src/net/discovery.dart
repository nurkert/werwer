import 'dart:async';
import 'dart:convert';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/foundation.dart';
import 'package:game_core/game_core.dart' show maxNameLength;
import 'package:protocol/protocol.dart';

/// The mDNS / Bonjour service type of a Whowolf room.
const roomServiceType = '_whowolf._tcp';

/// Announces this device's room on the local network, so that the others
/// see it under "Join a room" without typing anything.
class RoomAnnouncer {
  BonsoirBroadcast? _broadcast;
  // Cancelled in stop().
  // ignore: cancel_subscriptions
  StreamSubscription<BonsoirBroadcastEvent>? _events;
  Completer<void>? _stopped;

  Future<void> start({
    required String hostName,
    required String room,
    required int port,
    required List<int> hostKey,
    int epoch = 0,
    bool candidate = false,
  }) async {
    try {
      final print = keyPrint(hostKey);
      final broadcast = BonsoirBroadcast(
        printLogs: false,
        service: BonsoirService(
          // A successor's entrance is not a room to join: its own name, so
          // it never replaces the room's announcement.
          name: candidate
              ? 'Whowolf $room ${print.substring(0, 6)}'
              : 'Whowolf $room',
          type: roomServiceType,
          port: port,
          attributes: {
            'room': room,
            'host': hostName,
            'key': print,
            'v': '$protocolVersion',
            if (epoch > 0) 'epoch': '$epoch',
            if (candidate) 'cand': '1',
          },
        ),
      );
      await broadcast.initialize();
      // stop() returns before the system has withdrawn the announcement;
      // the stopped event says when it has.
      final stopped = Completer<void>();
      _events = broadcast.eventStream?.listen((event) {
        if (event is BonsoirBroadcastStoppedEvent && !stopped.isCompleted) {
          stopped.complete();
        }
      });
      _stopped = stopped;
      await broadcast.start();
      _broadcast = broadcast;
    } on Object {
      // No mDNS on this device: joining by QR code still works.
    }
  }

  /// Withdraws the announcement and waits (briefly) until the system has,
  /// so that announcing the same room again right after does not show it
  /// twice.
  Future<void> stop() async {
    final broadcast = _broadcast;
    final stopped = _stopped;
    final events = _events;
    _broadcast = null;
    _stopped = null;
    _events = null;
    try {
      if (broadcast != null) {
        await broadcast.stop();
        await stopped?.future.timeout(const Duration(seconds: 2));
      }
    } on Object {
      // Already gone, or the system did not confirm in time.
    }
    await events?.cancel();
  }
}

/// A short, public fingerprint of a host key: lets a player tell its own
/// room from another with the same code. Authenticity still comes from the
/// encrypted handshake, never from this.
String keyPrint(List<int> hostKey) =>
    base64Url.encode(hostKey.take(12).toList()).replaceAll('=', '');

/// A room found on the local network.
class NearbyRoom {
  const NearbyRoom({
    required this.id,
    required this.hostName,
    required this.room,
    required this.lan,
    this.keyPrint,
    this.epoch = 0,
    this.candidate = false,
  });

  final String id;
  final String hostName;
  final String room;
  final LanAddress lan;

  /// Fingerprint of the host key, if the host announced one.
  final String? keyPrint;

  /// How many times the room changed hands (a hint; the welcome is proof).
  final int epoch;

  /// A successor's entrance during a takeover, not a room to join.
  final bool candidate;
}

/// Looks for rooms on the local network while it lives.
class RoomFinder extends ChangeNotifier {
  RoomFinder() {
    _live.add(this);
    unawaited(_start());
  }

  /// Searches running now: a room closed here leaves all of them at once.
  static final Set<RoomFinder> _live = {};

  BonsoirDiscovery? _discovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _events;
  final _rooms = <String, NearbyRoom>{};
  bool _disposed = false;

  /// Whether the search could not start (no mDNS on this device).
  bool unavailable = false;

  /// Rooms this device hosted and closed, by key fingerprint: the system
  /// may keep their announcement cached for a while after it was
  /// withdrawn, but a closed room is gone for good.
  static final Set<String> _closed = {};

  /// Marks a room this device closed, so no search shows it again.
  static void closed(List<int> hostKey) {
    if (!_closed.add(keyPrint(hostKey))) return;
    for (final finder in [..._live]) {
      finder.notifyListeners();
    }
  }

  /// Rooms to join (without successors' entrances and rooms closed here).
  List<NearbyRoom> get rooms => _rooms.values
      .where((r) => !r.candidate && !_closed.contains(r.keyPrint))
      .toList();

  /// Everything announced, entrances included.
  Iterable<NearbyRoom> get all => _rooms.values;

  Future<void> _start() async {
    try {
      final discovery = BonsoirDiscovery(
        printLogs: false,
        type: roomServiceType,
      );
      await discovery.initialize();
      if (_disposed) return;
      _events = discovery.eventStream?.listen((event) {
        switch (event) {
          case BonsoirDiscoveryServiceFoundEvent(:final service):
            unawaited(service.resolve(discovery.serviceResolver));
          case BonsoirDiscoveryServiceResolvedEvent(:final service) ||
              BonsoirDiscoveryServiceUpdatedEvent(:final service):
            _found(service);
          case BonsoirDiscoveryServiceLostEvent(:final service):
            if (_rooms.remove(service.name) != null) notifyListeners();
          default:
            break;
        }
      });
      await discovery.start();
      _discovery = discovery;
    } on Object {
      unavailable = true;
      if (!_disposed) notifyListeners();
    }
  }

  void _found(BonsoirService service) {
    final room = service.attributes['room'] ?? '';
    final version = service.attributes['v'];
    if (!RegExp('^[0-9]{$roomCodeLength}\$').hasMatch(room) ||
        version != '$protocolVersion') {
      return;
    }
    // Only private IPv4 addresses, exactly like a scanned link.
    final lan = service.hostAddresses
        .map((ip) => LanAddress.tryParse('$ip:${service.port}'))
        .whereType<LanAddress>()
        .firstOrNull;
    if (lan == null) return;
    final host = service.attributes['host'] ?? '';
    _rooms[service.name] = NearbyRoom(
      id: service.name,
      hostName: host.length > maxNameLength
          ? host.substring(0, maxNameLength)
          : host,
      room: room,
      lan: lan,
      keyPrint: service.attributes['key'],
      epoch:
          int.tryParse(service.attributes['epoch'] ?? '')?.clamp(0, maxEpoch) ??
          0,
      candidate: service.attributes['cand'] == '1',
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _live.remove(this);
    unawaited(_events?.cancel());
    final discovery = _discovery;
    if (discovery != null) {
      unawaited(discovery.stop().catchError((Object _) {}));
    }
    super.dispose();
  }
}

/// Keeps one room search running for the whole app, so a player whose host
/// moved (new Wi-Fi, new port after a restart) finds it again by room code
/// and key instead of the old address.
class HostLocator {
  HostLocator._();

  static final shared = HostLocator._();

  /// Tests on one machine: every phone is this machine, and a desktop
  /// firewall may block a fresh test build's sockets on the Wi-Fi address,
  /// so found addresses point to the loopback interface instead.
  @visibleForTesting
  static bool loopback = false;

  static LanAddress _here(LanAddress at) =>
      loopback ? LanAddress('127.0.0.1', at.port) : at;

  RoomFinder? _finder;

  /// The current address of [room], whose host has [hostKey] if known.
  /// After a takeover two hosts may announce it for a moment: the one with
  /// the higher epoch (the welcome proves it, a stale host is refused).
  LanAddress? find(String room, List<int>? hostKey) {
    final at = newest(room, hostKey)?.lan;
    return at == null ? null : _here(at);
  }

  /// The announcement of [room] with the highest epoch.
  NearbyRoom? newest(String room, List<int>? hostKey) {
    final finder = _finder ??= RoomFinder();
    final print = hostKey == null ? null : keyPrint(hostKey);
    final matching = finder.rooms.where(
      (r) =>
          r.room == room &&
          (print == null || r.keyPrint == null || r.keyPrint == print),
    );
    return matching.fold<NearbyRoom?>(
      null,
      (best, r) => best == null || r.epoch > best.epoch ? r : best,
    );
  }

  /// Where the successor with [candidateKey] waits during a takeover.
  LanAddress? findCandidate(String room, List<int> candidateKey) {
    final finder = _finder ??= RoomFinder();
    final print = keyPrint(candidateKey);
    return finder.all
        .where((r) => r.candidate && r.room == room && r.keyPrint == print)
        .map((r) => _here(r.lan))
        .firstOrNull;
  }

  /// Starts searching early (e.g. when a game screen opens).
  void warmUp() => _finder ??= RoomFinder();

  /// Fires whenever an announcement appears, changes or goes away (e.g. a
  /// host that came back, or a player who took the room over).
  Listenable get changes => _finder ??= RoomFinder();
}
