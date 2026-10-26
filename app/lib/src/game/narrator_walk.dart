import 'dart:math';

import 'package:game_core/game_core.dart' show stableHash;

/// How loud this phone plays the narrator at each moment while the voice
/// walks around the table: a pure function of public values, so every
/// phone computes the same walk and plays its part of it.
///
/// The narrator stands at a position on the circle of seats (seat `k` is at
/// position `k`) and moves on at [seatsPerSecond]. A phone is at full
/// volume while the narrator stands at its seat and hands over to the next
/// seat in a short crossfade ([handover] seats wide). Only during that
/// crossfade do two phones play at once, so small differences between their
/// clocks and speakers sound like a room, not like an echo.
class NarratorWalk {
  /// A walk around [seats] seats, starting at [start].
  ///
  /// With [to] the narrator walks to that seat (the shorter way round) and
  /// stays there, e.g. to whoever did not wake up; otherwise it keeps
  /// walking clockwise. Never pass a seat that depends on a secret.
  const NarratorWalk({
    required this.seats,
    required this.start,
    this.to,
    this.seatsPerSecond = 0.55,
    this.handover = 0.3,
  }) : assert(seats > 0, 'a table has seats');

  /// Where a walk starts: the same on every phone, from the room code and
  /// the moment (round and line), never from a role.
  factory NarratorWalk.forMoment({
    required int seats,
    required String room,
    required int round,
    required String line,
    int? to,
  }) {
    final hash = stableHash('$room/$round/$line');
    return NarratorWalk(seats: seats, start: hash % seats, to: to);
  }

  /// Seats at the table.
  final int seats;

  /// Where the narrator stands when the line begins.
  final int start;

  /// Where the narrator walks to, if anywhere in particular.
  final int? to;

  /// How fast the narrator walks.
  final double seatsPerSecond;

  /// How much of the way between two seats is a crossfade (0 to 1).
  final double handover;

  /// The narrator's position on the circle [ms] after the line began.
  double positionAt(int ms) {
    final walked = seatsPerSecond * ms / 1000;
    final target = to;
    if (target == null) return (start + walked) % seats;
    // The shorter way round, then standing still.
    var way = (target - start) % seats;
    if (way > seats / 2) way -= seats;
    final step = min(walked, way.abs().toDouble()) * way.sign;
    return (start + step) % seats;
  }

  /// This phone's volume (0 to 1) at [seat], [ms] after the line began.
  double gainAt(int seat, int ms) {
    if (seats == 1) return 1;
    final position = positionAt(ms);
    // Distance on the circle between the narrator and this seat.
    var distance = (position - seat).abs() % seats;
    distance = min(distance, seats - distance);
    // Full volume within its own stretch, a crossfade at the edges.
    final edge = 0.5 - handover / 2;
    if (distance <= edge) return 1;
    if (distance >= 0.5 + handover / 2) return 0;
    final t = (distance - edge) / handover;
    // Equal-power crossfade: the sum of both phones stays even.
    return cos(t * pi / 2);
  }

  /// When this [seat] has anything to play in a line of [lengthMs]: the
  /// stretches with a volume above zero, so silent phones need not start.
  List<({int from, int until})> activeFor(int seat, int lengthMs) {
    const step = 20;
    final spans = <({int from, int until})>[];
    int? from;
    for (var ms = 0; ms <= lengthMs; ms += step) {
      final on = gainAt(seat, ms) > 0;
      if (on && from == null) from = ms;
      if (!on && from != null) {
        spans.add((from: from, until: ms));
        from = null;
      }
    }
    if (from != null) spans.add((from: from, until: lengthMs));
    return spans;
  }
}
