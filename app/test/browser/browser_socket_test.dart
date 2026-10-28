@TestOn('browser')
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:web/web.dart' as web;
import 'package:whowolf/src/net/browser_socket.dart';

/// In a real browser: a page served by a relay under `/v/<protocol>/<build>/`
/// forgets the key from the address but keeps its own path, and after a
/// reload this tab finds its seat again; another room never mixes in.
void main() {
  final key =
      'k=${base64Url.encode(List.filled(32, 1))}'
      '&s=${base64Url.encode(List.filled(32, 2))}';
  const page = '/v/$protocolVersion/0.2.0/join';

  test('a reload under the server page path returns to the table', () {
    web.window.history.replaceState(
      null,
      '',
      '$page?room=1234&relay=abcd2345#$key',
    );
    final link = JoinLink.tryParse(
      'https://play.example.org$page?room=1234&relay=abcd2345#$key',
    )!;
    forgetPageLink();
    // The key is gone from the address bar; the page's path stays, so a
    // reload loads the same page again.
    expect(web.window.location.pathname, page);
    expect(web.window.location.hash, isEmpty);
    expect(web.window.location.search, isEmpty);

    rememberGame(link, token: 'T' * 43, name: 'Ada');
    // After the reload the address has no link: this tab's game comes back.
    final back = recallGame()!;
    expect(back.link.room, '1234');
    expect(back.link.relayRoom, 'abcd2345');
    expect(back.token, 'T' * 43);
    expect(back.name, 'Ada');
    // A second scan of the same room finds the same seat.
    expect(recallGame(link)?.token, 'T' * 43);

    // Another room with the same code but another host is another game.
    final other = JoinLink.tryParse(
      'https://play.example.org$page?room=1234&relay=abcd2345'
      '#k=${base64Url.encode(List.filled(32, 3))}'
      '&s=${base64Url.encode(List.filled(32, 2))}',
    )!;
    expect(recallGame(other), isNull);

    forgetGame(link);
    expect(recallGame(link), isNull);
    expect(web.window.localStorage.getItem('whowolf.games'), '{}');
  });
}
