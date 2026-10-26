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

  test('one address cannot hold every room', () async {
    final hosts = <RelayTransport>[];
    for (var i = 0; i < const RelayConfig().maxRoomsPerAddress; i++) {
      hosts.add(await RelayTransport.open(server));
    }
    expect(relay.roomCount, hosts.length);
    await expectLater(RelayTransport.open(server), throwsA(anything));
    await hosts.first.close();
    await eventually(() => relay.roomCount == hosts.length - 1 ? true : null);
    hosts[0] = await RelayTransport.open(server);
    for (final h in hosts) {
      await h.close();
    }
  });

  test('rooms opened at the same moment still respect the limit', () async {
    final limit = const RelayConfig().maxRoomsPerAddress;
    final tries = await Future.wait([
      for (var i = 0; i < limit + 3; i++)
        RelayTransport.open(server).then<RelayTransport?>(
          (t) => t,
          onError: (Object _) => null,
        ),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(relay.roomCount, lessThanOrEqualTo(limit));
    for (final t in tries.nonNulls) {
      await t.close();
    }
  });

  group('limits for a public server', () {
    Future<RelayServer> start(RelayConfig config) async {
      final r = await RelayServer.start(
        address: '127.0.0.1',
        port: 0,
        config: config,
      );
      addTearDown(r.close);
      return r;
    }

    Future<int> upgrade(int port, String path, {String? forwardedFor}) async {
      final client = HttpClient();
      addTearDown(client.close);
      final request = await client.get('127.0.0.1', port, path);
      request.headers
        ..set('Connection', 'Upgrade')
        ..set('Upgrade', 'websocket')
        ..set('Sec-WebSocket-Version', '13')
        ..set('Sec-WebSocket-Key', 'dGhlIHNhbXBsZSBub25jZQ==');
      if (forwardedFor != null) {
        request.headers.set('X-Forwarded-For', forwardedFor);
      }
      final response = await request.close();
      if (response.statusCode == HttpStatus.switchingProtocols) {
        // The handshake by hand gives the answer RFC 6455 asks for.
        expect(
          response.headers.value('sec-websocket-accept'),
          's3pPLMBiTxaQ9kYGzzhZRbK+xOo=',
        );
        unawaited((await response.detachSocket()).close());
      }
      return response.statusCode;
    }

    test('a huge frame is cut off before it is complete', () async {
      final relay = await start(const RelayConfig());
      relay.playerBudget = const ByteBudget(burst: 16 * 1024, rate: 1024);
      final room = await RelayTransport.open(
        Uri.parse('ws://127.0.0.1:${relay.port}'),
      );
      addTearDown(room.close);
      final peer = await WebSocket.connect(
        'ws://127.0.0.1:${relay.port}/join/${room.roomId}',
      );
      final closed = Completer<void>();
      // One message of 4 MB: the relay hangs up long before it would hold it.
      peer
        ..listen(null, onDone: closed.complete)
        ..add('x' * (4 << 20));
      await closed.future.timeout(const Duration(seconds: 5));
      await eventually(() => relay.connectionCount == 1 ? true : null);
      expect(relay.roomCount, 1, reason: 'the room itself stays open');
    });

    test('one address can only hold so many sockets', () async {
      final relay = await start(
        const RelayConfig(maxConnectionsPerAddress: 2, maxRoomsPerAddress: 0),
      );
      final server = Uri.parse('ws://127.0.0.1:${relay.port}');
      final a = await RelayTransport.open(server);
      final b = await RelayTransport.open(server);
      addTearDown(a.close);
      addTearDown(b.close);
      expect(await upgrade(relay.port, '/host'), HttpStatus.tooManyRequests);
      await a.close();
      await eventually(() => relay.connectionCount == 1 ? true : null);
      final c = await RelayTransport.open(server);
      addTearDown(c.close);
    });

    test('nobody can try room ids quickly', () async {
      final relay = await start(const RelayConfig(maxUpgradesPerMinute: 5));
      final codes = [
        for (var i = 0; i < 8; i++) await upgrade(relay.port, '/join/abcd2345'),
      ];
      expect(codes.take(5), everyElement(HttpStatus.notFound));
      expect(codes.skip(5), everyElement(HttpStatus.tooManyRequests));
    });

    test('the forwarded address counts only behind a trusted proxy', () async {
      const config = RelayConfig(
        maxConnectionsPerAddress: 1,
        maxRoomsPerAddress: 0,
      );
      final open = await start(config);
      // Not trusted: the header changes nothing, all come from 127.0.0.1.
      expect(
        await upgrade(open.port, '/host', forwardedFor: '203.0.113.1'),
        101,
      );
      await eventually(() => open.connectionCount == 0 ? true : null);

      final behind = await start(
        const RelayConfig(
          maxConnectionsPerAddress: 1,
          maxRoomsPerAddress: 0,
          trustProxy: true,
        ),
      );
      final server = 'ws://127.0.0.1:${behind.port}/host';
      final one = await WebSocket.connect(
        server,
        headers: {'X-Forwarded-For': '203.0.113.1'},
      );
      final two = await WebSocket.connect(
        server,
        headers: {'X-Forwarded-For': 'spoofed, 203.0.113.2'},
      );
      addTearDown(one.close);
      addTearDown(two.close);
      expect(behind.connectionCount, 2);
      expect(
        await upgrade(behind.port, '/host', forwardedFor: '203.0.113.1'),
        HttpStatus.tooManyRequests,
      );
    });
  });
}
