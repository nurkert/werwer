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
    final start = NarratorWalk.forMoment(
      seats: 4,
      room: '4711',
      round: 1,
      line: 'discuss',
    ).start;
    final t = table();
    t.narrator.speak(
      moments: const [(key: 'discuss', to: null)],
      language: NarratorLanguage.de,
      round: 1,
      startMs: 1000,
      seats: seats,
      me: seats[start],
    );
    await Future<void>.delayed(Duration.zero);
    t.run(999);
    expect(t.players.single.started, isFalse);
    t.run(1000);
    expect(t.players.single.started, isTrue);
    expect(t.players.single.asset, 'voice/de/discuss_1_de.mp3');
    t.run(6000);
    final volumes = t.players.single.volumes;
    expect(volumes.first, 1);
    // The voice walks on: it fades out here before the clip ends.
    expect(volumes.last, lessThan(1));
    expect(t.players.single.stopped, isTrue);
  });

  test('a phone the voice never reaches plays nothing at all', () async {
    final start = NarratorWalk.forMoment(
      seats: 4,
      room: '4711',
      round: 1,
      line: 'vote',
    ).start;
    final t = table();
    t.narrator.speak(
      moments: const [(key: 'vote', to: null)],
      language: NarratorLanguage.de,
      round: 1,
      startMs: 500,
      seats: seats,
      me: seats[(start + 2) % 4],
    );
    t.run(5000);
    expect(t.players, isEmpty);
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
        seats: seats,
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
    final start = NarratorWalk.forMoment(
      seats: 4,
      room: '4711',
      round: 1,
      line: 'discuss',
    ).start;
    final t = table();
    t.run(5000);
    final planned = t.narrator.speak(
      moments: const [(key: 'discuss', to: null)],
      language: NarratorLanguage.de,
      round: 1,
      startMs: 4000,
      seats: seats,
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
      seats: seats,
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
      seats: seats,
      me: seats.first,
    );
    expect(t.players, isEmpty);
  });
}
