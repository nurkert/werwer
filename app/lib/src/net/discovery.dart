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

  Future<void> start({
    required String hostName,
    required String room,
    required int port,
    required List<int> hostKey,
  }) async {
    try {
      final broadcast = BonsoirBroadcast(
        printLogs: false,
        service: BonsoirService(
          name: 'Whowolf $room',
          type: roomServiceType,
          port: port,
          attributes: {
            'room': room,
            'host': hostName,
            'key': keyPrint(hostKey),
            'v': '$protocolVersion',
          },
        ),
      );
      await broadcast.initialize();
      await broadcast.start();
      _broadcast = broadcast;
    } on Object {
      // No mDNS on this device: joining by QR code still works.
    }
  }

  Future<void> stop() async {
    try {
      await _broadcast?.stop();
    } on Object {
      // Already gone.
    }
    _broadcast = null;
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
  });

  final String id;
  final String hostName;
  final String room;
  final LanAddress lan;

  /// Fingerprint of the host key, if the host announced one.
  final String? keyPrint;
}

/// Looks for rooms on the local network while it lives.
class RoomFinder extends ChangeNotifier {
  RoomFinder() {
    unawaited(_start());
  }

  BonsoirDiscovery? _discovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _events;
  final _rooms = <String, NearbyRoom>{};
  bool _disposed = false;

  /// Whether the search could not start (no mDNS on this device).
  bool unavailable = false;

  List<NearbyRoom> get rooms => _rooms.values.toList();

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
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
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

  RoomFinder? _finder;

  /// The current address of [room], whose host has [hostKey] if known.
  LanAddress? find(String room, List<int>? hostKey) {
    final finder = _finder ??= RoomFinder();
    final print = hostKey == null ? null : keyPrint(hostKey);
    return finder.rooms
        .where(
          (r) =>
              r.room == room &&
              (print == null || r.keyPrint == null || r.keyPrint == print),
        )
        .map((r) => r.lan)
        .firstOrNull;
  }

  /// Starts searching early (e.g. when a game screen opens).
  void warmUp() => _finder ??= RoomFinder();
}
