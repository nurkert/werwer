import 'package:flutter_test/flutter_test.dart';
import 'package:whowolf/src/game/narrator_walk.dart';

/// Every line of the script, as the walk sees them.
const _lines = [
  'intro',
  'reveal',
  'night_first_called',
  'night_called',
  'night_together',
  'sleep',
  'wake_wolves',
  'wake_seer',
  'morning_first',
  'morning',
  'died_one',
  'role_seer',
  'discuss',
  'vote',
  'voted_out',
  'hunter',
  'win_village',
];

NarratorWalk _plan(
  String line, {
  int seats = 7,
  String room = '4711',
  int round = 2,
  int ms = 9000,
  int? start,
  int? to,
}) => NarratorWalk.plan(
  seats: seats,
  room: room,
  round: round,
  line: line,
  lengthMs: ms,
  start: start,
  to: to,
);

void main() {
  test('one phone at a time, two at most while handing over, and one '
      'always almost at full volume (never two at half)', () {
    for (final seats in [2, 3, 5, 8, 12]) {
      for (final line in _lines) {
        for (final room in ['1111', '2846', '9301']) {
          final walk = _plan(line, seats: seats, room: room);
          for (var ms = 0; ms <= 9000; ms += 23) {
            final gains = [for (var s = 0; s < seats; s++) walk.gainAt(s, ms)];
            final playing = gains.where((g) => g > 0).length;
            final where = '$line, $seats seats, room $room, $ms ms';
            expect(playing, inInclusiveRange(1, 2), reason: where);
            final loudest = gains.reduce((a, b) => a > b ? a : b);
            expect(loudest, greaterThanOrEqualTo(0.95), reason: where);
          }
        }
      }
    }
  });

  test('every phone plans the same walk from public values', () {
    for (final line in _lines) {
      final a = _plan(line);
      final b = _plan(line);
      expect(a.stops, b.stops, reason: line);
      expect(a.gaits, b.gaits, reason: line);
    }
  });

  test('the narrator has many ways to move, chosen by the moment', () {
    final seen = <Gait>{};
    final byMood = <Mood, Set<Gait>>{};
    for (var round = 1; round < 40; round++) {
      for (final line in _lines) {
        final walk = _plan(line, round: round);
        seen.addAll(walk.gaits);
        byMood.putIfAbsent(moodOf(line), () => {}).addAll(walk.gaits);
      }
    }
    expect(seen, containsAll(Gait.values.where((g) => g != Gait.approach)));
    // Calls in the called night mostly stand still, never hurry.
    expect(byMood[Mood.call], isNot(contains(Gait.hurry)));
    // The night is restless, the morning calm.
    expect(byMood[Mood.tense], contains(Gait.hurry));
    expect(byMood[Mood.calm], isNot(contains(Gait.hurry)));
  });

  test('a long line may change its pace halfway', () {
    final changes = [
      for (var round = 1; round < 30; round++)
        for (final line in ['intro', 'night_called', 'win_village'])
          _plan(line, round: round, ms: 12000).gaits.length,
    ];
    expect(changes, contains(2));
    expect(
      [
        for (var r = 1; r < 30; r++) _plan('vote', round: r, ms: 3000).gaits,
      ].every((g) => g.length == 1),
      isTrue,
      reason: 'short lines keep one pace',
    );
  });

  test('it goes to someone whose fate is public only sometimes, the '
      'shorter way, and stays', () {
    var went = 0;
    for (var round = 1; round <= 40; round++) {
      final walk = _plan('died_one', seats: 8, round: round, start: 1, to: 7);
      if (walk.gaits.first != Gait.approach) continue;
      went++;
      // Two seats back is shorter than six forward.
      expect(walk.stops.map((s) => s.seat), [1, 0, 7]);
      expect(walk.gainAt(7, 60000), 1);
    }
    expect(went, inInclusiveRange(8, 32), reason: 'no pattern either way');
  });

  test('a call in the called night does not stay where the last line '
      'ended', () {
    final starts = <int>{};
    final ends = <int>{};
    for (var round = 1; round < 30; round++) {
      final walk = _plan('wake_wolves', round: round, start: 0, ms: 3000);
      starts.add(walk.start);
      ends.add(walk.end);
    }
    expect(starts, {0});
    expect(ends.length, greaterThan(3), reason: 'it moves to many seats');
  });

  test('a leap crosses the table, a zigzag goes back and forth', () {
    for (var round = 1; round < 60; round++) {
      for (final line in ['night_called', 'win_village', 'intro']) {
        final walk = _plan(line, seats: 9, round: round);
        if (walk.gaits.length != 1) continue;
        final seats = walk.stops.map((s) => s.seat).toList();
        for (var i = 1; i < seats.length; i++) {
          var d = (seats[i] - seats[i - 1]).abs() % 9;
          if (d > 4) d = 9 - d;
          switch (walk.gaits.single) {
            case Gait.leap:
              expect(d, greaterThanOrEqualTo(3), reason: '$line $round');
            case Gait.stroll || Gait.hurry:
              expect(d, 1, reason: '$line $round');
            case _:
              break;
          }
        }
      }
    }
  });

  test('silent phones know when they have nothing to play', () {
    final walk = NarratorWalk.still(6, 0);
    expect(walk.activeFor(3, 3000), isEmpty);
    expect(walk.activeFor(0, 3000), isNotEmpty);
    expect(
      NarratorWalk.plan(
        seats: 1,
        room: '1',
        round: 1,
        line: 'vote',
        lengthMs: 5000,
      ).gainAt(0, 2500),
      1,
    );
  });
}
