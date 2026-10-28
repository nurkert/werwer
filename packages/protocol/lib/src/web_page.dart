/// What every page of the web app gets, whether the host's phone or a relay
/// server delivers it: the same media types and the same headers, so a page
/// can only talk to the origin it came from.
library;

/// Media types of the web app's files by ending; anything else is never
/// served.
const webAppTypes = {
  'html': 'text/html; charset=utf-8',
  'js': 'text/javascript; charset=utf-8',
  'mjs': 'text/javascript; charset=utf-8',
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

/// The media type of the web app's file [path], or `null` if it is never
/// served.
String? webAppType(String path) {
  final name = path.split('/').last;
  if (name == 'NOTICES') return webAppTypes['txt'];
  final dot = name.lastIndexOf('.');
  return dot < 0 ? null : webAppTypes[name.substring(dot + 1)];
}

/// Paths of the web app's files: plain names, no way out.
final _sitePath = RegExp(r'^[A-Za-z0-9_.\-]+(/[A-Za-z0-9_.\-]+)*$');

/// Whether [path] (no leading slash) can name a file of the web app.
bool isWebAppPath(String path) =>
    path.length <= 200 &&
    _sitePath.hasMatch(path) &&
    !path.split('/').any((part) => part.startsWith('.'));

/// The headers of every file of the web app. [socket] is the WebSocket
/// origin the page may reach besides its own (`ws://host:port` on the
/// local network, `wss://host` on a server).
Map<String, String> webAppHeaders(String socket) => {
  'X-Content-Type-Options': 'nosniff',
  'X-Frame-Options': 'DENY',
  'Referrer-Policy': 'no-referrer',
  'Cross-Origin-Opener-Policy': 'same-origin',
  'Content-Security-Policy':
      "default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; "
      "style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; "
      "font-src 'self' data:; worker-src 'self' blob:; "
      "connect-src 'self' $socket; object-src 'none'; "
      "frame-ancestors 'none'; base-uri 'none'; form-action 'none'",
};
