import 'package:flutter/services.dart';
import 'package:game_host/lan.dart';

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

/// Media types by file ending; anything else is not served.
const _types = {
  'html': 'text/html; charset=utf-8',
  'js': 'text/javascript; charset=utf-8',
  'css': 'text/css; charset=utf-8',
  'json': 'application/json',
  'wasm': 'application/wasm',
  'png': 'image/png',
  'webp': 'image/webp',
  'mp3': 'audio/mpeg',
  'otf': 'font/otf',
  'ttf': 'font/ttf',
  'frag': 'application/octet-stream',
  'bin': 'application/octet-stream',
  'txt': 'text/plain; charset=utf-8',
};

String? _type(String path) {
  final name = path.split('/').last;
  if (name == 'NOTICES') return _types['txt'];
  final dot = name.lastIndexOf('.');
  return dot < 0 ? null : _types[name.substring(dot + 1)];
}

Future<SiteFile?> _file(String path) async {
  final file = path.isEmpty ? 'index.html' : path;
  final type = _type(file);
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
