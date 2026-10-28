// A dress rehearsal against a real relay (the official one by default):
// a host opens a room there, asks for a door code and checks that the
// code page sends people to this build's join page, then six bots play a
// whole game with every role and the mayor through the relay.
//
//   dart run tool/smoke_relay.dart [wss://play.whowolf.de] [0.2.0]
//
// Nothing is kept: the room closes when the game is over.
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:game_core/game_core.dart';
import 'package:game_host/game_host.dart';
import 'package:game_host/relay.dart';
import 'package:protocol/protocol.dart';

Future<T> _until<T>(
  T? Function() value,
  String what, {
  int seconds = 30,
}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (DateTime.now().isBefore(end)) {
    final v = value();
    if (v != null) return v;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  throw StateError('timed out waiting for $what');
}

void _ok(String line) => stdout.writeln('✓ $line');

Future<void> main(List<String> args) async {
  final server = Uri.parse(args.isNotEmpty ? args[0] : 'wss://play.whowolf.de');
  final build = args.length > 1 ? args[1] : '0.2.0';
  final random = Random();
  final room = '${1000 + random.nextInt(9000)}';

  final host = GameHost(
    settings: Preset.fullStage.settings,
    roomCode: room,
    random: random,
  );
  final transport = await RelayTransport.open(server);
  host.serve(transport);
  _ok('room ${transport.roomId} opened on ${server.host}');

  // The door code and the page it leads to.
  if (!transport.doors) throw StateError('the relay hands out no door codes');
  transport.openDoor(room: room, protocol: protocolVersion, build: build);
  final code = await _until(() => transport.doorCode, 'a door code');
  _ok('door code $code');
  final client = HttpClient();
  final request = await client.getUrl(
    Uri.https(server.host, '/c', {'code': code}),
  );
  request.followRedirects = false;
  final response = await request.close();
  await response.drain<void>();
  final location = response.headers.value(HttpHeaders.locationHeader) ?? '';
  if (response.statusCode != 303 ||
      !location.contains('/v/$protocolVersion/$build/join') ||
      !location.contains('room=$room') ||
      !location.contains('relay=${transport.roomId}')) {
    throw StateError('code page answered ${response.statusCode} → $location');
  }
  _ok('code page sends to $location');
  final page = await (await client.getUrl(
    Uri.https(server.host, location.split('?').first),
  )).close();
  await page.drain<void>();
  if (page.statusCode != 200) {
    throw StateError('join page answered ${page.statusCode}');
  }
  _ok('join page of $build is there');
  client.close();

  // Six bots through the relay, the first one the game leader.
  final links = <PlayerLink>[
    PlayerLink(
      name: 'Owner',
      roomCode: room,
      dial: () async => host.connectOwner(),
      random: Random(1),
    ),
    for (final name in ['Ada', 'Bo', 'Cem', 'Dua', 'Eli'])
      PlayerLink(
        name: name,
        roomCode: room,
        dial: () => dialRelay(server, transport.roomId),
        random: Random(name.hashCode),
      ),
  ];
  await _until(
    () => links.every((l) => l.view?.seats.length == 6) ? true : null,
    'six seats',
  );
  _ok('six players seated, five of them through the relay');
  links.first.send(const StartGameIntent());

  final sent = <String>{};
  void once(PlayerLink link, String key, ClientMessage message) {
    if (sent.add('${link.name}/$key')) link.send(message);
  }

  var lastPhase = '';
  final end = DateTime.now().add(const Duration(minutes: 8));
  while (links.first.view?.phase != Phase.ended) {
    if (DateTime.now().isAfter(end)) throw StateError('the game got stuck');
    for (final link in links) {
      final v = link.view;
      if (v == null) continue;
      final me = v.yourSeat;
      final others = [
        for (final s in v.seats)
          if (s.isAlive && s.id != v.you) s,
      ];
      PlayerId pick() => others[random.nextInt(others.length)].id;
      final step = '${v.round}/${v.phase.name}/${v.nightStep.name}';
      switch (v.phase) {
        case Phase.roleReveal:
          once(link, 'confirm', const ConfirmRoleIntent());
        case Phase.night when me.isAlive && others.isNotEmpty:
          final task = v.yourNightTask;
          final message = switch (task) {
            null => null,
            NightAbility.hunt => NightIntent(
              others.firstWhere((s) => s.role != Role.werewolf).id,
            ),
            NightAbility.link => NightIntent.of([v.you, pick()]),
            NightAbility.brew => NightIntent.of(const []),
            NightAbility.protect => NightIntent(
              v.seats
                  .firstWhere((s) => s.isAlive && s.id != v.guardedBefore)
                  .id,
            ),
            NightAbility.inspect || NightAbility.decoy => NightIntent(pick()),
          };
          if (message != null) once(link, 'night/$step', message);
        case Phase.day:
          if (me.isAlive &&
              v.settings.mayor &&
              !v.seats.any((s) => s.id == v.mayor && s.isAlive)) {
            final leader = links.first.you!;
            final alive = v.seats.any((s) => s.id == leader && s.isAlive);
            once(link, 'mayor/$step', MayorIntent(alive ? leader : v.you));
          }
          if (me.isAlive) {
            once(link, 'ready/$step', const ReadyIntent(ready: true));
          }
          // The game leader ends the talk, dead or alive.
          if (link == links.first) {
            once(link, 'end/$step', const EndDiscussionIntent());
          }
        case Phase.vote when me.isAlive && others.isNotEmpty:
          once(
            link,
            'vote/$step/${v.runoff.length}',
            VoteIntent(
              v.runoff.isEmpty
                  ? pick()
                  : v.runoff.firstWhere((p) => p != v.you),
            ),
          );
        case Phase.hunterShot when v.shooter == v.you && others.isNotEmpty:
          once(link, 'shot/$step', ShootIntent(pick()));
        case Phase.lobby ||
            Phase.night ||
            Phase.day ||
            Phase.vote ||
            Phase.hunterShot ||
            Phase.ended:
          break;
      }
    }
    final phase = '${links.first.view?.phase.name} ${links.first.view?.round}';
    if (phase != lastPhase) {
      stdout.writeln('  … $phase');
      lastPhase = phase;
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
  final ended = links.first.view!;
  final mayor = ended.mayor == null
      ? 'none'
      : ended.seats.firstWhere((s) => s.id == ended.mayor).name;
  _ok(
    'game over after ${ended.round} rounds: '
    '${ended.winner?.name ?? '?'} won, mayor $mayor, '
    '${ended.chronicle.length} chronicle entries',
  );
  if (links.any((l) => l.view?.phase != Phase.ended)) {
    throw StateError('not every player saw the end');
  }
  _ok('every player saw the same end');
  for (final l in links) {
    l.close();
  }
  await host.close();
  exit(0);
}
