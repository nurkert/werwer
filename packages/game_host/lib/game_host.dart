/// Whowolf host logic: one room, its sessions and timers, behind a transport
/// interface. Pure Dart (no `dart:io`), so it runs in the app, in tests and,
/// later, on a server. The LAN WebSocket transport lives in `lan.dart`.
library;

export 'src/custody.dart';
export 'src/host.dart';
export 'src/player_link.dart';
export 'src/succession.dart';
export 'src/transport.dart';
