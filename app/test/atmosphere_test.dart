import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/src/game/atmosphere.dart';

class _Ear implements Sounds {
  final heard = <Sound>[];

  @override
  void play(Sound sound) => heard.add(sound);

  @override
  void stopAll() {}
}

PlayerView _view(Phase phase, int round, {bool atmosphere = true}) =>
    PlayerView(
      you: const PlayerId('p1'),
      phase: phase,
      round: round,
      seats: const [SeatView(id: PlayerId('p1'), name: 'Ada', isAlive: true)],
      deaths: const [],
      waitingFor: 0,
      settings: GameSettings(atmosphere: atmosphere),
    );

void main() {
  test('every phone plans the same night, from public values only', () {
    // The signature takes only the room code and the round: no role or
    // night action can ever change what a phone plays.
    expect(nightCues('1234', 2), nightCues('1234', 2));
    expect(nightCues('1234', 2), isNot(nightCues('1234', 3)));
    final cues = nightCues('1234', 1);
    expect(cues.first, (sound: Sound.wind, at: Duration.zero));
    expect(cues.map((c) => c.sound), containsAll([Sound.crickets, Sound.owl]));
    expect(cues.every((c) => c.at < const Duration(seconds: 90)), isTrue);
  });

  group('the morning yawn', () {
    late _Ear ear;
    late List<void Function()> timers;
    Atmosphere atmosphere() {
      ear = _Ear();
      timers = [];
      return Atmosphere(
        room: '1234',
        sounds: ear,
        random: Random(1),
        startTimer: (_, callback) {
          timers.add(callback);
          return () => timers.remove(callback);
        },
      );
    }

    void fireAll() {
      for (final t in [...timers]) {
        t();
      }
    }

    test('comes when the night ends', () {
      atmosphere()
        ..update(_view(Phase.night, 1))
        ..update(_view(Phase.day, 1));
      fireAll();
      expect(ear.heard, [Sound.yawn]);
    });

    test('stays away when atmosphere is off or the phone is muted', () {
      atmosphere()
        ..update(_view(Phase.night, 1, atmosphere: false))
        ..update(_view(Phase.day, 1, atmosphere: false));
      fireAll();
      expect(ear.heard, isEmpty);

      atmosphere()
        ..muted = true
        ..update(_view(Phase.night, 1))
        ..update(_view(Phase.day, 1));
      fireAll();
      expect(ear.heard, isEmpty);
    });

    test('the night plays its cues, and they stop at dawn', () {
      final a = atmosphere()..update(_view(Phase.night, 1));
      expect(timers, hasLength(nightCues('1234', 1).length));
      a.update(_view(Phase.day, 1));
      expect(timers, hasLength(1)); // only the yawn is left
    });
  });
}
