import 'package:flutter_test/flutter_test.dart';
import 'package:whowolf/src/game/narrator_walk.dart';

void main() {
  test('the narrator walks round the table, one phone at a time', () {
    const walk = NarratorWalk(seats: 6, start: 2);
    expect(walk.gainAt(2, 0), 1);
    expect(walk.gainAt(3, 0), 0);
    expect(walk.gainAt(1, 0), 0);
    // After a while the next seat clockwise has the voice.
    final later = (1000 / walk.seatsPerSecond).round();
    expect(walk.gainAt(3, later), closeTo(1, 1e-3));
    expect(walk.gainAt(2, later), closeTo(0, 1e-3));
    // It goes all the way round.
    expect(walk.positionAt(later * 6), closeTo(2, 0.01));
  });

  test('at most two phones play at once, and the sound stays even', () {
    const walk = NarratorWalk(seats: 5, start: 0);
    for (var ms = 0; ms < 12000; ms += 37) {
      final gains = [for (var s = 0; s < 5; s++) walk.gainAt(s, ms)];
      final playing = gains.where((g) => g > 0).length;
      expect(playing, inInclusiveRange(1, 2), reason: '$ms ms');
      final power = gains.fold<double>(0, (sum, g) => sum + g * g);
      expect(power, closeTo(1, 0.02), reason: '$ms ms');
    }
  });

  test('it can walk to someone and stay there, the shorter way', () {
    const walk = NarratorWalk(seats: 8, start: 1, to: 7);
    // Two seats back is shorter than six forward.
    expect(walk.positionAt(1000), lessThan(1));
    final arrived = walk.positionAt(60000);
    expect(arrived, closeTo(7, 1e-9));
    expect(walk.gainAt(7, 60000), 1);
  });

  test('every phone plans the same walk from public values', () {
    NarratorWalk walk(String line) => NarratorWalk.forMoment(
      seats: 7,
      room: '4711',
      round: 2,
      line: line,
    );
    expect(walk('morning').start, walk('morning').start);
    expect(
      {
        for (final l in ['a', 'b', 'c', 'd', 'e', 'f']) walk(l).start,
      },
      hasLength(greaterThan(1)),
    );
  });

  test('silent phones know when they have nothing to play', () {
    const walk = NarratorWalk(seats: 6, start: 0);
    final spans = walk.activeFor(3, 3000);
    expect(spans, isEmpty);
    expect(walk.activeFor(0, 3000), isNotEmpty);
    expect(const NarratorWalk(seats: 1, start: 0).gainAt(0, 5000), 1);
  });
}
