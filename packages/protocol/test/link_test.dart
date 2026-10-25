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
      );
      final back = JoinLink.tryParse(link.encode())!;
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
      ]) {
        expect(JoinLink.tryParse(raw), isNull, reason: raw);
      }
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
