import 'dart:convert';

import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

void main() {
  group('join links', () {
    test('round-trip with LAN and relay', () {
      final link = JoinLink(
        room: '1234',
        lan: const LanAddress('192.168.1.5', 47470),
        relayRoom: 'abcd2345',
        server: parseRelayServer('wss://relay.example.org'),
        hostKey: List.filled(32, 7),
        roomSecret: List.filled(32, 9),
      );
      final back = JoinLink.tryParse(link.encode())!;
      expect(back.hostKey, List.filled(32, 7));
      expect(back.roomSecret, List.filled(32, 9));
      expect(link.encode(), contains('#k='));
      expect(back.room, '1234');
      expect(back.lan.toString(), '192.168.1.5:47470');
      expect(back.relayRoom, 'abcd2345');
      expect(back.server.toString(), 'wss://relay.example.org');
    });

    test('anything else is refused', () {
      for (final raw in [
        'https://evil.de/join?room=1234&lan=192.168.1.5:1',
        'http://whowolf.de/join?room=1234&lan=192.168.1.5:1',
        'https://whowolf.de/other?room=1234&lan=192.168.1.5:1',
        'https://whowolf.de/join?room=123&lan=192.168.1.5:1',
        'https://whowolf.de/join?room=1234',
        'https://whowolf.de/join?room=1234&lan=8.8.8.8:53',
        'https://whowolf.de/join?room=1234&lan=192.168.1.5:99999',
        'https://whowolf.de/join?room=1234&relay=abcd2345',
        'https://whowolf.de/join?room=1234&relay=ABCD2345&srv=wss://a.b',
        'https://whowolf.de/join?room=1234&relay=abcd2345&srv=https://a.b',
        'https://whowolf.de/join?room=1234&relay=abcd2345&srv=wss://a.b/x',
        'https://whowolf.de/join?room=1234&lan=192.168.1.5:1&x=1',
        'https://u:p@whowolf.de/join?room=1234&lan=192.168.1.5:1',
        'whatever',
        'https://whowolf.de/join?room=1234&lan=192.168.1.5:1#k=abc&s=def',
        'https://whowolf.de/join?room=1234&lan=192.168.1.5:1#x=1',
        // A server without the host's key and secret: could be anyone's.
        'https://whowolf.de/join?room=1234&relay=abcd2345&srv=wss://relay.example.org',
      ]) {
        expect(JoinLink.tryParse(raw), isNull, reason: raw);
      }
    });

    test('a host links to itself for the browser', () {
      final link = JoinLink(
        room: '1234',
        lan: const LanAddress('192.168.1.5', 47470),
        relayRoom: 'abcd2345',
        server: parseRelayServer('wss://relay.example.org'),
        hostKey: List.filled(32, 7),
        roomSecret: List.filled(32, 9),
      );
      final local = link.encodeLocal()!;
      expect(local, startsWith('http://192.168.1.5:47470/join?room=1234'));
      final back = JoinLink.tryParse(local)!;
      expect(back.lan.toString(), '192.168.1.5:47470');
      expect(back.hostKey, List.filled(32, 7));
      expect(back.relayRoom, 'abcd2345');
      // Without the key, or from anything but a private address: no.
      expect(
        const JoinLink(
          room: '1234',
          lan: LanAddress('192.168.1.5', 1),
        ).encodeLocal(),
        isNull,
      );
      final k =
          'k=${base64Url.encode(List.filled(32, 1))}'
          '&s=${base64Url.encode(List.filled(32, 2))}';
      for (final raw in [
        'http://192.168.1.5:47470/join?room=1234',
        'http://8.8.8.8:47470/join?room=1234#$k',
        'http://192.168.1.5:47470/other?room=1234#$k',
        'http://192.168.1.5:47470/join?room=1234&lan=10.0.0.1:1#$k',
        'https://192.168.1.5:47470/join?room=1234#$k',
        'http://u:p@192.168.1.5:47470/join?room=1234#$k',
      ]) {
        expect(JoinLink.tryParse(raw), isNull, reason: raw);
      }
      expect(
        JoinLink.tryParse('http://192.168.1.5:47470/join?room=1234#$k'),
        isNotNull,
      );
    });

    test('LAN addresses must be private', () {
      expect(LanAddress.tryParse('10.0.0.2')!.port, defaultLanPort);
      expect(LanAddress.tryParse('172.20.1.1:80')!.port, 80);
      expect(LanAddress.tryParse('172.32.1.1'), isNull);
      expect(LanAddress.tryParse('192.168.1'), isNull);
      expect(LanAddress.tryParse('localhost'), isNull);
    });
  });

  group('relay frames', () {
    test('round-trip', () {
      for (final f in <RelayFrame>[
        const RoomOpened('abcd2345'),
        const PeerJoined(3),
        const PeerData(3, '{"v":1,"type":"start"}'),
        const PeerLeft(3),
      ]) {
        expect(RelayFrame.parse(f.encode()).encode(), f.encode());
      }
    });

    test('invalid frames are refused', () {
      for (final raw in [
        '{"rv":1,"t":"room","room":"ABCDEFGH"}',
        '{"rv":2,"t":"join","peer":1}',
        '{"rv":1,"t":"data","peer":-1,"d":"x"}',
        '{"rv":1,"t":"nope"}',
      ]) {
        expect(() => RelayFrame.parse(raw), throwsA(isA<ProtocolError>()));
      }
    });
  });
}
