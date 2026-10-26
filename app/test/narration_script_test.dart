import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/src/game/narration_script.dart';

void main() {
  const ada = PlayerId('p1');
  const bo = PlayerId('p2');
  PlayerView view(
    Phase phase,
    int round, {
    NightStep step = NightStep.hunt,
    List<DeathView> deaths = const [],
    GameSettings settings = const GameSettings(),
    Faction? winner,
    PlayerId? shooter,
  }) => PlayerView(
    you: ada,
    phase: phase,
    round: round,
    seats: const [
      SeatView(id: ada, name: 'Ada', isAlive: true),
      SeatView(id: bo, name: 'Bo', isAlive: true),
    ],
    deaths: deaths,
    waitingFor: 0,
    nightStep: step,
    settings: settings,
    winner: winner,
    shooter: shooter,
  );
  final classic = Preset.classic.settings;
  List<String> keys(List<Spoken> spoken) => [for (final s in spoken) s.key];

  test('the classic night: the first night, then one role after another', () {
    final first = spokenMoments(
      view(Phase.roleReveal, 0, settings: classic),
      view(Phase.night, 1, settings: classic),
    );
    expect(keys(first), ['night_first_called', 'wake_wolves']);
    final next = spokenMoments(
      view(Phase.night, 1, settings: classic),
      view(Phase.night, 1, settings: classic, step: NightStep.inspect),
    );
    expect(keys(next), ['sleep', 'wake_seer']);
    expect(
      keys(
        spokenMoments(
          view(Phase.vote, 1, settings: classic),
          view(Phase.night, 2, settings: classic),
        ),
      ),
      ['vote_tie', 'night_called', 'wake_wolves'],
    );
  });

  test('the morning names nobody but walks to whoever died', () {
    const death = DeathView(
      player: bo,
      round: 1,
      cause: DeathCause.night,
      role: Role.seer,
    );
    final morning = spokenMoments(
      view(Phase.night, 1),
      view(Phase.day, 1, deaths: const [death]),
    );
    expect(keys(morning), [
      'morning_first',
      'died_one',
      'role_seer',
      'discuss',
    ]);
    expect(morning[1].to, bo);
    expect(
      keys(spokenMoments(view(Phase.night, 2), view(Phase.day, 2))),
      ['morning', 'died_none', 'discuss'],
    );
  });

  test('a vote result walks to the one voted out', () {
    const out = DeathView(player: bo, round: 2, cause: DeathCause.vote);
    final spoken = spokenMoments(
      view(Phase.vote, 2),
      view(Phase.night, 3, deaths: const [out]),
    );
    expect(spoken.first, (key: 'voted_out', to: bo));
    expect(spoken.last.key, 'night_together');
  });

  test('the end names the winner', () {
    final end = spokenMoments(
      view(Phase.vote, 3),
      view(Phase.ended, 3, winner: Faction.werewolves),
    );
    expect(end.last.key, 'win_wolves');
  });

  test('every moment the app can say is in the script, in both languages', () {
    final script =
        jsonDecode(File('../tool/voice/script.json').readAsStringSync())
            as Map<String, Object?>;
    final moments = {
      for (final m in script['moments']! as List<Object?>)
        (m! as Map<String, Object?>)['key']! as String:
            m as Map<String, Object?>,
    };
    final needed = {
      'reveal',
      'night_first_called',
      'night_called',
      'night_together',
      'sleep',
      'morning_first',
      'morning',
      'died_one',
      'died_two',
      'died_none',
      'grief',
      'discuss',
      'vote',
      'voted_out',
      'vote_tie',
      'hunter',
      'win_village',
      'win_wolves',
      'win_lovers',
      for (final step in NightStep.values)
        keys(
          spokenMoments(
            view(Phase.night, 1, settings: classic),
            view(Phase.night, 1, settings: classic, step: step),
          ),
        ).lastOrNull,
      for (final role in Role.values) 'role_${role.name}',
    }.nonNulls;
    for (final key in needed) {
      expect(moments, contains(key), reason: key);
      final m = moments[key]!;
      expect(
        (m['de']! as List).length,
        (m['en']! as List).length,
        reason: '$key: as many variants in both languages',
      );
    }
  });

  test('variants: the same everywhere, never twice in a row', () {
    int pick(int round, {int occurrence = 0}) => pickVariant(
      room: '4711',
      round: round,
      key: 'discuss',
      count: 4,
      occurrence: occurrence,
    );
    expect(pick(3), pick(3));
    for (var round = 1; round < 12; round++) {
      expect(pick(round), isNot(pick(round + 1)));
    }
    expect(pick(2), isNot(pick(2, occurrence: 1)));
    expect(
      pickVariant(room: '1', round: 9, key: 'x', count: 1),
      0,
    );
  });
}
