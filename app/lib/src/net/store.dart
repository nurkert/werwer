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

  /// Whether the short privacy notice was shown on this device.
  Future<bool> privacyNoticeSeen() => _flag(_noticeKey);

  Future<void> setPrivacyNoticeSeen() => _setFlag(_noticeKey, on: true);

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
