import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:protocol/protocol.dart';

/// The official relay server: players on mobile data join a host through
/// it. It only forwards end-to-end encrypted messages. A fork sets its own
/// at build time (`--dart-define=RELAY_SERVER=wss://…`, empty for none);
/// players can enter a self-hosted one in the settings.
const officialRelayServer = String.fromEnvironment(
  'RELAY_SERVER',
  defaultValue: 'wss://play.whowolf.de',
);

/// When a host opens its room on the online server too. Players on the
/// same Wi-Fi never need it, so by default it happens only when the host
/// shows the QR code (or has no Wi-Fi): the server learns nothing of games
/// that stay at home.
enum RelayMode {
  /// When the host shows the QR code, or right away without Wi-Fi.
  onDemand,

  /// Right away, so the QR code works for everyone from the start.
  always,

  /// Never: Wi-Fi only.
  never,
}

/// How to get back into a game after the app was closed. Holds the session
/// token, so it lives in the Keychain / Keystore only and is never logged.
class ResumeInfo {
  const ResumeInfo({
    required this.name,
    required this.room,
    required this.token,
    this.lan,
    this.relayRoom,
    this.server,
    this.hostKey,
    this.roomSecret,
    this.savedAt,
  });

  /// Older than this, the game is surely over: nothing to come back to.
  static const maxAge = Duration(hours: 12);

  static ResumeInfo? fromJson(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, Object?>;
      final lan = json['lan'] as String?;
      final server = json['server'] as String?;
      final key = json['hostKey'] as String?;
      final secret = json['roomSecret'] as String?;
      final savedAt = json['savedAt'] as int?;
      return ResumeInfo(
        name: json['name']! as String,
        room: json['room']! as String,
        token: json['token']! as String,
        lan: lan == null ? null : LanAddress.tryParse(lan),
        relayRoom: json['relayRoom'] as String?,
        server: server == null ? null : parseRelayServer(server),
        hostKey: key == null ? null : base64Url.decode(key),
        roomSecret: secret == null ? null : base64Url.decode(secret),
        savedAt: savedAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(savedAt),
      );
    } on Object {
      return null;
    }
  }

  final String name;
  final String room;
  final String token;
  final LanAddress? lan;
  final String? relayRoom;
  final Uri? server;
  final List<int>? hostKey;
  final List<int>? roomSecret;

  /// When the host last welcomed this player.
  final DateTime? savedAt;

  /// Recent enough to rejoin by itself when the app starts.
  bool get isFresh {
    final at = savedAt;
    return at != null && DateTime.now().difference(at) < maxAge;
  }

  String toJson() => jsonEncode({
    'name': name,
    'room': room,
    'token': token,
    'lan': ?lan?.toString(),
    'relayRoom': ?relayRoom,
    'server': ?server?.toString(),
    'hostKey': ?(hostKey == null ? null : base64Url.encode(hostKey!)),
    'roomSecret': ?(roomSecret == null ? null : base64Url.encode(roomSecret!)),
    'savedAt': ?savedAt?.millisecondsSinceEpoch,
  });
}

