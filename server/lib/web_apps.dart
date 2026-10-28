/// The web app for players without the app, served by the relay (opt-in,
/// `WEB_APP_DIR`): every build the image carries, under
/// `/v/<protocol>/<build>/`, so each host's QR code points at exactly its
/// own build.
///
/// Everything is read once at start into memory, already compressed: a
/// request is a map lookup, never a file access or compression. Only files
/// found at start exist, with a media type from a fixed list; nothing from
/// a request reaches a path on disk.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:protocol/protocol.dart';

/// One file of a build, ready to send.
class _File {
  _File(this.bytes, this.type, {required this.gzip})
    : etag = '"${sha256.convert(bytes).toString().substring(0, 32)}"';

  final List<int> bytes;
  final String type;
  final bool gzip;
  final String etag;
}

final _page = RegExp(r'^/v/([0-9]{1,4})/([0-9a-z][0-9a-z.-]{0,31})/(.*)$');

/// The builds of the web app this relay serves.
class WebApps {
  WebApps._(this._files, this.builds, this.bytes);

  /// No web app: the relay only forwards (the default).
  WebApps.none() : this._(const {}, const [], 0);

  /// Reads every build under [root] (`<root>/<protocol>/<build>/…`). Files
  /// ending in `.gz` are kept compressed; a build without `index.html` is
  /// skipped. Stops at [maxBytes] in total.
  static Future<WebApps> load(
    Directory root, {
    int maxBytes = 512 << 20,
    int maxFileBytes = 32 << 20,
  }) async {
    final files = <String, _File>{};
    final builds = <String>[];
    var total = 0;
    final versions = await root.list().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final version in versions.whereType<Directory>()) {
      final protocol = version.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
      if (!RegExp(r'^[0-9]{1,4}$').hasMatch(protocol)) continue;
      for (final build
          in (await version.list().toList()).whereType<Directory>()) {
        final name = build.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
        if (!isWebAppBuild(name)) continue;
        final prefix = '$protocol/$name/';
        final found = <String, _File>{};
        await for (final entry in build.list(recursive: true)) {
          if (entry is! File) continue;
          var path = entry.path
              .substring(build.path.length)
              .replaceAll(r'\', '/');
          if (path.startsWith('/')) path = path.substring(1);
          final gzip = path.endsWith('.gz');
          if (gzip) path = path.substring(0, path.length - 3);
          final type = webAppType(path);
          if (type == null || !isWebAppPath(path)) continue;
          final size = await entry.length();
          if (size > maxFileBytes || total + size > maxBytes) {
            throw StateError('web apps exceed the limit at $prefix$path');
          }
          total += size;
          found[path] = _File(await entry.readAsBytes(), type, gzip: gzip);
        }
        if (!found.containsKey('index.html')) continue;
        found.forEach((path, file) => files['$prefix$path'] = file);
        builds.add('$protocol/$name');
      }
    }
    return WebApps._(files, builds, total);
  }

  final Map<String, _File> _files;

  /// The builds served, as `<protocol>/<build>`.
  final List<String> builds;

  /// Bytes held in memory.
  final int bytes;

  /// Whether [path] is the web app's (`/v/…`); [serve] answers those.
  static bool owns(String path) => path.startsWith('/v/');

  /// Answers one request for the web app. [socket] is the WebSocket origin
  /// the page may reach (`wss://<this server>`).
  Future<void> serve(HttpRequest request, String socket) async {
    final response = request.response;
    try {
      final match = _page.firstMatch(request.uri.path);
      var rest = match?.group(3) ?? '';
      if (rest.isEmpty || rest == 'join') rest = 'index.html';
      final method = request.method;
      final file = match == null || !isWebAppPath(rest)
          ? null
          : _files['${match.group(1)}/${match.group(2)}/$rest'];
      if (method != 'GET' && method != 'HEAD') {
        response.statusCode = HttpStatus.methodNotAllowed;
      } else if (request.headers.value('service-worker') != null) {
        // No page may install a service worker that outlives the game.
        response.statusCode = HttpStatus.forbidden;
      } else if (file == null) {
        _missing(response);
      } else {
        _send(request, file, rest == 'index.html', socket);
        return;
      }
      await response.close();
    } on Object {
      // The browser went away mid-file.
      try {
        await response.close();
      } on Object {
        // Already closed.
      }
    }
  }

  void _send(HttpRequest request, _File file, bool page, String socket) {
    final response = request.response;
    final headers = response.headers
      ..contentType = ContentType.parse(file.type)
      ..set(HttpHeaders.etagHeader, file.etag)
      // The build is in the path: a file never changes, except the page,
      // which the browser checks each time.
      ..set(
        HttpHeaders.cacheControlHeader,
        page ? 'no-cache' : 'public, max-age=31536000, immutable',
      );
    webAppHeaders(socket).forEach(headers.set);
    if (request.headers.value(HttpHeaders.ifNoneMatchHeader) == file.etag) {
      response.statusCode = HttpStatus.notModified;
      unawaited(response.close());
      return;
    }
    var bytes = file.bytes;
    if (file.gzip) {
      final accepts =
          request.headers.value(HttpHeaders.acceptEncodingHeader) ?? '';
      if (accepts.contains('gzip')) {
        headers.set(HttpHeaders.contentEncodingHeader, 'gzip');
      } else {
        bytes = gzip.decode(bytes);
      }
      headers.set(HttpHeaders.varyHeader, 'Accept-Encoding');
    }
    response.contentLength = bytes.length;
    if (request.method == 'GET') response.add(bytes);
    unawaited(response.close());
  }

  /// A plain page instead of a blank screen: this server does not have the
  /// build the QR code asks for.
  static void _missing(HttpResponse response) {
    response
      ..statusCode = HttpStatus.notFound
      ..headers.contentType = ContentType.html
      ..headers.set(HttpHeaders.cacheControlHeader, 'no-store')
      ..headers.set('X-Content-Type-Options', 'nosniff')
      ..headers.set('Referrer-Policy', 'no-referrer')
      ..headers.set(
        'Content-Security-Policy',
        "default-src 'none'; style-src 'unsafe-inline'; "
            "frame-ancestors 'none'; base-uri 'none'; form-action 'none'",
      )
      ..add(utf8.encode(_missingPage));
  }
}

const _missingPage = '''
<!DOCTYPE html>
<html lang="de"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Whowolf</title>
<style>body{font:17px/1.5 system-ui,sans-serif;background:#141A33;color:#F4EEDC;
margin:0;padding:12vh 24px;text-align:center}p{max-width:30em;margin:1em auto}
a{color:#F2B544}</style></head><body>
<p><b>Diese Runde geht hier nicht im Browser.</b><br>
Spielt mit der Whowolf-App, oder fragt am Tisch nach einem neuen Code.</p>
<p lang="en"><b>This game cannot be joined in the browser here.</b><br>
Play with the Whowolf app, or ask the table for a new code.</p>
<p><a href="https://whowolf.de">whowolf.de</a></p>
</body></html>
''';
