import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

/// Limits must survive JavaScript: shifts there are 32 bit (`1 << 40` is 0
/// in a browser), and numbers above 2^53 are not exact.
void main() {
  test('limits are exact, positive numbers on every platform', () {
    for (final limit in [maxSeq, maxClock, maxEpoch, maxCustody]) {
      expect(limit, greaterThan(40000));
      expect(limit, lessThan(9007199254740992)); // 2^53
    }
    expect(maxSeq, 1099511627776);
    expect(maxClock, 1125899906842624);
  });

  test('a real clock value passes', () {
    final now = DateTime.now().millisecondsSinceEpoch;
    expect(now, lessThan(maxClock));
    final pong =
        HostMessage.parse(Pong(3, echo: now, at: now).encode()) as Pong;
    expect(pong.at, now);
  });
}
