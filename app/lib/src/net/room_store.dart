import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Keeps the snapshot of the room this device hosts, so the game survives a
/// crash or a restart of the host app. The file holds every role and session
/// token: it stays in the app's private support folder and is deleted when
/// the room closes.
class RoomStore {
  const RoomStore();

  /// Snapshots older than this are not offered any more.
  static const maxAge = Duration(hours: 12);

  Future<File> _file() async =>
      File('${(await getApplicationSupportDirectory()).path}/room.json');

  Future<void> save(String snapshot) async {
    try {
      final file = await _file();
      final temp = File('${file.path}.tmp');
      // Write, then rename: a crash mid-write never leaves half a file.
      await temp.writeAsString(snapshot, flush: true);
      await temp.rename(file.path);
    } on Object {
      // Without storage the room just cannot be restored.
    }
  }

  Future<String?> load() async {
    try {
      final file = await _file();
      if (!file.existsSync()) return null;
      if (DateTime.now().difference(file.lastModifiedSync()) > maxAge) {
        await file.delete();
        return null;
      }
      return file.readAsString();
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
