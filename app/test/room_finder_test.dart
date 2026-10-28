import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:whowolf/src/net/discovery.dart';

NearbyRoom _room(String id, {String ip = '192.168.1.20', String? print}) =>
    NearbyRoom(
      id: id,
      hostName: 'Test',
      room: '1234',
      lan: LanAddress(ip, 4040),
      keyPrint: print,
    );

/// The keychain as a map, so a "restart" can read what was written.
Map<String, String> _fakeKeychain() {
  final values = <String, String>{};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (call) async {
          final args = (call.arguments as Map).cast<String, Object?>();
          final key = args['key'] as String?;
          switch (call.method) {
            case 'read':
              return values[key];
            case 'write':
              values[key!] = args['value']! as String;
            case 'delete':
              values.remove(key);
          }
          return null;
        },
      );
  return values;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a room closed here leaves every running search at once', () {
    final finder = RoomFinder.manual();
    addTearDown(finder.dispose);
    var told = 0;
    finder.addListener(() => told++);

    RoomFinder.closed(List.filled(32, 7));
    expect(told, 1);

    // Closing it again changes nothing.
    RoomFinder.closed(List.filled(32, 7));
    expect(told, 1);
  });

  group('with a probe', () {
    late Set<String> answering;
    late List<String> probed;
    late RoomFinder finder;

    setUp(() {
      answering = {};
      probed = [];
      finder = RoomFinder.manual(
        probe: (at) async {
          probed.add(at.ip);
          return answering.contains(at.ip);
        },
        every: const Duration(hours: 1),
      );
    });
    tearDown(() => finder.dispose());

    test('an announced room whose host does not answer never shows', () async {
      finder.add(_room('a'));
      await pumpEventQueue();
      expect(probed, ['192.168.1.20']);
      expect(finder.rooms, isEmpty);
    });

    test('a room whose host answers shows', () async {
      answering.add('192.168.1.20');
      finder.add(_room('a'));
      await pumpEventQueue();
      expect(finder.rooms.map((r) => r.id), ['a']);
    });

    test('a room that stops answering leaves after two misses, and comes '
        'back when it answers again', () async {
      answering.add('192.168.1.20');
      finder.add(_room('a'));
      await pumpEventQueue();
      expect(finder.rooms, hasLength(1));

      answering.clear();
      await finder.probeAll();
      expect(finder.rooms, hasLength(1), reason: 'one miss is not enough');
      await finder.probeAll();
      expect(finder.rooms, isEmpty);

      answering.add('192.168.1.20');
      await finder.probeAll();
      expect(finder.rooms, hasLength(1));
    });

    test('a tapped room that does not answer leaves at once', () async {
      answering.add('192.168.1.20');
      final room = _room('a');
      finder.add(room);
      await pumpEventQueue();

      answering.clear();
      expect(await finder.check(room), isFalse);
      expect(finder.rooms, isEmpty);
    });

    test('more announcements than the limit cause no further probes', () async {
      for (var i = 0; i < RoomFinder.maxRooms + 10; i++) {
        finder.add(_room('r$i', ip: '192.168.2.${i + 1}'));
      }
      await pumpEventQueue();
      expect(finder.all, hasLength(RoomFinder.maxRooms));
      expect(probed, hasLength(RoomFinder.maxRooms));
    });

    test('a room closed here is not probed', () async {
      RoomFinder.closed(List.filled(32, 9));
      finder.add(_room('a', print: keyPrint(List.filled(32, 9))));
      await pumpEventQueue();
      expect(probed, isEmpty);
    });
  });

  test(
    'a room closed here stays hidden after a restart, until it expires',
    () async {
      final keychain = _fakeKeychain();
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel(
                'plugins.it_nomads.com/flutter_secure_storage',
              ),
              null,
            ),
      );
      final key = List.filled(32, 3);
      RoomFinder.closed(key);
      await pumpEventQueue();
      expect(keychain['closedRooms'], contains(keyPrint(key)));

      await RoomFinder.restart();
      final finder = RoomFinder.manual();
      addTearDown(finder.dispose);
      finder.add(_room('a', print: keyPrint(key)));
      expect(finder.rooms, isEmpty);

      // Expired: the room shows again (if it is announced at all).
      keychain['closedRooms'] = '{"${keyPrint(key)}": 1}';
      await RoomFinder.restart();
      finder.add(_room('b', print: keyPrint(key)));
      expect(finder.rooms.map((r) => r.id), containsAll(['a', 'b']));
    },
  );

  test('the TCP probe answers only for a listening host', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    HostLocator.loopback = true;
    addTearDown(() => HostLocator.loopback = false);
    expect(await tcpProbe(LanAddress('192.168.1.2', port)), isTrue);
    await server.close();
    expect(await tcpProbe(LanAddress('192.168.1.2', port)), isFalse);
  });
}
