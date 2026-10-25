import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:game_core/game_core.dart';
import 'package:game_host/game_host.dart';
import 'package:game_host/relay.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:whowolf_server/relay_server.dart';

Future<T> eventually<T>(T? Function() probe) async {
  for (var i = 0; i < 250; i++) {
    final value = probe();
    if (value != null) return value;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  throw TimeoutException('condition not met');
}

void main() {
  late RelayServer relay;
  late Uri server;

  setUp(() async {
    relay = await RelayServer.start(address: '127.0.0.1', port: 0);
    server = Uri.parse('ws://127.0.0.1:${relay.port}');
  });

  tearDown(() => relay.close());

  test('remote players reach the host through the relay', () async {
    final host = GameHost(roomCode: '1357', random: Random(1));
    final transport = await RelayTransport.open(server);
    host.serve(transport);
    expect(isRelayRoomId(transport.roomId), isTrue);
    expect(relay.roomCount, 1);

    final views = <String, PlayerView>{};
    final connections = <Connection>[];
    for (final name in ['Ada', 'Bo', 'Cem']) {
      final c = await dialRelay(server, transport.roomId);
      connections.add(c);
      c.messages.listen((raw) {
        final m = HostMessage.parse(raw);
        if (m is StateMessage) views[name] = m.view;
      });
      c.send(Hello(name: name, room: '1357').encode());
    }
    await eventually(
      () => views.length == 3 && views['Ada']!.seats.length == 3 ? true : null,
    );
    expect(views['Cem']!.seats.map((s) => s.name), ['Ada', 'Bo', 'Cem']);

    // A player leaving is seen by the host as a closed connection.
    await connections.first.close();
    await host.close();
    await eventually(() => relay.roomCount == 0 ? true : null);
  });

  test('unknown rooms and wrong paths are refused', () async {
    final client = HttpClient();
    Future<int> status(String path) async {
      final request = await client.get('127.0.0.1', relay.port, path);
      return (await request.close()).statusCode;
    }

    expect(await status('/health'), 200);
    expect(await status('/join/abcd2345'), 404);
    expect(await status('/anything'), 404);
    await expectLater(
      dialRelay(server, 'abcd2345'),
      throwsA(isA<WebSocketException>()),
    );
    client.close();
  });

  test('a host sending garbage loses its room', () async {
    final socket = await WebSocket.connect('$server/host');
    final frames = <Object?>[];
    final done = Completer<void>();
    socket.listen(frames.add, onDone: done.complete);
    await eventually(() => frames.isNotEmpty ? true : null);
    expect(RelayFrame.parse(frames.first! as String), isA<RoomOpened>());
    expect(relay.roomCount, 1);
    socket.add('{garbage');
    await done.future.timeout(const Duration(seconds: 5));
    expect(relay.roomCount, 0);
  });
}
