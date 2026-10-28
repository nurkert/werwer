import 'package:flutter/services.dart';
import 'package:game_host/lan.dart';
import 'package:protocol/protocol.dart' show webAppType;

/// The web app this host serves to browsers on the local network, if this
/// build carries it (see `tool/build_webapp.sh`); `null` otherwise.
Future<Site?> bundledWebApp() async {
  try {
    await rootBundle.load('$_folder/index.html.gz');
    return _file;
  } on Object {
    return null;
  }
}

const _folder = 'assets/webapp';

Future<SiteFile?> _file(String path) async {
  final file = path.isEmpty ? 'index.html' : path;
  final type = webAppType(file);
  if (type == null) return null;
  // The web build itself, flattened and mostly compressed.
  final flat = '$_folder/${file.replaceAll('/', '__')}';
  for (final (name, gzip) in [('$flat.gz', true), (flat, false)]) {
    try {
      final data = await rootBundle.load(name);
      return SiteFile(data.buffer.asUint8List(), type, gzip: gzip);
    } on Object {
      // Not this one.
    }
  }
  // The app's own pictures, sounds and fonts: straight from this bundle,
  // where the web build expects them (under assets/), never the web app's
  // own folder twice.
  const prefix = 'assets/assets/';
  if (file.startsWith(prefix) && !file.startsWith('${prefix}webapp/')) {
    try {
      final data = await rootBundle.load(file.substring('assets/'.length));
      return SiteFile(data.buffer.asUint8List(), type);
    } on Object {
      return null;
    }
  }
  return null;
}
