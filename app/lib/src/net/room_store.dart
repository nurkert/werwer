import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// A saved room: the host's snapshot and the room keys.
class SavedRoom {
  const SavedRoom(this.snapshot, this.keys);

  final String snapshot;
  final Map<String, Object?> keys;
}

/// Keeps the snapshot of the room this device hosts, so the game survives a
/// crash or a restart of the host app. The file holds every role and session
/// token: it stays in the app's private support folder and is deleted when
/// the room closes.
class RoomStore {
  const RoomStore();

  /// Snapshots older than this are not offered any more.
  static const maxAge = Duration(hours: 3);

  /// Phases worth bringing back: a game under way. An empty lobby is
  /// opened again in a tap, an ended game is over.
  static const _running = {'roleReveal', 'night', 'day', 'hunterShot', 'vote'};

  static bool _underway(String snapshot) {
    try {
      final json = jsonDecode(snapshot) as Map<String, Object?>;
      final state = json['state']! as Map<String, Object?>;
      return _running.contains(state['phase']);
    } on Object {
      return false;
    }
  }

  Future<File> _file() async =>
      File('${(await getApplicationSupportDirectory()).path}/room.json');

  Future<void> save(SavedRoom room) async {
    try {
      final file = await _file();
      final temp = File('${file.path}.tmp');
      // Write, then rename: a crash mid-write never leaves half a file.
      await temp.writeAsString(
        jsonEncode({'snapshot': room.snapshot, 'keys': room.keys}),
        flush: true,
      );
      await temp.rename(file.path);
    } on Object {
      // Without storage the room just cannot be restored.
    }
  }

  Future<SavedRoom?> load() async {
    try {
      final file = await _file();
      if (!file.existsSync()) return null;
      if (DateTime.now().difference(file.lastModifiedSync()) > maxAge) {
        await file.delete();
        return null;
      }
      final json =
          jsonDecode(await file.readAsString()) as Map<String, Object?>;
      final snapshot = json['snapshot']! as String;
      if (!_underway(snapshot)) return null;
      return SavedRoom(snapshot, json['keys']! as Map<String, Object?>);
    } on Object {
      return null;
    }
  }

  Future<void> clear() async {
    try {
      final file = await _file();
      if (file.existsSync()) await file.delete();
    } on Object {
      // Nothing to clear.
    }
  }
}
