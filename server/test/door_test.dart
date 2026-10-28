import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:game_host/relay.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:whowolf_server/relay_server.dart';
import 'package:whowolf_server/web_apps.dart';

import 'relay_test.dart' show eventually;

/// Door codes: a host gets a short code for its room, people type it on the
/// relay's code page and land on the room's page, without the room's keys
/// (task 022).
void main() {
  late Directory root;
  late HttpClient client;
  final relays = <RelayServer>[];

  setUpAll(() async {
    root = await Directory.systemTemp.createTemp('doors');
    final page = File('${root.path}/12/0.3.0/index.html');
    await page.parent.create(recursive: true);
    await page.writeAsString('<!DOCTYPE html>page');
  });
  tearDownAll(() => root.delete(recursive: true));

  setUp(() => client = HttpClient());
  tearDown(() async {
    client.close(force: true);
    for (final relay in relays) {
      await relay.close();
    }
    relays.clear();
  });

  Future<RelayServer> start({
    RelayConfig config = const RelayConfig(),
    bool webApp = true,
  }) async {
    final relay = await RelayServer.start(
      address: '127.0.0.1',
      port: 0,
      config: config,
      webApps: webApp ? await WebApps.load(root) : null,
    );
    relays.add(relay);
    return relay;
  }

  Uri socketOf(RelayServer relay) => Uri.parse('ws://127.0.0.1:${relay.port}');

  Future<({int status, String? location, String body, HttpHeaders headers})>
  get(
    RelayServer relay,
    String path, {
    String method = 'GET',
    String language = 'en',
  }) async {
    final request = await client.openUrl(
      method,
      Uri.parse('http://127.0.0.1:${relay.port}$path'),
    );
    request
      ..followRedirects = false
      ..headers.set(HttpHeaders.acceptLanguageHeader, language);
    final response = await request.close();
    return (
      status: response.statusCode,
      location: response.headers.value(HttpHeaders.locationHeader),
      body: await response.transform(utf8.decoder).join(),
      headers: response.headers,
    );
  }

  String lookup(String code) => '/c?code=${Uri.encodeQueryComponent(code)}';

  test('a typed code leads to the room page, without any key', () async {
    final relay = await start();
    final host = await RelayTransport.open(socketOf(relay));
    expect(host.doors, isTrue);
    host.openDoor(room: '1234', protocol: 12, build: '0.3.0');
    final code = await eventually(() => host.doorCode);
    expect(isDoorCode(code), isTrue);

    // Typed as people do: upper case, with a space or a dash.
    for (final typed in [showDoorCode(code), code, code.toUpperCase()]) {
      final r = await get(relay, lookup(typed));
      expect(r.status, HttpStatus.seeOther, reason: typed);
      expect(
        r.location,
        '/v/12/0.3.0/join?room=1234&relay=${host.roomId}',
      );
      // The page the browser lands on knows the room, never a key.
      final link = JoinLink.tryParseCodePage(
        'https://play.example.org${r.location}',
      )!;
      expect(link.relayRoom, host.roomId);
      expect(link.hostKey, isNull);
      expect(link.roomSecret, isNull);
    }
    await host.close();
  });

  test('the code page is plain, strict and in two languages', () async {
    final relay = await start();
    final en = await get(relay, '/');
    expect(en.status, HttpStatus.ok);
    expect(en.body, contains('Join with a code'));
    expect(en.body, isNot(contains('<script')));
    expect(en.headers.value('content-security-policy'), contains("'none'"));
    expect(en.headers.value('cache-control'), 'no-store');
    expect(en.headers.value('x-frame-options'), 'DENY');
    final de = await get(relay, '/', language: 'de-DE,de;q=0.9');
    expect(de.body, contains('Mitspielen mit Code'));
    expect((await get(relay, '/', method: 'POST')).status, 405);
  });

  test('without a web app there are no door codes and no page', () async {
    final relay = await start(webApp: false);
    final host = await RelayTransport.open(socketOf(relay));
    expect(host.doors, isFalse);
    host.openDoor(room: '1234', protocol: 12, build: '0.3.0');
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(host.doorCode, isNull);
    expect(relay.doorCount, 0);
    expect((await get(relay, '/')).status, 404);
    expect((await get(relay, lookup('abc234'))).status, 404);
    await host.close();
  });

  test('codes rotate; the previous one still works, older ones not', () async {
    final relay = await start(
      config: const RelayConfig(minDoorInterval: Duration.zero),
    );
    final host = await RelayTransport.open(socketOf(relay));
    final seen = <String>[];
    host.doorCodes.listen((c) {
      if (c != null) seen.add(c);
    });
    host.openDoor(
      room: '1234',
      protocol: 12,
      build: '0.3.0',
      every: const Duration(milliseconds: 150),
    );
    await eventually(() => seen.length >= 3 ? true : null);
    expect(seen.toSet().length, seen.length);
    expect(relay.doorCount, 2);
    await host.close();

    // Step by step: three codes in a row, the first one is gone.
    final socket = await WebSocket.connect('${socketOf(relay)}/host');
    final frames = StreamIterator(socket);
    await frames.moveNext();
    const ask = DoorAsked(room: '4321', protocol: 12, build: '0.3.0');
    final codes = <String>[];
    for (var i = 0; i < 3; i++) {
      socket.add(ask.encode());
      await frames.moveNext();
      codes.add(
        (RelayFrame.parse(frames.current as String) as DoorOpened).code,
      );
    }
    expect((await get(relay, lookup(codes[2]))).status, HttpStatus.seeOther);
    expect((await get(relay, lookup(codes[1]))).status, HttpStatus.seeOther);
    expect((await get(relay, lookup(codes[0]))).status, HttpStatus.notFound);
    await socket.close();
  });

  test('a code stops working when its time is up', () async {
    final relay = await start(
      config: const RelayConfig(doorLifetime: Duration(seconds: 1)),
    );
    final host = await RelayTransport.open(socketOf(relay));
    host.openDoor(room: '1234', protocol: 12, build: '0.3.0');
    final code = await eventually(() => host.doorCode);
    expect((await get(relay, lookup(code))).status, HttpStatus.seeOther);
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    expect((await get(relay, lookup(code))).status, HttpStatus.notFound);
    // The host stops showing it too.
    expect(host.doorCode, isNull);
    await host.close();
  });

  test('codes die with their room', () async {
    final relay = await start();
    final host = await RelayTransport.open(socketOf(relay));
    host.openDoor(room: '1234', protocol: 12, build: '0.3.0');
    final code = await eventually(() => host.doorCode);
    await host.close();
    await eventually(() => relay.roomCount == 0 ? true : null);
    expect(relay.doorCount, 0);
    expect((await get(relay, lookup(code))).status, HttpStatus.notFound);
  });

  test('a build the server lacks gets a clear version note', () async {
    final relay = await start();
    final host = await RelayTransport.open(socketOf(relay));
    host.openDoor(room: '1234', protocol: 12, build: '9.9.9');
    final code = await eventually(() => host.doorCode);
    final r = await get(relay, lookup(code));
    expect(r.status, HttpStatus.notFound);
    expect(r.location, isNull);
    expect(r.body, contains('app version'));
    await host.close();
  });

  test('guessing is limited per address, right or wrong', () async {
    final relay = await start(
      config: const RelayConfig(maxDoorLookupsPerMinute: 3),
    );
    final host = await RelayTransport.open(socketOf(relay));
    host.openDoor(room: '1234', protocol: 12, build: '0.3.0');
    final code = await eventually(() => host.doorCode);
    for (final guess in ['aaaaaa', 'bbbbbb', 'cccccc']) {
      expect((await get(relay, lookup(guess))).status, HttpStatus.notFound);
    }
    // Even the right code waits now.
    final r = await get(relay, lookup(code));
    expect(r.status, HttpStatus.tooManyRequests);
    expect(r.location, isNull);
    // The page itself still loads (it costs no guess).
    expect((await get(relay, '/')).status, HttpStatus.ok);
    await host.close();
  });

  test('odd input is refused and never echoed', () async {
    final relay = await start(
      config: const RelayConfig(maxDoorLookupsPerMinute: 0),
    );
    for (final path in [
      '/c',
      lookup('<script>alert(1)</script>'),
      lookup('ab'),
      lookup('a' * 4000),
      lookup('ABC 23I'),
    ]) {
      final r = await get(relay, path);
      expect(r.status, HttpStatus.notFound, reason: path);
      expect(r.body, isNot(contains('alert(1)')));
      expect(r.body, isNot(contains('aaaaaaaaaa')));
    }
  });

  test('hosts asking too often or wrongly get nothing', () async {
    final relay = await start();
    // Too often: the second ask within the interval is not answered.
    final socket = await WebSocket.connect('${socketOf(relay)}/host');
    final frames = StreamIterator(socket);
    expect(await frames.moveNext(), isTrue);
    final opened = RelayFrame.parse(frames.current as String) as RoomOpened;
    expect(opened.doors, isTrue);
    const ask = DoorAsked(room: '1234', protocol: 12, build: '0.3.0');
    socket
      ..add(ask.encode())
      ..add(ask.encode());
    expect(await frames.moveNext(), isTrue);
    expect(RelayFrame.parse(frames.current as String), isA<DoorOpened>());
    expect(
      await frames.moveNext().timeout(
        const Duration(milliseconds: 400),
        onTimeout: () => false,
      ),
      isFalse,
    );
    expect(relay.doorCount, 1);

    // A malformed ask ends the room, like any bad frame.
    socket.add(
      jsonEncode({
        'rv': relayVersion,
        't': 'ask',
        'room': '12a4',
        'p': 12,
        'build': '0.3.0',
      }),
    );
    await eventually(() => relay.roomCount == 0 ? true : null);
    expect(relay.doorCount, 0);
    await socket.close();
  });

  test('door frames are strictly read', () {
    const ask = DoorAsked(room: '1234', protocol: 12, build: '0.3.0');
    final back = RelayFrame.parse(ask.encode()) as DoorAsked;
    expect((back.room, back.protocol, back.build), ('1234', 12, '0.3.0'));
    final door = RelayFrame.parse(
      const DoorOpened('abc234', lifetime: Duration(minutes: 7)).encode(),
    );
    expect((door as DoorOpened).lifetime, const Duration(minutes: 7));
    // An old server's room frame has no doors.
    expect(
      (RelayFrame.parse('{"rv":1,"t":"room","room":"abcd2345"}') as RoomOpened)
          .doors,
      isFalse,
    );
    for (final bad in [
      '{"rv":1,"t":"ask","room":"1234","p":12,"build":"../x"}',
      '{"rv":1,"t":"ask","room":"1234","p":0,"build":"0.3.0"}',
      '{"rv":1,"t":"ask","room":"123","p":12,"build":"0.3.0"}',
      '{"rv":1,"t":"door","code":"ABC234","ttl":60}',
      '{"rv":1,"t":"door","code":"abc23i","ttl":60}',
      '{"rv":1,"t":"door","code":"abc234","ttl":0}',
      '{"rv":1,"t":"door","code":"abc234"}',
    ]) {
      expect(
        () => RelayFrame.parse(bad),
        throwsA(isA<ProtocolError>()),
        reason: bad,
      );
    }
    expect(normalizeDoorCode(' abc-234 '), 'abc234');
    expect(normalizeDoorCode('ABC 234'), 'abc234');
    expect(normalizeDoorCode('abc 23l'), isNull);
    expect(normalizeDoorCode('x' * 40), isNull);
    expect(showDoorCode('abc234'), 'ABC 234');
  });
}
