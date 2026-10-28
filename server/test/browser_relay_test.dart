@TestOn('browser')
library;

import 'dart:async';

import 'package:game_host/browser.dart';
import 'package:game_host/game_host.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

/// A player in a real browser reaches a host through the relay, the way a
/// page served by the relay connects (`pageSocket`), and gets their seat
/// back after a reload.
void main() {
  test(
    'a browser plays through the relay and comes back to its seat',
    () async {
      final hybrid = spawnHybridUri('browser_relay_hybrid.dart');
      final info = await hybrid.stream.first as Map<Object?, Object?>;
      final url = Uri.parse(
        'ws://127.0.0.1:${info['port']}/join/${info['room']}',
      );

      Future<PlayerLink> seat({String? token}) async {
        final seated = Completer<void>();
        late final PlayerLink link;
        link = PlayerLink(
          name: 'Ada',
          roomCode: '1357',
          token: token,
          dial: () => dialBrowser(url),
          onChange: () {
            if (!seated.isCompleted && link.view != null) seated.complete();
          },
        );
        await seated.future.timeout(const Duration(seconds: 10));
        return link;
      }

      final first = await seat();
      final you = first.you;
      final token = first.token;
      expect(you, isNotNull);
      expect(token, isNotNull);
      expect(first.view!.seats.map((s) => s.name), ['Ada']);

      // The tab is thrown away and reloaded: same token, same seat.
      first.close();
      final back = await seat(token: token);
      expect(back.you, you);
      expect(back.view!.seats, hasLength(1));
      back.close();

      // A page of another protocol version is never seated: the host does
      // not answer its hello, but does answer this version's right after.
      final raw = await dialBrowser(url);
      final answers = <HostMessage>[];
      raw.messages.listen((m) => answers.add(HostMessage.parse(m)));
      final hello = const Hello(name: 'Old', room: '1357', web: true).encode();
      raw.send(hello.replaceFirst('"v":$protocolVersion', '"v":7'));
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(answers, isEmpty);
      raw.send(hello);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(answers.whereType<Welcome>(), hasLength(1));
      await raw.close();
      await hybrid.sink.close();
    },
  );
}
