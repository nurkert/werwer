import 'dart:math';

import 'package:game_core/game_core.dart' show stableHash;

/// How the narrator moves while saying one line.
enum Gait {
  /// Slowly round the table, one way or the other.
  stroll,

  /// Quickly round the table: the night falls, the vote is near.
  hurry,

  /// Back and forth across the table, a little further each time.
  zigzag,

  /// Straight across the table to someone far away, again and again.
  leap,

  /// At one seat for the whole line.
  stay,

  /// To someone whose fate is already public, then staying there.
  approach,
}

/// What a line does for the story, which decides how the narrator may
/// move: calm for the morning, restless for the night, still for news.
enum Mood { calm, tense, news, call, finale }

/// The mood of the script line [key] (tool/voice/script.json).
Mood moodOf(String key) {
  if (key.startsWith('win_')) return Mood.finale;
  if (key.startsWith('wake_')) return Mood.call;
  if (key.startsWith('role_') || key.startsWith('died_')) return Mood.news;
  return switch (key) {
    'voted_out' || 'vote_tie' || 'grief' || 'hunter' => Mood.news,
    'night_first_called' ||
    'night_called' ||
    'night_late' ||
    'night_together' ||
    'sleep' ||
    'vote' ||
    'vote_late' ||
    'runoff' ||
    'morning_late' ||
    'discuss_late' => Mood.tense,
    _ => Mood.calm,
  };
}

/// How likely each gait is in a mood ([Gait.approach] is decided apart).
const Map<Mood, Map<Gait, int>> _weights = {
  Mood.calm: {Gait.stroll: 5, Gait.zigzag: 2, Gait.leap: 1, Gait.stay: 2},
  Mood.tense: {Gait.hurry: 4, Gait.leap: 3, Gait.zigzag: 2, Gait.stroll: 1},
  Mood.news: {Gait.stay: 4, Gait.stroll: 2, Gait.leap: 1},
  Mood.call: {Gait.stay: 7, Gait.stroll: 2},
  Mood.finale: {Gait.leap: 4, Gait.hurry: 3, Gait.zigzag: 3},
};

/// A sequence of numbers from public values, the same on every platform
/// (Park–Miller: every product stays exact in a browser's doubles too).
class _Dice {
  _Dice(String seed) : _state = stableHash(seed) % 2147483646 + 1;

  int _state;

  /// A number from 0 (inclusive) to 1 (exclusive).
  double next() {
    _state = _state * 48271 % 2147483647;
    return (_state - 1) / 2147483646;
  }

  /// A whole number from 0 to [count] - 1.
  int below(int count) => min(count - 1, (next() * count).floor());

  /// A number between [from] and [to].
  double between(double from, double to) => from + (to - from) * next();

  T pick<T>(Map<T, int> weights) {
    final total = weights.values.fold(0, (a, b) => a + b);
    var roll = below(total);
    for (final MapEntry(:key, :value) in weights.entries) {
      if (roll < value) return key;
      roll -= value;
    }
    return weights.keys.last;
  }
}

/// The narrator arrives at `seat` at `at` ms into the line, handing over
/// from the seat before within `fade` ms around that moment.
typedef Stop = ({int seat, int at, int fade});

/// How loud each phone plays the narrator while it walks: a pure function
/// of public values (room, round, line, the speakers in seat order), so
/// every phone plans the same walk and plays its part of it. Never from a
/// role or a night action.
///
/// The walk is a list of [stops]. Between two stops one phone hands the
/// voice to the next: the next one rises before the last one falls, so at
/// every moment at least one phone plays at almost full volume (never two
/// at half), and never more than two play at once.
class NarratorWalk {
  /// A walk through [stops] at a table of [seats] speakers.
  NarratorWalk(this.seats, List<Stop> stops, {this.gaits = const []})
    : assert(seats > 0, 'a table has seats'),
      assert(stops.isNotEmpty, 'a walk starts somewhere'),
      stops = List.unmodifiable(stops);

  /// The voice at [seat] for the whole line.
  NarratorWalk.still(int seats, int seat)
    : this(seats, [(seat: seat, at: 0, fade: 0)]);

