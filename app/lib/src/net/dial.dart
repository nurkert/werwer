import 'package:game_host/lan.dart';
import 'package:game_host/relay.dart';
import 'package:protocol/protocol.dart';
import 'package:whowolf/src/net/game_session.dart';

/// Dials a host: directly on the local network if possible, else through the
/// relay server. The session does not care which one worked.
Dial dialerFor({LanAddress? lan, String? relayRoom, Uri? server}) {
  final relay = relayRoom != null && server != null;
  return () async {
    if (lan != null) {
      try {
        return await dialHost(
          lan.ip,
          lan.port,
          timeout: Duration(seconds: relay ? 3 : 6),
        );
      } on Object {
        if (!relay) rethrow;
      }
    }
    if (!relay) throw StateError('no way to reach the host');
    return dialRelay(server, relayRoom);
  };
}
