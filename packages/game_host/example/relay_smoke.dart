// Smoke test against a running relay (e.g. `docker compose up -d`): opens a
// room through the relay and lets three players join it.
//
//   dart run example/relay_smoke.dart ws://localhost:8080
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:game_host/game_host.dart';
import 'package:game_host/relay.dart';
import 'package:protocol/protocol.dart';

Future<void> main(List<String> args) async {
  final server = parseRelayServer(
    args.firstOrNull ?? 'ws://localhost:8080',
  );
  if (server == null) {
    stderr.writeln('Usage: relay_smoke.dart ws(s)://host[:port]');
    exitCode = 64;
    return;
  }
  final relay = await RelayTransport.open(server);
  final host = GameHost(roomCode: '1357', random: Random.secure())
    ..serve(relay);
  stdout.writeln('Room ${relay.roomId} on $server');

  final names = <String>{};
  for (final name in ['Ada', 'Bo', 'Cem']) {
    final c = await dialRelay(server, relay.roomId);
    c.messages.listen((raw) {
      final m = HostMessage.parse(raw);
      if (m is StateMessage) names.addAll(m.view.seats.map((s) => s.name));
    });
    c.send(Hello(name: name, room: '1357').encode());
  }
  await Future<void>.delayed(const Duration(seconds: 1));
  final ok = names.length == 3;
  stdout.writeln(ok ? 'OK: $names' : 'FAILED: $names');
  await host.close();
  exitCode = ok ? 0 : 1;
}
