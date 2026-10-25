// Smoke test over the real network: hosts a room on this machine's Wi-Fi
// address and lets three players join and play into the first night.
//
//   dart run example/lan_smoke.dart
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:game_core/game_core.dart';
import 'package:game_host/game_host.dart';
import 'package:game_host/lan.dart';
import 'package:protocol/protocol.dart';

Future<void> main() async {
  final addresses = await privateAddresses();
  if (addresses.isEmpty) {
    stderr.writeln('No private network address found.');
    exitCode = 1;
    return;
  }
  final ip = addresses.first.address;
  final lan = await LanTransport.bind();
  final host = GameHost(roomCode: '2468', random: Random.secure())..serve(lan);
  stdout.writeln('Hosting on $ip:${lan.port}');

  final views = <String, PlayerView>{};
  final connections = <String, Connection>{};
  for (final name in ['Ada', 'Bo', 'Cem']) {
    final connection = await dialHost(ip, lan.port);
    connections[name] = connection;
    connection.messages.listen((raw) {
      final message = HostMessage.parse(raw);
      if (message is StateMessage) views[name] = message.view;
    });
    connection.send(Hello(name: name, room: '2468').encode());
  }
  final owner = host.connectOwner();
  owner.messages.listen((_) {});
  owner.send(const Hello(name: 'Host', room: '2468').encode());
  await Future<void>.delayed(const Duration(milliseconds: 300));
  owner.send(const StartGameIntent().encode());
  await Future<void>.delayed(const Duration(milliseconds: 300));
  for (final c in [...connections.values, owner]) {
    c.send(const ConfirmRoleIntent().encode());
  }
  await Future<void>.delayed(const Duration(milliseconds: 300));

  for (final MapEntry(:key, :value) in views.entries) {
    stdout.writeln('$key: ${value.phase.name}, role ${value.yourRole?.name}');
  }
  final ok =
      views.length == 3 && views.values.every((v) => v.phase == Phase.night);
  stdout.writeln(ok ? 'OK' : 'FAILED');
  await host.close();
  exitCode = ok ? 0 : 1;
}
