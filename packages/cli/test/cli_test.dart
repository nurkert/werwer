import 'dart:async';
import 'dart:math';

import 'package:game_core/game_core.dart';
import 'package:game_host/game_host.dart';
import 'package:game_host/lan.dart';
import 'package:secure_channel/secure_channel.dart';
import 'package:test/test.dart';
import 'package:whowolf_cli/whowolf_cli.dart';

Future<void> until(bool Function() done) async {
  for (var i = 0; i < 200; i++) {
    if (done()) return;
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
  fail('condition not met');
}

void main() {
  test('three terminals play a whole game over encrypted sockets', () async {
    final keys = await HostKeys.generate();
    final lan = await LanTransport.bind(port: 0);
    final host = GameHost(
      settings: const GameSettings(),
      roomCode: '2580',
      random: Random(11),
    )..serve(SecureTransport(lan, keys));
    final logs = {
      for (final n in ['Ada', 'Bo', 'Cem']) n: StringBuffer(),
    };

    Future<CliPlayer> remote(String name, {String? token}) async => CliPlayer(
      name: name,
      room: '2580',
      token: token,
      out: logs[name]!,
      connection: await connectSecure(
        await dialHost('127.0.0.1', lan.port),
        hostKey: keys.publicKey,
        roomSecret: keys.roomSecret,
      ),
    );

    final ada = CliPlayer(
      name: 'Ada',
      room: '2580',
      connection: host.connectOwner(),
      out: logs['Ada']!,
    );
    await until(() => ada.view != null);
    var bo = await remote('Bo');
    final cem = await remote('Cem');
    await until(() => ada.view!.seats.length == 3);

    ada.command('start');
    await until(() => ada.view!.phase == Phase.roleReveal);
    for (final p in [ada, bo, cem]) {
      p.command('confirm');
    }
    await until(() => ada.view!.phase == Phase.night);

    // Bo drops out and comes back with his token, with his role intact.
    final boRole = bo.view!.yourRole;
    final boToken = bo.token;
    await bo.connection.close();
    bo = await remote('Bo', token: boToken);
    await until(() => bo.view?.phase == Phase.night);
    expect(bo.view!.yourRole, boRole);

    // Night: the wolf takes a villager, everyone else picks the wolf.
    final players = [ada, bo, cem];
    final wolf = players.firstWhere((p) => p.view!.yourRole == Role.werewolf);
    final others = players.where((p) => p != wolf).toList();
    wolf.command('pick ${others.first.name}');
    for (final p in others) {
      p.command('pick ${wolf.name}');
    }
    await until(() => ada.view!.phase != Phase.night);

    if (ada.view!.phase == Phase.day) {
      ada.command('vote');
      await until(() => ada.view!.phase == Phase.vote);
      for (final p in players.where((p) => p.view!.yourSeat.isAlive)) {
        p.command(p == wolf ? 'vote none' : 'vote ${wolf.name}');
      }
    }
    await until(() => ada.view!.phase == Phase.ended);
    expect(logs['Cem'].toString(), contains('Game over'));
    expect(logs['Bo'].toString(), contains('Joined room 2580'));
    await host.close();
  });
}
