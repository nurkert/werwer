import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart' show NarratorStage;
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

/// A pause between words every 1.3 s, like a narrator's sentences.
List<Pause> _pausesIn(int ms) => [
  for (var at = 1100; at + 400 < ms; at += 1300) (start: at, end: at + 320),
];

NarratorWalk _plan(
  String line, {
  int seats = 7,
  String room = '4711',
  int round = 2,
  int ms = 9000,
  int? start,
  int? to,
  List<Pause>? pauses,
  NarratorStage stage = NarratorStage.lively,
  bool night = false,
}) => NarratorWalk.plan(
  seats: seats,
  room: room,
  round: round,
  line: line,
  lengthMs: ms,
  start: start,
  to: to,
  pauses: pauses ?? _pausesIn(ms),
  stage: stage,
  night: night,
);

int _distance(int a, int b, int seats) {
  final d = (a - b).abs() % seats;
  return d > seats / 2 ? seats - d : d;
}

void main() {
  test('one phone at a time, two at most while handing over, and one '
      'always almost at full volume (never two at half)', () {
    for (final seats in [2, 3, 5, 8, 12]) {
      for (final line in _lines) {
        for (final room in ['1111', '2846', '9301']) {
          for (final stage in NarratorStage.values) {
            final walk = _plan(line, seats: seats, room: room, stage: stage);
            for (var ms = 0; ms <= 9000; ms += 7) {
              final gains = [
                for (var s = 0; s < seats; s++) walk.gainAt(s, ms),
              ];
              final playing = gains.where((g) => g > 0).length;
              final where = '$line, $seats seats, room $room, $ms ms';
              expect(playing, inInclusiveRange(1, 2), reason: where);
              final loudest = gains.reduce((a, b) => a > b ? a : b);
              expect(loudest, greaterThanOrEqualTo(0.9), reason: where);
            }
          }
        }
      }
    }
  });

  test('the voice changes phones only inside a pause between words', () {
    for (var round = 1; round < 30; round++) {
      for (final line in _lines) {
        final pauses = _pausesIn(9000);
        final walk = _plan(line, round: round, pauses: pauses);
        for (final stop in walk.stops.skip(1)) {
          final from = stop.at - stop.fade / 2;
          final until = stop.at + stop.fade / 2;
          expect(
            pauses.any((p) => p.start <= from && until <= p.end),
            isTrue,
            reason: '$line, round $round: a change at ${stop.at} ms',
          );
          expect(stop.fade, inInclusiveRange(60, 120));
        }
      }
    }
  });

  test('it stays a while at a phone before it moves on, longest when '
      'calm, and a line without pauses comes from one phone', () {
    for (var round = 1; round < 30; round++) {
      for (final line in _lines) {
        for (final stage in NarratorStage.values) {
          final walk = _plan(line, round: round, stage: stage);
          if (stage == NarratorStage.calm) {
            expect(walk.stops, hasLength(1), reason: '$line calm');
          }
          final dwell = NarratorWalk.dwellOf(stage);
          for (var i = 2; i < walk.stops.length; i++) {
            expect(
              walk.stops[i].at - walk.stops[i - 1].at,
              greaterThanOrEqualTo(dwell),
              reason: '$line ${stage.name}',
            );
          }
        }
        expect(
          _plan(line, round: round, pauses: const []).stops,
          hasLength(1),
        );
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
    expect(seen, containsAll(Gait.values));
    // Calls in the called night mostly stand still, never hurry.
    expect(byMood[Mood.call], isNot(contains(Gait.hurry)));
    // The night is restless, the morning calm.
    expect(byMood[Mood.tense], contains(Gait.hurry));
    expect(byMood[Mood.calm], isNot(contains(Gait.hurry)));
  });

  test('a stroll still goes seat by seat, a leap still crosses the table', () {
    for (var round = 1; round < 60; round++) {
      for (final line in ['night_called', 'win_village', 'intro']) {
        final walk = _plan(line, seats: 9, round: round);
        if (walk.gaits.length != 1) continue;
        final seats = walk.stops.map((s) => s.seat).toList();
        for (var i = 1; i < seats.length; i++) {
          final d = _distance(seats[i], seats[i - 1], 9);
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

  test('at night every call comes from the same seat of the moon', () {
    for (var round = 1; round < 20; round++) {
      final moon = moonSeat(seats: 7, room: '4711', round: round);
      for (final line in ['sleep', 'wake_wolves', 'wake_seer', 'night_late']) {
        final walk = _plan(line, round: round, night: true, start: 3);
        expect(walk.stops, [(seat: moon, at: 0, fade: 0)], reason: line);
      }
    }
    final moons = {
      for (var round = 1; round < 40; round++)
        moonSeat(seats: 7, room: '4711', round: round),
    };
    expect(moons.length, greaterThan(3), reason: 'a new place each night');
  });

  test('it walks up to someone whose fate is public in fewer than half '
      'the lines, and as often to someone else: an approach says nothing', () {
    var toTarget = 0;
    var approaches = 0;
    var lines = 0;
    for (var room = 1000; room < 1150; room++) {
      for (var round = 1; round < 9; round++) {
        lines++;
        final walk = _plan(
          'died_one',
          seats: 8,
          room: '$room',
          round: round,
          start: 1,
          to: 6,
        );
        if (walk.gaits.first != Gait.approach) continue;
        approaches++;
        if (walk.end == 6) toTarget++;
        // Straight there at the first pause it may take, and staying.
        expect(walk.stops, hasLength(2));
        expect(walk.gainAt(walk.end, 60000), 1);
      }
    }
    final share = toTarget / lines;
    expect(share, inInclusiveRange(0.4, 0.5), reason: 'approach share');
    expect(
      toTarget / approaches,
      lessThan(0.65),
      reason: 'many approaches go to someone else',
    );
  });

  test('between lines it moves on only sometimes, by the shorter way', () {
    var moved = 0;
    for (var round = 1; round <= 200; round++) {
      final to = NarratorWalk.relocate(
        seats: 8,
        room: '4711',
        round: round,
        line: 'discuss',
        occurrence: 0,
        from: 2,
        stage: NarratorStage.lively,
      );
      if (to == null) continue;
      moved++;
      expect(_distance(to, 2, 8), greaterThanOrEqualTo(2));
      final way = NarratorWalk.path(8, 2, to);
      expect(way.last, to);
      expect(way, hasLength(_distance(to, 2, 8)));
    }
    expect(moved, inInclusiveRange(40, 80));
    expect(
      NarratorWalk.relocate(
        seats: 8,
        room: '1',
        round: 1,
        line: 'discuss',
        occurrence: 0,
        from: 2,
        stage: NarratorStage.calm,
      ),
      isNull,
    );
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
