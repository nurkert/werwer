import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:protocol/protocol.dart';

/// The official relay server, set at build time
/// (`--dart-define=RELAY_SERVER=wss://…`). Empty until it exists; players can
/// enter their own (self-hosted) server in the settings.
const officialRelayServer = String.fromEnvironment('RELAY_SERVER');

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

  /// The relay server to use: the player's own, else the official one.
  Future<Uri?> relayServer() async {
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
