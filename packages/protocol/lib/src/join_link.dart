import 'dart:convert';

import 'package:protocol/src/messages.dart';
import 'package:protocol/src/relay.dart';

/// Default port of a host on the local network.
const defaultLanPort = 47470;

/// The only path a host answers WebSockets on, on the local network.
const hostSocketPath = '/whowolf';

/// The relay server's page for a room: `/v/<protocol>/<build>/join`.
/// A seat's one-time handover code: 32 lowercase hex digits.
final _seatCode = RegExp(r'^[0-9a-f]{32}$');

final _serverPage = RegExp(r'^/v/[0-9]{1,4}/([0-9a-z][0-9a-z.-]{0,31})/join$');

/// Whether [build] can name a web app build in a server page's path.
bool isWebAppBuild(String build) =>
    RegExp(r'^[0-9a-z][0-9a-z.-]{0,31}$').hasMatch(build);

/// Everything needed to join a room, as carried by the QR code:
/// `https://whowolf.de/join?room=1234&lan=192.168.1.5:47470&relay=abcd2345&srv=wss://relay.example.org`.
///
/// The host's public key and the room secret for the encrypted handshake are
/// in the fragment (`#k=…&s=…`), which browsers never send to a server.
///
/// A host that serves the web app links to itself instead
/// (`http://192.168.1.5:47470/join?room=1234#k=…&s=…`): a phone without
/// the app opens it in the browser and joins, even without internet. The
/// address must be a private one, and such a link always carries the key.
///
/// A relay server that serves the web app links to its own page for the
/// host's build (`https://play.whowolf.de/v/7/0.2.0/join?room=1234&relay=…#k=…&s=…`):
/// a phone without the app joins in the browser over the internet. The
/// server is the page's own origin, and such a link always carries the key.
class JoinLink {
  /// Creates a link; at least one of [lan] or [relayRoom] must be set.
  const JoinLink({
    required this.room,
    this.lan,
    this.relayRoom,
    this.server,
    this.hostKey,
    this.roomSecret,
    this.seat,
  });

