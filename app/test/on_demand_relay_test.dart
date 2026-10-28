import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:whowolf/src/net/on_demand_relay.dart';

void main() {
  test('on the Wi-Fi the room stays off the server until it is needed', () {
    expect(
      OnDemandRelay.rightAway(always: false, offline: false),
      isFalse,
    );
    expect(OnDemandRelay.rightAway(always: true, offline: false), isTrue);
    expect(OnDemandRelay.rightAway(always: false, offline: true), isTrue);
  });

  test('opens the server room once, also when asked twice at once', () async {
    var connects = 0;
    final pending = Completer<String?>();
    final relay = OnDemandRelay<String>(() {
      connects++;
      return pending.future;
    });
    expect(relay.relay, isNull);
    expect(connects, 0);
    // Two quick taps on "Show QR code".
    final first = relay.open();
    final second = relay.open();
    pending.complete('abcd2345');
    expect(await first, 'abcd2345');
    expect(await second, 'abcd2345');
    expect(await relay.open(), 'abcd2345');
    expect(connects, 1);
  });

  test('a failed attempt can be tried again', () async {
    var connects = 0;
    final relay = OnDemandRelay<String>(() async {
      connects++;
      return connects == 1 ? null : 'abcd2345';
    });
    expect(await relay.open(), isNull);
    expect(await relay.open(), 'abcd2345');
    expect(connects, 2);
  });
}
