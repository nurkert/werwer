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

PlayerView _view(
  Phase phase,
  int round, {
  bool atmosphere = true,
  int seats = 1,
  int dead = 0,
  Faction? winner,
}) => PlayerView(
  you: const PlayerId('p1'),
  phase: phase,
  round: round,
  seats: [
    for (var i = 0; i < seats; i++)
      SeatView(id: PlayerId('p${i + 1}'), name: 'P$i', isAlive: i >= dead),
  ],
  deaths: const [],
  waitingFor: 0,
  winner: winner,
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

  group('the night and the morning', () {
    late _Ear ear;
    late List<void Function()> timers;
    Atmosphere atmosphere() {
      ear = _Ear();
      timers = [];
      return Atmosphere(
        room: '1234',
        sounds: ear,
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

    test('night falls with the gong and a yawn, morning with the rooster '
        'and a yawn', () {
      atmosphere().update(_view(Phase.night, 1));
      expect(timers, hasLength(nightCues('1234', 1).length + 2));
      timers.first();
      expect(ear.heard, [Sound.night]);
      ear.heard.clear();
      atmosphere()
        ..update(_view(Phase.night, 1))
        ..update(_view(Phase.day, 1));
      fireAll();
      expect(ear.heard, [Sound.wake, Sound.yawn]);
    });

    test(
      'without atmosphere only the shared moments sound; muted, nothing',
      () {
        atmosphere()
          ..update(_view(Phase.night, 1, atmosphere: false))
          ..update(_view(Phase.day, 1, atmosphere: false));
        fireAll();
        expect(ear.heard, [Sound.wake]);

        atmosphere()
          ..muted = true
          ..update(_view(Phase.night, 1))
          ..update(_view(Phase.day, 1));
        fireAll();
        expect(ear.heard, isEmpty);
      },
    );

    test('the night plays its cues, and they stop at dawn', () {
      final a = atmosphere()..update(_view(Phase.night, 1));
      expect(timers, hasLength(nightCues('1234', 1).length + 2));
      a.update(_view(Phase.day, 1));
      expect(timers, hasLength(2)); // only the rooster and the yawn
    });

    test('the shared moments of a game', () {
      final a = atmosphere();
      // Time passes between the views: what is due has played.
      for (final view in [
        _view(Phase.lobby, 0, seats: 3),
        _view(Phase.lobby, 0, seats: 4),
        _view(Phase.roleReveal, 0, seats: 4),
        _view(Phase.day, 1, seats: 4),
        _view(Phase.vote, 1, seats: 4),
        _view(Phase.night, 2, seats: 4, dead: 1),
        _view(Phase.ended, 2, seats: 4, dead: 2, winner: Faction.werewolves),
      ]) {
        a.update(view);
        fireAll();
      }
      expect(
        ear.heard,
        containsAllInOrder([Sound.join, Sound.start, Sound.vote]),
      );
      expect(ear.heard.where((s) => s == Sound.death), hasLength(2));
      expect(ear.heard.last, Sound.howl);
    });

    test("a player's own sounds never play at night", () {
      final a = atmosphere()
        ..update(_view(Phase.day, 1))
        ..own(Sound.tap);
      expect(ear.heard, [Sound.tap]);
      a
        ..update(_view(Phase.night, 1))
        ..own(Sound.tap);
      expect(ear.heard, [Sound.tap]);
    });
  });
}