  /// Parses a scanned link strictly; returns `null` for anything else.
  static JoinLink? tryParse(String raw) {
    if (raw.length > 512) return null;
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.userInfo.isNotEmpty) return null;
    final onServer = uri.scheme == 'https' && _serverPage.hasMatch(uri.path);
    if (uri.path != '/join' && !onServer) return null;
    // The host itself, on the local network: its address is the link's.
    final local = uri.scheme == 'http' && uri.path == '/join'
        ? LanAddress.tryParse('${uri.host}:${uri.hasPort ? uri.port : 80}')
        : null;
    final official =
        uri.scheme == 'https' &&
        uri.path == '/join' &&
        uri.host == linkHost &&
        !uri.hasPort;
    if (local == null && !official && !onServer) return null;
    final q = uri.queryParameters;
    final allowed = {
      'room',
      'relay',
      if (!onServer) 'srv',
      if (official || onServer) 'lan',
    };
    if (q.keys.any((k) => !allowed.contains(k))) return null;
    final room = q['room'] ?? '';
    if (!RegExp('^[0-9]{$roomCodeLength}\$').hasMatch(room)) return null;
    final lan =
        local ?? (q['lan'] == null ? null : LanAddress.tryParse(q['lan']!));
    if (q['lan'] != null && lan == null) return null;
    final relay = q['relay'];
    if (relay != null && !isRelayRoomId(relay)) return null;
    // A server's own page: the server is the page's origin.
    final server = onServer
        ? parseRelayServer(
            Uri(
              scheme: 'wss',
              host: uri.host,
              port: uri.hasPort ? uri.port : null,
            ).toString(),
          )
        : q['srv'] == null
        ? null
        : parseRelayServer(q['srv']!);
    if ((onServer || q['srv'] != null) && server == null) return null;
    if (onServer && relay == null) return null;
    if (lan == null && relay == null) return null;
    if ((relay == null) != (server == null)) return null;
    List<int>? key;
    List<int>? secret;
    String? seat;
    if (uri.fragment.isNotEmpty) {
      final f = Uri.splitQueryString(uri.fragment);
      if (f.keys.any((k) => k != 'k' && k != 's' && k != 'h')) return null;
      key = _key32(f['k']);
      secret = _key32(f['s']);
      if (key == null || secret == null) return null;
      seat = f['h'];
      if (seat != null && !_seatCode.hasMatch(seat)) return null;
    }
    // A server named by a link is only trusted with the host's key and
    // secret from the same link (end-to-end encrypted and authenticated);
    // a bare server could be anyone's.
    if (server != null && key == null) return null;
    // Whoever serves a page could serve any page: from the host's own
    // address or a server's page only with the key, so the handshake
    // proves it is the host.
    if ((local != null || onServer) && key == null) return null;
    return JoinLink(
      room: room,
      lan: lan,
      relayRoom: relay,
      server: server,
      hostKey: key,
      roomSecret: secret,
      seat: seat,
    );
  }

  /// The page a relay server's code page sent this browser to
  /// (`https://<server>/v/<protocol>/<build>/join?room=1234&relay=…`, see
  /// [DoorAsked]): the room and its relay room, but no key, because the
  /// player only typed a short code. Such a join runs the handshake without
  /// the QR code: both screens show the check image, and the game leader
  /// lets the player in or not. Only the web app reads its own address
  /// this way; a scanned code is always read with [tryParse], which never
  /// accepts a server without the key. `null` for anything else.
  static JoinLink? tryParseCodePage(String raw) {
    if (raw.length > 512) return null;
    final uri = Uri.tryParse(raw.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment ||
        !_serverPage.hasMatch(uri.path)) {
      return null;
    }
    final q = uri.queryParameters;
    if (q.length != 2) return null;
    final room = q['room'] ?? '';
    final relay = q['relay'] ?? '';
    if (!RegExp('^[0-9]{$roomCodeLength}\$').hasMatch(room) ||
        !isRelayRoomId(relay)) {
      return null;
    }
    final server = parseRelayServer(
      Uri(
        scheme: 'wss',
        host: uri.host,
        port: uri.hasPort ? uri.port : null,
      ).toString(),
    );
    if (server == null) return null;
    return JoinLink(room: room, relayRoom: relay, server: server);
  }

  /// Host name of join links.
  static const linkHost = 'whowolf.de';

  /// The 4-digit room code.
  final String room;

  /// The host on the local network.
  final LanAddress? lan;

  /// The room on the relay server.
  final String? relayRoom;

  /// The relay server (`ws://` or `wss://` origin).
  final Uri? server;

  /// The host's public key for this room (32 bytes).
  final List<int>? hostKey;

  /// The room secret (32 bytes).
  final List<int>? roomSecret;

  /// A one-time code handing an existing seat to the device that scans
  /// this link (only with the key, never on its own).
  final String? seat;

  /// The link to the host itself (see the class comment), for phones that
  /// join in the browser; `null` without a local address or the key.
  String? encodeLocal() {
    final lan = this.lan;
    if (lan == null || hostKey == null || roomSecret == null) return null;
    return Uri(
      scheme: 'http',
      host: lan.ip,
      port: lan.port,
      path: '/join',
      queryParameters: {
        'room': room,
        'relay': ?relayRoom,
        'srv': ?server?.toString(),
      },
      fragment:
          'k=${base64Url.encode(hostKey!)}&s=${base64Url.encode(roomSecret!)}',
    ).toString();
  }

  /// The link to this room's page on its relay server (see the class
  /// comment), for phones that join in the browser over the internet;
  /// `null` without a `wss://` server, a relay room or the key, or for an
  /// invalid [build].
  String? encodeOnServer(String build) {
    final server = this.server;
    if (server == null ||
        server.scheme != 'wss' ||
        relayRoom == null ||
        hostKey == null ||
        roomSecret == null ||
        !isWebAppBuild(build)) {
      return null;
    }
    return Uri(
      scheme: 'https',
      host: server.host,
      port: server.hasPort ? server.port : null,
      path: '/v/$protocolVersion/$build/join',
      queryParameters: {
        'room': room,
        'lan': ?lan?.toString(),
        'relay': relayRoom,
      },
      fragment:
          'k=${base64Url.encode(hostKey!)}&s=${base64Url.encode(roomSecret!)}',
    ).toString();
  }

  /// This link handing [code]'s seat to the device that scans it.
  JoinLink withSeat(String code) => JoinLink(
    room: room,
    lan: lan,
    relayRoom: relayRoom,
    server: server,
    hostKey: hostKey,
    roomSecret: roomSecret,
    seat: code,
  );

  /// The link as text for the QR code.
  String encode() => Uri(
    scheme: 'https',
    host: linkHost,
    path: '/join',
    queryParameters: {
      'room': room,
      'lan': ?lan?.toString(),
      'relay': ?relayRoom,
      'srv': ?server?.toString(),
    },
    fragment: hostKey == null || roomSecret == null
        ? null
        : 'k=${base64Url.encode(hostKey!)}&s=${base64Url.encode(roomSecret!)}'
              '${seat == null ? '' : '&h=$seat'}',
  ).toString();
}

