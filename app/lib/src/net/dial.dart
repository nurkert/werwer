import 'package:game_host/game_host.dart';
import 'package:game_host/lan.dart';
import 'package:game_host/relay.dart';
import 'package:protocol/protocol.dart';
import 'package:secure_channel/secure_channel.dart';
import 'package:whowolf/src/net/game_session.dart';

/// Dials a host: directly on the local network if possible, else through the
/// relay server. The session does not care which one worked.
///
/// Every connection is end-to-end encrypted. With [hostKey] and [roomSecret]
/// (from the QR code) the host is authenticated; without them the host lets
/// the player in after comparing the check code.
Dial dialerFor({
  LanAddress? lan,
  String? relayRoom,
  Uri? server,
  List<int>? hostKey,
  List<int>? roomSecret,
}) {
  final relay = relayRoom != null && server != null;
  Future<Connection> secure(Connection raw) =>
      connectSecure(raw, hostKey: hostKey, roomSecret: roomSecret);
  return () async {
    if (lan != null) {
      try {
        return await secure(
          await dialHost(
            lan.ip,
            lan.port,
            timeout: Duration(seconds: relay ? 3 : 6),
          ),
        );
      } on NoiseError {
        // Someone else answered at that address: never fall back silently.
        rethrow;
      } on Object {
        if (!relay) rethrow;
      }
    }
    if (!relay) throw StateError('no way to reach the host');
    return secure(await dialRelay(server, relayRoom));
  };
}
