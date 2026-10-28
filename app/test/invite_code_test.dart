import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:whowolf/src/net/invite_code.dart';

void main() {
  final online = JoinLink(
    room: '1234',
    lan: const LanAddress('192.168.1.5', 47470),
    relayRoom: 'abcd2345',
    server: parseRelayServer('wss://play.example.org'),
    hostKey: List.filled(32, 7),
    roomSecret: List.filled(32, 9),
  );
  final offline = JoinLink(
    room: '1234',
    lan: const LanAddress('192.168.1.5', 47470),
    hostKey: List.filled(32, 7),
    roomSecret: List.filled(32, 9),
  );

  test('one code for everyone once the room is on a server with the page', () {
    final code = inviteCode(
      online,
      serverHasBuild: true,
      servesWebApp: true,
      build: '0.2.0',
    );
    expect(code, startsWith('https://play.example.org/v/'));
    expect(JoinLink.tryParse(code)!.lan.toString(), '192.168.1.5:47470');
  });

  test('the Wi-Fi code when the host asks for it or the server lacks it', () {
    for (final code in [
      inviteCode(
        online,
        serverHasBuild: true,
        servesWebApp: true,
        build: '0.2.0',
        localOnly: true,
      ),
      inviteCode(online, serverHasBuild: false, servesWebApp: true),
      inviteCode(offline, serverHasBuild: false, servesWebApp: true),
    ]) {
      expect(code, startsWith('http://192.168.1.5:47470/join'));
    }
  });

  test('the app link alone when the host serves no page', () {
    final code = inviteCode(
      offline,
      serverHasBuild: false,
      servesWebApp: false,
    );
    expect(code, startsWith('https://whowolf.de/join'));
    expect(
      inviteCode(
        online,
        serverHasBuild: true,
        servesWebApp: false,
        build: '0.2.0',
        localOnly: true,
      ),
      startsWith('https://whowolf.de/join'),
    );
  });
}
