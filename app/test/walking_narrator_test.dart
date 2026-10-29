import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/src/game/narrator_walk.dart';
import 'package:whowolf/src/game/walking_narrator.dart';

class _Player implements ClipPlayer {
  _Player(this.log, [this.loading]);
  final List<String> log;

  /// Loading takes until this completes (a first play, a slow browser).
  final Future<void>? loading;
  String? asset;
  final volumes = <double>[];
  bool started = false;
  bool stopped = false;

  @override
  Future<void> prepare(String asset, double volume) async {
    this.asset = asset;
    volumes.add(volume);
    await loading;
  }

  @override
  void start() {
    started = true;
    log.add('start $asset');
  }

  @override
  void volume(double volume) => volumes.add(volume);

  @override
  void stop() => stopped = true;
}

void main() {
  const seats = [PlayerId('a'), PlayerId('b'), PlayerId('c'), PlayerId('d')];

  /// Where the walk of [line] begins at this table (the first line said).
  int startOf(String line, {int ms = 4000}) => NarratorWalk.plan(
    seats: seats.length,
    room: '4711',
    round: 1,
    line: line,
    lengthMs: ms,
  ).start;
  const bank = VoiceBank({
    'de': {
      'discuss': [
        (
          file: 'de/discuss_1_de.mp3',
          ms: 4000,
          only: <String>{},
          pauses: <Pause>[],
        ),
      ],
      'vote': [
        (
          file: 'de/vote_1_de.mp3',
          ms: 2000,
          only: <String>{},
          pauses: <Pause>[],
        ),
        (
          file: 'de/vote_2_de.mp3',
          ms: 2000,
          only: <String>{},
          pauses: <Pause>[],
        ),
      ],
    },
  });

  ({WalkingNarrator narrator, List<_Player> players, void Function(int) run})
  table({Future<void>? loading}) {
    var now = 0;
    final timers = <(int, void Function())>[];
    final players = <_Player>[];
    final log = <String>[];
    final narrator = WalkingNarrator(
      bank: bank,
      room: '4711',
      clock: () => now,
      player: () {
        final p = _Player(log, loading);
        players.add(p);
        return p;
      },
      startTimer: (after, callback) {
        final entry = (now + after.inMilliseconds, callback);
        timers.add(entry);
        return () => timers.remove(entry);
      },
    );
    void run(int until) {
      while (true) {
        timers.sort((a, b) => a.$1.compareTo(b.$1));
        final next = timers.firstOrNull;
        if (next == null || next.$1 > until) break;
        timers.remove(next);
        now = next.$1;
        next.$2();
      }
      now = until;
    }

    return (narrator: narrator, players: players, run: run);
  }

  test('the phone where the walk begins plays, at the shared moment', () async {
    final start = startOf('discuss');
    final t = table();
    t.narrator.speak(
      moments: const [(key: 'discuss', to: null)],
      language: NarratorLanguage.de,
      round: 1,
      startMs: 1000,
      speakers: seats,
      me: seats[start],
    );
    await Future<void>.delayed(Duration.zero);
    t.run(999);
    expect(t.players.single.started, isFalse);
    t.run(1000);
    expect(t.players.single.started, isTrue);
    expect(t.players.single.asset, 'voice/de/discuss_1_de.mp3');
    t.run(6000);
    expect(t.players.single.volumes.first, 1);
    expect(t.players.single.stopped, isTrue);
  });

  test('a clip still loading when it is due begins a moment late, never '
      'not at all; past the grace it would run into the next line', () async {
    final start = startOf('discuss');
    for (final (loadedAt, plays) in [(1300, true), (1700, false)]) {
      final loaded = Completer<void>();
      final t = table(loading: loaded.future);
      t.narrator.speak(
        moments: const [(key: 'discuss', to: null)],
        language: NarratorLanguage.de,
        round: 1,
        startMs: 1000,
        speakers: seats,
        me: seats[start],
      );
      t.run(loadedAt);
      expect(t.players.single.started, isFalse);
      loaded.complete();
      await Future<void>.delayed(Duration.zero);
      t.run(loadedAt + 50);
      expect(t.players.single.started, plays, reason: 'loaded at $loadedAt');
      if (plays) {
        // It plays to its own end, counted from its late start.
        t.run(loadedAt + 3900);
        expect(t.players.single.stopped, isFalse);
        t.run(loadedAt + 4100);
      }
      expect(t.players.single.stopped, isTrue);
    }
  });

  test('queued moments wait for what is still being said', () async {
    final t = table();
    t.narrator.speak(
      moments: const [(key: 'discuss', to: null)],
      language: NarratorLanguage.de,
      round: 1,
      startMs: 1000,
      speakers: seats,
      me: seats.first,
      stage: NarratorStage.calm,
    );
    t.run(2000);
    final planned = t.narrator.speak(
      moments: const [(key: 'vote', to: null)],
      language: NarratorLanguage.de,
      round: 1,
      startMs: 2000,
      speakers: seats,
      me: seats.first,
      queued: true,
      stage: NarratorStage.calm,
    );
    // After the 4 s line that began at 1000, and a breath.
    expect(planned.single.at, 5000 + WalkingNarrator.gap('', 'vote'));
    expect(t.players.where((p) => p.stopped), isEmpty);
  });

  test('a phone the voice never reaches plays nothing at all', () async {
    const eight = [
      PlayerId('a'),
      PlayerId('b'),
      PlayerId('c'),
      PlayerId('d'),
      PlayerId('e'),
      PlayerId('f'),
      PlayerId('g'),
      PlayerId('h'),
    ];
    final walk = NarratorWalk.plan(
      seats: eight.length,
      room: '4711',
      round: 1,
      line: 'vote',
      lengthMs: 2000,
    );
    final idle = [
      for (var s = 0; s < eight.length; s++)
        if (walk.activeFor(s, 2000).isEmpty) s,
    ];
    expect(idle, isNotEmpty);
    final t = table();
    t.narrator.speak(
      moments: const [(key: 'vote', to: null)],
      language: NarratorLanguage.de,
      round: 1,
      startMs: 500,
      speakers: eight,
      me: eight[idle.first],
    );
    t.run(5000);
    expect(t.players, isEmpty);
  });

  test('a phone that is not a speaker never plays the voice', () {
    final t = table();
    t.narrator.speak(
      moments: const [(key: 'discuss', to: null)],
      language: NarratorLanguage.de,
      round: 1,
      startMs: 0,
      speakers: const [PlayerId('a')],
      me: const PlayerId('b'),
    );
    t.run(9000);
    expect(t.players, isEmpty);
  });

  test('nothing runs past the end of the phase', () {
    final t = table();
    final planned = t.narrator.plan(
      moments: const [
        (key: 'vote', to: null),
        (key: 'discuss', to: null),
      ],
      language: NarratorLanguage.de,
      round: 1,
      startMs: 0,
      speakers: seats,
      deadlineMs: 3000,
    );
    expect(planned.map((p) => p.key), ['vote']);
  });

  test('pauses like one speaker: short within a thought, long between '
      'roles', () {
    const many = VoiceBank({
      'de': {
        'died_one': [
          (
            file: 'de/died_one_1_de.mp3',
            ms: 1000,
            only: <String>{},
            pauses: <Pause>[],
          ),
        ],
        'role_seer': [
          (
            file: 'de/role_seer_1_de.mp3',
            ms: 1000,
            only: <String>{},
            pauses: <Pause>[],
          ),
        ],
        'discuss': [
          (
            file: 'de/discuss_1_de.mp3',
            ms: 1000,
            only: <String>{},
            pauses: <Pause>[],
          ),
        ],
        'sleep': [
          (
            file: 'de/sleep_1_de.mp3',
            ms: 1000,
            only: <String>{},
            pauses: <Pause>[],
          ),
        ],
        'wake_seer': [
          (
            file: 'de/wake_seer_1_de.mp3',
            ms: 1000,
            only: <String>{},
            pauses: <Pause>[],
          ),
        ],
      },
    });
    final narrator = WalkingNarrator(bank: many, room: '1');
    List<int> starts(List<String> keys) => [
      for (final p in narrator.plan(
        moments: [for (final k in keys) (key: k, to: null)],
        language: NarratorLanguage.de,
        round: 1,
        startMs: 0,
        speakers: seats,
        // Standing still: no walk between the lines to wait for.
        stage: NarratorStage.calm,
      ))
        p.at,
    ];
    expect(starts(['died_one', 'role_seer', 'discuss']), [0, 1650, 3500]);
    // Time to close the eyes before the next role is woken.
    expect(starts(['sleep', 'wake_seer']), [0, 2800]);
  });

  test('a line that names a detail plays only when it is true', () {
    const bank = VoiceBank({
      'de': {
        'night_called': [
          (file: 'de/a.mp3', ms: 1000, only: <String>{}, pauses: <Pause>[]),
          (file: 'de/b.mp3', ms: 1000, only: {'deaths'}, pauses: <Pause>[]),
          (
            file: 'de/c.mp3',
            ms: 1000,
            only: {'deaths', 'wolves'},
            pauses: <Pause>[],
          ),
        ],
      },
    });
    List<String> files(Set<String> facts) => [
      for (final c in bank.variants(
        NarratorLanguage.de,
        'night_called',
        facts: facts,
      ))
        c.file,
    ];
    expect(files({'no_deaths', 'wolves'}), ['de/a.mp3']);
    expect(files({'deaths', 'wolf'}), ['de/a.mp3', 'de/b.mp3']);
    expect(files({'deaths', 'wolves'}), ['de/a.mp3', 'de/b.mp3', 'de/c.mp3']);
  });

  test('a moment that should have begun already stays silent', () {
    final start = startOf('discuss');
    final t = table();
    t.run(5000);
    final planned = t.narrator.speak(
      moments: const [(key: 'discuss', to: null)],
      language: NarratorLanguage.de,
      round: 1,
      startMs: 4000,
      speakers: seats,
      me: seats[start],
    );
    expect(planned.single.at, 4000);
    t.run(9000);
    expect(t.players, isEmpty);
  });

  test('without recordings in a language, the narrator stays silent', () {
    final t = table();
    expect(bank.speaks(NarratorLanguage.en), isFalse);
    t.narrator.speak(
      moments: const [(key: 'discuss', to: null)],
      language: NarratorLanguage.en,
      round: 1,
      startMs: 0,
      speakers: seats,
      me: seats.first,
    );
    t.run(9000);
    expect(t.players, isEmpty);
  });

  test('muted, or stopped, means silent', () async {
    final t = table();
    t.narrator.muted = true;
    t.narrator.speak(
      moments: const [(key: 'discuss', to: null)],
      language: NarratorLanguage.de,
      round: 1,
      startMs: 0,
      speakers: seats,
      me: seats.first,
    );
    expect(t.players, isEmpty);
  });

  group('a phone drops out in the middle', () {
    const moments = [(key: 'discuss', to: null), (key: 'vote', to: null)];
    final me = seats[startOf('discuss')];

    List<Planned> speak(
      WalkingNarrator narrator,
      List<PlayerId> speakers, {
      bool goingOn = false,
    }) => narrator.speak(
      moments: moments,
      language: NarratorLanguage.de,
      round: 1,
      startMs: 1000,
      speakers: speakers,
      me: me,
      goingOn: goingOn,
    );

    test('what is being said goes on; what is to come moves to the phones '
        'still there', () async {
      final t = table();
      speak(t.narrator, seats);
      await Future<void>.delayed(Duration.zero);
      t.run(2000);
      final saying = t.players.firstWhere((p) => p.started);
      expect(saying.asset, 'voice/de/discuss_1_de.mp3');
      // Everyone else is gone: this phone says the rest alone.
      speak(t.narrator, [me], goingOn: true);
      await Future<void>.delayed(Duration.zero);
      expect(saying.stopped, isFalse, reason: 'not cut off mid-sentence');
      t.run(20000);
      expect(
        t.players.where((p) => p.started).map((p) => p.asset),
        contains(startsWith('voice/de/vote_')),
      );
      // Nothing said twice.
      expect(
        t.players.where((p) => p.started && p.asset == saying.asset),
        hasLength(1),
      );
    });

    test('a phone that goes silent ends its sentence and says nothing '
        'more', () async {
      final t = table();
      speak(t.narrator, seats);
      await Future<void>.delayed(Duration.zero);
      t.run(2000);
      final others = [
        for (final s in seats)
          if (s != me) s,
      ];
      speak(t.narrator, others, goingOn: true);
      t.run(20000);
      expect(
        t.players.where((p) => p.started).map((p) => p.asset),
        ['voice/de/discuss_1_de.mp3'],
      );
    });
  });

  test('the recordings carry the pauses between their words', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final bank = await VoiceBank.load();
    final intro = bank.variants(NarratorLanguage.de, 'intro');
    expect(intro, isNotEmpty);
    for (final clip in intro) {
      expect(clip.pauses, isNotEmpty, reason: clip.file);
      for (final p in clip.pauses) {
        expect(p.end - p.start, greaterThanOrEqualTo(250));
        expect(p.end, lessThan(clip.ms));
      }
    }
  });

  group('between lines', () {
    const talk = VoiceBank({
      'de': {
        'discuss': [
          (file: 'de/d.mp3', ms: 3000, only: <String>{}, pauses: <Pause>[]),
        ],
        'vote': [
          (file: 'de/v.mp3', ms: 3000, only: <String>{}, pauses: <Pause>[]),
        ],
        'voted_out': [
          (file: 'de/o.mp3', ms: 3000, only: <String>{}, pauses: <Pause>[]),
        ],
      },
    });
    const eight = [
      PlayerId('a'),
      PlayerId('b'),
      PlayerId('c'),
      PlayerId('d'),
      PlayerId('e'),
      PlayerId('f'),
      PlayerId('g'),
      PlayerId('h'),
    ];
    const lines = [
      (key: 'discuss', to: null),
      (key: 'vote', to: null),
      (key: 'voted_out', to: null),
    ];
    List<Planned> plan(int round, {bool night = false}) =>
        WalkingNarrator(bank: talk, room: '4711').plan(
          moments: lines,
          language: NarratorLanguage.de,
          round: round,
          startMs: 0,
          speakers: eight,
          stage: NarratorStage.theater,
          night: night,
        );

    test('by day the narrator walks to the next line, a footstep on every '
        'phone it passes, and speaks once it has arrived', () {
      var walked = 0;
      for (var round = 1; round < 30; round++) {
        final planned = plan(round);
        for (var i = 1; i < planned.length; i++) {
          final steps = planned[i].steps;
          if (steps.isEmpty) {
            expect(planned[i].walk.start, planned[i - 1].walk.end);
            continue;
          }
          walked++;
          expect(
            steps.map((s) => s.seat),
            NarratorWalk.path(
              8,
              planned[i - 1].walk.end,
              planned[i].walk.start,
            ),
          );
          for (var k = 1; k < steps.length; k++) {
            expect(steps[k].at - steps[k - 1].at, WalkingNarrator.stepMs);
          }
          expect(steps.first.at, greaterThan(planned[i - 1].at));
          expect(planned[i].at, greaterThan(steps.last.at));
        }
      }
      expect(walked, greaterThan(5));
    });

    test('at night nobody hears steps, and every line comes from the moon', () {
      for (var round = 1; round < 30; round++) {
        final moon = moonSeat(seats: 8, room: '4711', round: round);
        for (final p in plan(round, night: true)) {
          expect(p.steps, isEmpty);
          expect(p.walk.stops, [(seat: moon, at: 0, fade: 0)]);
        }
      }
    });

    test('a phone the narrator passes plays its footstep, softly', () async {
      final round = [
        for (var r = 1; r < 30; r++)
          if (plan(r).any((p) => p.steps.isNotEmpty)) r,
      ].first;
      final step = plan(round).expand((p) => p.steps).first;
      var now = 0;
      final timers = <(int, void Function())>[];
      final players = <_Player>[];
      final log = <String>[];
      WalkingNarrator(
        bank: talk,
        room: '4711',
        clock: () => now,
        player: () => _addPlayer(players, log),
        startTimer: (after, callback) {
          final entry = (now + after.inMilliseconds, callback);
          timers.add(entry);
          return () => timers.remove(entry);
        },
      ).speak(
        moments: lines,
        language: NarratorLanguage.de,
        round: round,
        startMs: 0,
        speakers: eight,
        me: eight[step.seat],
        stage: NarratorStage.theater,
      );
      await Future<void>.delayed(Duration.zero);
      while (timers.isNotEmpty) {
        timers.sort((a, b) => a.$1.compareTo(b.$1));
        final next = timers.removeAt(0);
        now = next.$1;
        next.$2();
        if (now > step.at) break;
      }
      final foot = players.firstWhere(
        (p) => (p.asset ?? '').startsWith('sounds/steps/'),
      );
      expect(foot.started, isTrue);
      expect(foot.volumes.first, WalkingNarrator.stepVolume);
    });
  });
}

_Player _addPlayer(List<_Player> players, List<String> log) {
  final p = _Player(log);
  players.add(p);
  return p;
}
