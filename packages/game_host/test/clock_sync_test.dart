import 'dart:math';

import 'package:game_host/game_host.dart';
import 'package:test/test.dart';

void main() {
  test('finds the offset within a few milliseconds despite jitter', () {
    final random = Random(4);
    const offset = 123456; // the host is this far ahead
    final sync = ClockSync();
    var now = 1000000;
    for (var i = 0; i < 20; i++) {
      // Wi-Fi: 3-60 ms each way, rarely the same both ways.
      final there = 3 + random.nextInt(57);
      final back = 3 + random.nextInt(57);
      final sent = now;
      final hostAt = sent + there + offset;
      final received = sent + there + back;
      sync.add(sent: sent, hostAt: hostAt, received: received);
      now = received + 3000;
    }
    expect((sync.offset! - offset).abs(), lessThan(15));
    expect(sync.uncertainty, lessThan(30));
    expect(sync.toLocal(offset + 5000), closeTo(5000, 15));
  });

  test('ignores impossible or stale samples, and starts over on reset', () {
    final sync = ClockSync()
      ..add(sent: 100, hostAt: 50, received: 90)
      ..add(sent: 0, hostAt: 0, received: ClockSync.maxRoundTrip + 1);
    expect(sync.offset, isNull);
    sync.add(sent: 0, hostAt: 1010, received: 20);
    expect(sync.offset, 1000);
    sync.reset();
    expect(sync.offset, isNull);
  });
}
