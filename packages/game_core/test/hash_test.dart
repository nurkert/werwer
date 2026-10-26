import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

/// Every phone, app or browser, must make the same public choices.
void main() {
  test('the stable hash is FNV-1a, the same on the VM and in browsers', () {
    expect(stableHash(''), 2166136261);
    expect(stableHash('a'), 0xe40c292c);
    expect(stableHash('1234/1/wake_wolves'), 3323605163);
    expect(stableHash('4711/discuss'), 445211231);
    expect(stableHash('1234/2'), 229536300);
  });
}
