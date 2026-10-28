import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:whowolf/src/app.dart';
import 'package:whowolf/src/net/app_links.dart';

void main() {
  final key =
      'k=${base64Url.encode(List.filled(32, 1))}'
      '&s=${base64Url.encode(List.filled(32, 2))}';
  final page = '/v/$protocolVersion/0.2.0/join?room=1234&relay=abcd2345#$key';

  test('only the official server pages with the key open a room', () {
    final link = joinLinkFromRoute(page)!;
    expect(link.room, '1234');
    expect(link.server.toString(), 'wss://play.whowolf.de');
    expect(joinLinkFromRoute('https://play.whowolf.de$page'), isNotNull);
    for (final route in [
      null,
      '/',
      // Another server, even with a valid page.
      'https://evil.example.org$page',
      // No key: anyone could have made it.
      '/v/$protocolVersion/0.2.0/join?room=1234&relay=abcd2345',
      // Not a room page.
      '/v/$protocolVersion/0.2.0/other?room=1234&relay=abcd2345#$key',
      '/join?room=1234&lan=192.168.1.5:1#$key',
      '/v/${'x' * 700}',
    ]) {
      expect(joinLinkFromRoute(route), isNull, reason: route);
    }
  });

  testWidgets('a link that starts the app reaches the start screen', (
    tester,
  ) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue = page;
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );
    incomingLink.value = null;
    final seen = <String?>[];
    void log() => seen.add(incomingLink.value?.room);
    incomingLink.addListener(log);
    addTearDown(() => incomingLink.removeListener(log));
    await tester.pumpWidget(const WhowolfApp(home: Text('start')));
    // The translations load first, then the navigator starts.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
    expect(find.text('start'), findsOneWidget);
    expect(seen, ['1234']);
    // No name yet: the link waits for the player.
    expect(incomingLink.value?.room, '1234');
  });
}