  /// Plans how the narrator walks through the line [line] of [lengthMs],
  /// said the [occurrence]-th time in [round] in [room]. It starts at
  /// [start] (where the last line ended) or at a seat from the dice.
  ///
  /// [to] is someone whose fate is public (the dead, the voted out, the
  /// hunter): the narrator goes there only sometimes, so going to someone
  /// is no pattern. Never pass a seat that depends on a secret.
  factory NarratorWalk.plan({
    required int seats,
    required String room,
    required int round,
    required String line,
    required int lengthMs,
    int occurrence = 0,
    int? start,
    int? to,
  }) {
    final dice = _Dice('$room/$round/$line/$occurrence');
    final first = start ?? dice.below(seats);
    if (seats == 1) return NarratorWalk.still(1, 0);
    final mood = moodOf(line);
    final gait = to != null && to != first && dice.next() < 0.5
        ? Gait.approach
        : dice.pick(_weights[mood]!);
    final stops = <Stop>[(seat: first, at: 0, fade: 0)];
    final gaits = [gait];
    // A long line may change its pace halfway, like a speaker would.
    final others = {
      for (final MapEntry(:key, :value) in _weights[mood]!.entries)
        if (key != gait && key != Gait.stay) key: value,
    };
    final split =
        gait != Gait.stay &&
            gait != Gait.approach &&
            others.isNotEmpty &&
            lengthMs > 6500
        ? (lengthMs * dice.between(0.45, 0.6)).round()
        : lengthMs;
    _walk(gait, stops, dice, seats, until: split, to: to);
    if (split < lengthMs) {
      final second = dice.pick(others);
      gaits.add(second);
      _walk(second, stops, dice, seats, until: lengthMs, from: split);
    }
    return NarratorWalk(seats, stops, gaits: gaits);
  }

  /// Adds the stops of [gait] from [from] until [until] ms.
  static void _walk(
    Gait gait,
    List<Stop> stops,
    _Dice dice,
    int seats, {
    required int until,
    int from = 0,
    int? to,
  }) {
    var seat = stops.last.seat;
    var at = from;
    void step(int next, int interval, int fade) {
      at += interval;
      if (at >= until) return;
      seat = next % seats;
      stops.add((seat: seat, at: at, fade: fade));
    }

    switch (gait) {
      case Gait.stroll || Gait.hurry:
        final dir = dice.next() < 0.5 ? 1 : -1;
        final speed = gait == Gait.stroll
            ? dice.between(0.35, 0.6)
            : dice.between(1, 1.6);
        final interval = (1000 / speed).round();
        final fade = min(900, (interval * 0.45).round());
        while (at + interval < until) {
          step(seat + dir, interval, fade);
        }
      case Gait.zigzag:
        if (seats < 4) {
          return _walk(Gait.stroll, stops, dice, seats, until: until, from: at);
        }
        final across = seats ~/ 2;
        final dir = dice.next() < 0.5 ? 1 : -1;
        final dwell = dice.between(1100, 1700).round();
        var home = seat;
        var far = false;
        while (at + dwell < until) {
          far = !far;
          if (!far) home += dir;
          step(far ? home + across : home, dwell, 380);
        }
      case Gait.leap:
        while (true) {
          final dwell = dice.between(1300, 2200).round();
          if (at + dwell >= until) break;
          // Somewhere at least a third of the table away.
          final reach = max(1, (seats / 3).ceil());
          final span = seats - 2 * reach + 1;
          final next = span <= 0
              ? seat + seats ~/ 2
              : seat + reach + dice.below(span);
          step(next, dwell, 420);
        }
      case Gait.stay:
        // Not where the last line ended: a seat of its own, from the dice.
        final next = dice.below(seats);
        if (next != seat && from + 600 < until) {
          stops.add((seat: next, at: from + 300, fade: 500));
        }
      case Gait.approach:
        final target = to!;
        var way = (target - seat) % seats;
        if (way > seats / 2) way -= seats;
        const interval = 800;
        for (var i = 0; i < way.abs(); i++) {
          step(seat + way.sign, interval, 360);
        }
    }
  }

  /// Speakers at the table.
  final int seats;

  /// Where the narrator is when (see [Stop]).
  final List<Stop> stops;

  /// The gaits of this walk, in order (for tests and debugging).
  final List<Gait> gaits;

  /// Where the line begins.
  int get start => stops.first.seat;

  /// Where the line ends (the next line goes on from here).
  int get end => stops.last.seat;

  /// How loud a phone that takes the voice over plays, [t] (0 to 1)
  /// through the handover; the one handing it over plays `_rise(1 - t)`.
  /// Both are above 0.96 in the middle: one phone is always almost at
  /// full volume.
  static double _rise(double t) =>
      sin(pi / 2 * min(1, max(0, t) / 0.6).toDouble());

  /// This phone's volume (0 to 1) at [seat], [ms] after the line began.
  double gainAt(int seat, int ms) {
    if (seats == 1) return 1;
    var k = 0;
    while (k + 1 < stops.length &&
        stops[k + 1].at - stops[k + 1].fade / 2 <= ms) {
      k++;
    }
    final stop = stops[k];
    if (k == 0 || stop.fade == 0) return seat == stop.seat ? 1 : 0;
    final t = (ms - (stop.at - stop.fade / 2)) / stop.fade;
    if (t >= 1) return seat == stop.seat ? 1 : 0;
    final before = stops[k - 1].seat;
    var gain = 0.0;
    if (seat == stop.seat) gain = max(gain, _rise(t));
    if (seat == before) gain = max(gain, _rise(1 - t));
    return gain;
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
