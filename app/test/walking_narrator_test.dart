import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/src/game/narrator_walk.dart';
import 'package:whowolf/src/game/walking_narrator.dart';

class _Player implements ClipPlayer {
  _Player(this.log);
  final List<String> log;
  String? asset;
  final volumes = <double>[];
  bool started = false;
  bool stopped = false;

  @override
  Future<void> prepare(String asset, double volume) async {
    this.asset = asset;
    volumes.add(volume);
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
      'discuss': [(file: 'de/discuss_1_de.mp3', ms: 4000, only: <String>{})],
      'vote': [
        (file: 'de/vote_1_de.mp3', ms: 2000, only: <String>{}),
        (file: 'de/vote_2_de.mp3', ms: 2000, only: <String>{}),
      ],
    },
  });

  ({WalkingNarrator narrator, List<_Player> players, void Function(int) run})
  table() {
    var now = 0;
    final timers = <(int, void Function())>[];
    final players = <_Player>[];
    final log = <String>[];
    final narrator = WalkingNarrator(
      bank: bank,
      room: '4711',
      clock: () => now,
      player: () {
        final p = _Player(log);
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
          (file: 'de/died_one_1_de.mp3', ms: 1000, only: <String>{}),
        ],
        'role_seer': [
          (file: 'de/role_seer_1_de.mp3', ms: 1000, only: <String>{}),
        ],
        'discuss': [(file: 'de/discuss_1_de.mp3', ms: 1000, only: <String>{})],
        'sleep': [(file: 'de/sleep_1_de.mp3', ms: 1000, only: <String>{})],
        'wake_seer': [
          (file: 'de/wake_seer_1_de.mp3', ms: 1000, only: <String>{}),
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
      ))
        p.at,
    ];
    expect(starts(['died_one', 'role_seer', 'discuss']), [0, 1650, 3550]);
    expect(starts(['sleep', 'wake_seer']), [0, 2600]);
  });

  test('a line that names a detail plays only when it is true', () {
    const bank = VoiceBank({
      'de': {
        'night_called': [
          (file: 'de/a.mp3', ms: 1000, only: <String>{}),
          (file: 'de/b.mp3', ms: 1000, only: {'deaths'}),
          (file: 'de/c.mp3', ms: 1000, only: {'deaths', 'wolves'}),
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
}
