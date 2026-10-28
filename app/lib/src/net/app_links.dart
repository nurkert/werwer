import 'package:flutter/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:whowolf/src/net/store.dart';

/// A room link that opened this app (Universal Link on iOS, App Link on
/// Android): the QR code of a room on the official server, scanned with
/// the phone's camera. The start screen takes it and asks before joining,
/// like after a scan.
final incomingLink = ValueNotifier<JoinLink?>(null);

/// The room in [route], as the platform hands it over: the link's path
/// with query and fragment, or the whole link. Only the official server's
/// room pages count (the only ones this app is linked with), and only with
/// the room's key; anything else is ignored.
JoinLink? joinLinkFromRoute(String? route, {String? server}) {
  final host = parseRelayServer(server ?? officialRelayServer)?.host;
  if (route == null || host == null || route.length > 600) return null;
  final raw = route.startsWith('/') ? 'https://$host$route' : route;
  final uri = Uri.tryParse(raw);
  if (uri == null || uri.host != host) return null;
  final link = JoinLink.tryParse(raw);
  return link?.hostKey == null ? null : link;
}
