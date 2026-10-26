import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_host/game_host.dart';
import 'package:whowolf/src/net/dial.dart';

void main() {
  test('the first path that answers wins, the others are closed', () async {
    final memory = MemoryTransport();
    memory.connections.listen((_) {});
    final slow = Completer<Connection>();
    final winner = await firstConnection([
      () => Future.error(StateError('wifi gone')),
      () async => memory.connect(),
      () => slow.future,
    ]);
    expect(winner, isNotNull);
    // A late success is closed instead of leaking.
    final late = memory.connect();
    var closed = false;
    late.messages.listen((_) {}, onDone: () => closed = true);
    slow.complete(late);
    await Future<void>.delayed(Duration.zero);
    expect(closed, isTrue);
  });

  test('it fails only when every path fails', () async {
    await expectLater(
      firstConnection([
        () => Future.error(StateError('a')),
        () => Future.error(StateError('b')),
      ]),
      throwsA(isA<StateError>()),
    );
    await expectLater(firstConnection([]), throwsA(isA<StateError>()));
  });
}