/// Where a browser page that came with [link] connects: back to the origin
/// that served it. A page from the host's phone (`http://`, the local
/// network) reaches the host directly; a page from a relay server
/// (`https://`) reaches the room on that same server, because a secure page
/// may not open `ws://` into the local network. A server named in the link
/// is never used here: the page talks only to its own origin. `null` if
/// there is no way.
Uri? pageSocket(Uri page, JoinLink link) {
  final port = page.hasPort ? page.port : null;
  return switch (page.scheme) {
    'http' => Uri(
      scheme: 'ws',
      host: page.host,
      port: port,
      path: hostSocketPath,
    ),
    'https' when link.relayRoom != null => Uri(
      scheme: 'wss',
      host: page.host,
      port: port,
      path: '/join/${link.relayRoom}',
    ),
    _ => null,
  };
}

List<int>? _key32(String? value) {
  if (value == null || value.length > 64) return null;
  try {
    final bytes = base64Url.decode(value);
    return bytes.length == 32 ? bytes : null;
  } on FormatException {
    return null;
  }
}

/// A host address on the local network: a private IPv4 address and a port.
class LanAddress {
  /// Creates an address.
  const LanAddress(this.ip, this.port);

  /// Parses `ip` or `ip:port`; only private IPv4 addresses are accepted.
  static LanAddress? tryParse(String input) {
    final parts = input.trim().split(':');
    if (parts.isEmpty || parts.length > 2) return null;
    final port = parts.length == 2 ? int.tryParse(parts[1]) : defaultLanPort;
    final octets = parts.first.split('.').map(int.tryParse).toList();
    final valid =
        octets.length == 4 &&
        octets.every((o) => o != null && o >= 0 && o < 256);
    if (!valid || port == null || port <= 0 || port > 65535) return null;
    final a = octets[0]!;
    final b = octets[1]!;
    final private =
        a == 10 || (a == 172 && b >= 16 && b <= 31) || (a == 192 && b == 168);
    return private ? LanAddress(octets.join('.'), port) : null;
  }

  /// The IPv4 address.
  final String ip;

  /// The port.
  final int port;

  @override
  String toString() => '$ip:$port';
}

/// Parses a relay server origin such as `wss://relay.example.org` or
/// `ws://192.168.1.5:8080`; returns `null` for anything with a path, query,
/// user info or another scheme.
Uri? parseRelayServer(String input) {
  final uri = Uri.tryParse(input.trim());
  if (uri == null ||
      !(uri.scheme == 'ws' || uri.scheme == 'wss') ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      (uri.path.isNotEmpty && uri.path != '/') ||
      uri.hasQuery ||
      uri.hasFragment ||
      input.length > 200) {
    return null;
  }
  return Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
  );
}