/// Small persistent settings and the resume info. Every call tolerates a
/// missing or locked keychain: the app then simply forgets.
class Store {
  const Store([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  static const _resumeKey = 'resume';
  static const _serverKey = 'relayServer';
  static const _relayOffKey = 'relayOff';
  static const _noticeKey = 'privacyNoticeSeen';

  Future<bool> _flag(String key) async {
    try {
      return await _storage.read(key: key) == '1';
    } on Object {
      return false;
    }
  }

  Future<void> _setFlag(String key, {required bool on}) async {
    try {
      if (on) {
        await _storage.write(key: key, value: '1');
      } else {
        await _storage.delete(key: key);
      }
    } on Object {
      // Not saved; asked again next time.
    }
  }

  /// The player switched the online server off: Wi-Fi only.
  Future<bool> relayOff() => _flag(_relayOffKey);

  Future<void> setRelayOff({required bool off}) =>
      _setFlag(_relayOffKey, on: off);

  static const _relayModeKey = 'relayMode';
  static const _webAppOffKey = 'webAppOff';

  /// When this device, as host, opens its room on the online server too.
  Future<RelayMode> relayMode() async {
    if (await relayOff()) return RelayMode.never;
    try {
      final raw = await _storage.read(key: _relayModeKey);
      return raw == RelayMode.always.name
          ? RelayMode.always
          : RelayMode.onDemand;
    } on Object {
      return RelayMode.onDemand;
    }
  }

  Future<void> setRelayMode(RelayMode mode) async {
    await setRelayOff(off: mode == RelayMode.never);
    try {
      await _storage.write(key: _relayModeKey, value: mode.name);
    } on Object {
      // Not saved; the default stays.
    }
  }

  /// Whether this device, as host, gives browsers on the same Wi-Fi the
  /// web app (players without the app).
  Future<bool> serveWebApp() async => !await _flag(_webAppOffKey);

  Future<void> setServeWebApp({required bool on}) =>
      _setFlag(_webAppOffKey, on: !on);

  /// Whether the short privacy notice was shown on this device.
  Future<bool> privacyNoticeSeen() => _flag(_noticeKey);

  Future<void> setPrivacyNoticeSeen() => _setFlag(_noticeKey, on: true);

  static const _nameKey = 'playerName';
  static const _lastRoomKey = 'lastRoom';

  /// The name last typed on the start screen, kept for next time.
  Future<String?> name() async {
    try {
      return await _storage.read(key: _nameKey);
    } on Object {
      return null;
    }
  }

  Future<void> setName(String name) async {
    try {
      await _storage.write(key: _nameKey, value: name);
    } on Object {
      // Typed again next time.
    }
  }

  /// The room code of the room last joined, to offer it first nearby.
  Future<String?> lastRoom() async {
    try {
      return await _storage.read(key: _lastRoomKey);
    } on Object {
      return null;
    }
  }

  Future<void> setLastRoom(String room) async {
    try {
      await _storage.write(key: _lastRoomKey, value: room);
    } on Object {
      // Just not offered first.
    }
  }

  static const _updateOffKey = 'updateCheckOff';
  static const _updateSeenKey = 'updateSeen';

  /// Whether the app asks GitHub for a new version when it starts (on
  /// unless the player switched it off).
  Future<bool> updateCheck() async => !await _flag(_updateOffKey);

  Future<void> setUpdateCheck({required bool on}) =>
      _setFlag(_updateOffKey, on: !on);

  /// The newest version the player was told about already.
  Future<String?> updateSeen() async {
    try {
      return await _storage.read(key: _updateSeenKey);
    } on Object {
      return null;
    }
  }

  Future<void> setUpdateSeen(String version) async {
    try {
      await _storage.write(key: _updateSeenKey, value: version);
    } on Object {
      // Told again next time.
    }
  }

  static const _closedRoomsKey = 'closedRooms';

  /// Rooms this device closed, by key fingerprint, with the time until
  /// which to hide them; expired ones are left out.
  Future<Map<String, DateTime>> closedRooms() async {
    try {
      final raw = await _storage.read(key: _closedRoomsKey);
      if (raw == null) return {};
      final now = DateTime.now();
      return {
        for (final MapEntry(:key, :value)
            in (jsonDecode(raw) as Map<String, Object?>).entries)
          if (value is int &&
              DateTime.fromMillisecondsSinceEpoch(value).isAfter(now))
            key: DateTime.fromMillisecondsSinceEpoch(value),
      };
    } on Object {
      return {};
    }
  }

  /// Keeps at most the 16 latest entries.
  Future<void> setClosedRooms(Map<String, DateTime> rooms) async {
    final latest = rooms.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    try {
      await _storage.write(
        key: _closedRoomsKey,
        value: jsonEncode({
          for (final MapEntry(:key, :value) in latest.take(16))
            key: value.millisecondsSinceEpoch,
        }),
      );
    } on Object {
      // Hidden only until the app restarts.
    }
  }

  static const _languageKey = 'language';

  /// The language the player picked in the app (`de`, `en`), or `null`
  /// to follow the system (which on iOS, macOS and Android 13+ can also be
  /// set per app in the system settings).
  Future<String?> language() async {
    try {
      return await _storage.read(key: _languageKey);
    } on Object {
      return null;
    }
  }

  Future<void> setLanguage(String? code) async {
    try {
      if (code == null) {
        await _storage.delete(key: _languageKey);
      } else {
        await _storage.write(key: _languageKey, value: code);
      }
    } on Object {
      // Not saved; the system language next time.
    }
  }

  /// The way back into a recent game; an older record is deleted (the
  /// game is surely over, and the token should not linger).
  Future<ResumeInfo?> loadResume() async {
    try {
      final raw = await _storage.read(key: _resumeKey);
      final info = raw == null ? null : ResumeInfo.fromJson(raw);
      if (raw != null && (info == null || !info.isFresh)) {
        await clearResume();
        return null;
      }
      return info;
    } on Object {
      return null;
    }
  }

  Future<void> saveResume(ResumeInfo info) async {
    try {
      await _storage.write(key: _resumeKey, value: info.toJson());
    } on Object {
      // Without a keychain there is no resume after a restart.
    }
  }

  Future<void> clearResume() async {
    try {
      await _storage.delete(key: _resumeKey);
    } on Object {
      // Nothing stored.
    }
  }

  /// The relay server to use: the player's own, else the official one;
  /// none if the player switched it off.
  Future<Uri?> relayServer() async {
    if (await relayOff()) return null;
    String? raw;
    try {
      raw = await _storage.read(key: _serverKey);
    } on Object {
      raw = null;
    }
    return parseRelayServer(raw ?? officialRelayServer);
  }

  /// The player's own server as entered, or `null`.
  Future<String?> customServer() async {
    try {
      return await _storage.read(key: _serverKey);
    } on Object {
      return null;
    }
  }

  Future<void> setCustomServer(String? server) async {
    try {
      if (server == null || server.trim().isEmpty) {
        await _storage.delete(key: _serverKey);
      } else {
        await _storage.write(key: _serverKey, value: server.trim());
      }
    } on Object {
      // Not saved; the field shows the old value next time.
    }
  }
}
