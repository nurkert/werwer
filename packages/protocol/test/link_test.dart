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

    test('a relay server links to its own page for the browser', () {
      final link = JoinLink(
        room: '1234',
        lan: const LanAddress('192.168.1.5', 47470),
        relayRoom: 'abcd2345',
        server: parseRelayServer('wss://play.example.org'),
        hostKey: List.filled(32, 7),
        roomSecret: List.filled(32, 9),
      );
      final page = link.encodeOnServer('0.2.0')!;
      expect(
        page,
        startsWith('https://play.example.org/v/$protocolVersion/0.2.0/join?'),
      );
      expect(page, isNot(contains('srv=')));
      final back = JoinLink.tryParse(page)!;
      // The server is the page's own origin.
      expect(back.server.toString(), 'wss://play.example.org');
      expect(back.relayRoom, 'abcd2345');
      expect(back.lan.toString(), '192.168.1.5:47470');
      expect(back.hostKey, List.filled(32, 7));
      // No page without a secure server, a relay room, the key or a sane
      // build.
      expect(link.encodeOnServer('../x'), isNull);
      expect(link.encodeOnServer(''), isNull);
      expect(
        JoinLink(
          room: '1234',
          relayRoom: 'abcd2345',
          server: parseRelayServer('ws://play.example.org'),
          hostKey: List.filled(32, 7),
          roomSecret: List.filled(32, 9),
        ).encodeOnServer('0.2.0'),
        isNull,
      );
      expect(
        JoinLink(
          room: '1234',
          lan: const LanAddress('192.168.1.5', 1),
          hostKey: List.filled(32, 7),
          roomSecret: List.filled(32, 9),
        ).encodeOnServer('0.2.0'),
        isNull,
      );
      final k =
          'k=${base64Url.encode(List.filled(32, 1))}'
          '&s=${base64Url.encode(List.filled(32, 2))}';
      for (final raw in [
        // Without the key: whoever serves the page could be anyone.
        'https://play.example.org/v/7/0.2.0/join?room=1234&relay=abcd2345',
        // Without a relay room, or naming another server.
        'https://play.example.org/v/7/0.2.0/join?room=1234#$k',
        'https://play.example.org/v/7/0.2.0/join?room=1234&relay=abcd2345&srv=wss://evil.example.org#$k',
        // Not plain https, or a path that is not a page.
        'http://play.example.org/v/7/0.2.0/join?room=1234&relay=abcd2345#$k',
        'https://play.example.org/v/7/../join?room=1234&relay=abcd2345#$k',
        'https://play.example.org/v/7/0.2.0/x/join?room=1234&relay=abcd2345#$k',
        'https://play.example.org/v/x/0.2.0/join?room=1234&relay=abcd2345#$k',
        'https://play.example.org/v/7/0.2.0/other?room=1234&relay=abcd2345#$k',
        'https://u:p@play.example.org/v/7/0.2.0/join?room=1234&relay=abcd2345#$k',
      ]) {
        expect(JoinLink.tryParse(raw), isNull, reason: raw);
      }
    });

    test('a browser page connects back to its own origin', () {
      final link = JoinLink(
        room: '1234',
        lan: const LanAddress('192.168.1.5', 47470),
        relayRoom: 'abcd2345',
        server: parseRelayServer('wss://elsewhere.example.org'),
        hostKey: List.filled(32, 7),
        roomSecret: List.filled(32, 9),
      );
      expect(
        pageSocket(Uri.parse('http://192.168.1.5:47470/join'), link).toString(),
        'ws://192.168.1.5:47470$hostSocketPath',
      );
      // From a server's page: that server, never the one named in the link.
      expect(
        pageSocket(
          Uri.parse('https://play.example.org/v/7/0.2.0/join'),
          link,
        ).toString(),
        'wss://play.example.org/join/abcd2345',
      );
      expect(
        pageSocket(
          Uri.parse('https://play.example.org/v/7/0.2.0/join'),
          const JoinLink(room: '1234', lan: LanAddress('192.168.1.5', 1)),
        ),
        isNull,
      );
      expect(pageSocket(Uri.parse('file:///join'), link), isNull);
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

  test('a seat code travels in the fragment, only with the key', () {
    final link = JoinLink(
      room: '1234',
      lan: const LanAddress('192.168.1.20', 47470),
      hostKey: List.filled(32, 1),
      roomSecret: List.filled(32, 2),
    ).withSeat('a1b2c3d4e5f60718293a4b5c6d7e8f90');
    final back = JoinLink.tryParse(link.encode())!;
    expect(back.seat, 'a1b2c3d4e5f60718293a4b5c6d7e8f90');
    expect(back.hostKey, List.filled(32, 1));
    // A bad code, or a code without the key, is no link.
    expect(
      JoinLink.tryParse(link.encode().replaceFirst('&h=a1b2', '&h=ZZ')),
      isNull,
    );
    expect(
      JoinLink.tryParse(
        'https://whowolf.de/join?room=1234&lan=192.168.1.20:47470'
        '#h=a1b2c3d4e5f60718293a4b5c6d7e8f90',
      ),
      isNull,
    );
  });

  test('a code page link carries the room but no key, and only there', () {
    const page =
        'https://play.example.org/v/12/0.3.0/join?room=1234&relay=abcd2345';
    final link = JoinLink.tryParseCodePage(page)!;
    expect(link.room, '1234');
    expect(link.relayRoom, 'abcd2345');
    expect(link.server, Uri.parse('wss://play.example.org'));
    expect(link.hostKey, isNull);
    expect(link.roomSecret, isNull);
    // A scanned code is never read this way: without the key a server's
    // page is refused, as before.
    expect(JoinLink.tryParse(page), isNull);
    for (final bad in [
      // Anything with a fragment is a QR code's page, read with tryParse.
      '$page#k=x',
      page.replaceFirst('https', 'http'),
      '$page&lan=192.168.1.5:47470',
      'https://play.example.org/v/12/0.3.0/join?room=12a4&relay=abcd2345',
      'https://play.example.org/v/12/0.3.0/join?room=1234&relay=ABCD2345',
      'https://play.example.org/v/12/0.3.0/join?room=1234',
      'https://play.example.org/join?room=1234&relay=abcd2345',
      'https://evil@play.example.org/v/12/0.3.0/join?room=1234&relay=abcd2345',
      '${page}x' * 20,
    ]) {
      expect(JoinLink.tryParseCodePage(bad), isNull, reason: bad);
    }
  });
}
