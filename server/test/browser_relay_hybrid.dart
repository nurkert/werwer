import 'dart:math';

import 'package:game_host/game_host.dart';
import 'package:game_host/relay.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:whowolf_server/relay_server.dart';

/// Runs in the VM next to `browser_relay_test.dart`: a relay server and a
/// host with one room on it. Tells the browser where to find them, and
/// shuts down when the browser closes the channel.
Future<void> hybridMain(StreamChannel<Object?> channel, Object? _) async {
  final relay = await RelayServer.start(address: '127.0.0.1', port: 0);
  final host = GameHost(roomCode: '1357', random: Random(1));
  final transport = await RelayTransport.open(
    Uri.parse('ws://127.0.0.1:${relay.port}'),
  );
  host.serve(transport);
  channel.sink.add({'port': relay.port, 'room': transport.roomId});
  await channel.stream.drain<void>();
  await host.close();
  await relay.close();
}
