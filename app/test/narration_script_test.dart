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
    // Every line, unless a test asks for fewer.
    GameSettings settings = const GameSettings(
      narratorMode: NarratorMode.always,
    ),
    Faction? winner,
    PlayerId? shooter,
    List<PlayerId> runoff = const [],
  }) => PlayerView(
    you: ada,
    phase: phase,
    round: round,
    seats: [
      const SeatView(id: ada, name: 'Ada', isAlive: true),
      const SeatView(id: bo, name: 'Bo', isAlive: true),
      for (var i = 3; i < 7; i++)
        SeatView(id: PlayerId('p$i'), name: 'P$i', isAlive: true),
    ],
    deaths: deaths,
    waitingFor: 0,
    nightStep: step,
    settings: settings,
    winner: winner,
    shooter: shooter,
    runoff: runoff,
  );
  final classic = Preset.classic.settings.copyWith(
    narratorMode: NarratorMode.always,
  );
  List<String> keys(List<Spoken> spoken) => [for (final s in spoken) s.key];

  test('with big moments only, the narrator leaves the small lines to the '
      'screens; switched off it says nothing', () {
    const moments = GameSettings();
    const night1 = DeathView(
      player: bo,
      round: 1,
      cause: DeathCause.night,
      role: Role.seer,
    );
    final morning = view(
      Phase.day,
      1,
      deaths: const [night1],
      settings: moments,
    );
    final said = keys(
      spokenMoments(view(Phase.night, 1, settings: moments), morning),
    );
    expect(said, contains('died_one'));
    expect(said.where((k) => k.startsWith('morning')), hasLength(1));
    expect(said, isNot(contains('discuss')));
    expect(said, isNot(contains('role_seer')));
    expect(
      keys(spokenMoments(null, view(Phase.roleReveal, 0, settings: moments))),
      ['intro'],
    );
    // The called night still calls every role.
    final called = moments.copyWith(nightMode: NightMode.called);
    expect(
      keys(
        spokenMoments(
          view(Phase.night, 1, settings: called),
          view(Phase.night, 1, step: NightStep.inspect, settings: called),
        ),
      ),
      ['sleep', 'wake_seer'],
    );
    const off = GameSettings(narratorMode: NarratorMode.off);
    expect(
      spokenMoments(null, view(Phase.roleReveal, 0, settings: off)),
      isEmpty,
    );
  });

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

  test('the game opens with the intro, then the roles', () {
    expect(
      keys(spokenMoments(view(Phase.lobby, 0), view(Phase.roleReveal, 0))),
      ['intro', 'reveal'],
    );
  });

  test('towards the end the story speaks of the last nights', () {
    PlayerView few(Phase phase, int round) => PlayerView(
      you: ada,
      phase: phase,
      round: round,
      seats: [
        const SeatView(id: ada, name: 'Ada', isAlive: true),
        const SeatView(id: bo, name: 'Bo', isAlive: true),
        for (var i = 3; i < 7; i++)
          SeatView(id: PlayerId('p$i'), name: 'P$i', isAlive: false),
      ],
      deaths: const [],
      waitingFor: 0,
      settings: classic,
    );
    expect(
      keys(spokenMoments(few(Phase.night, 3), few(Phase.day, 3))),
      ['morning_late', 'died_none', 'discuss_late'],
    );
    expect(
      keys(spokenMoments(few(Phase.day, 3), few(Phase.vote, 3))),
      ['vote_late'],
    );
    expect(
      keys(spokenMoments(few(Phase.vote, 3), few(Phase.night, 4))).take(2),
      ['vote_tie', 'night_late'],
    );
  });

  test('the voice waits for the sounds that open a phase', () {
    expect(narratorLeadIn(view(Phase.vote, 1), view(Phase.night, 2)), 3800);
    expect(narratorLeadIn(view(Phase.night, 1), view(Phase.day, 1)), 4300);
    expect(
      narratorLeadIn(
        view(Phase.night, 1, settings: classic),
        view(Phase.night, 1, settings: classic, step: NightStep.inspect),
      ),
      700,
    );
  });

  test('story facts are public and name only what is true', () {
    expect(storyFacts(view(Phase.night, 1)), {'no_deaths', 'wolf'});
    const death = DeathView(player: bo, round: 1, cause: DeathCause.night);
    final later = view(
      Phase.day,
      2,
      deaths: const [death],
      settings: const GameSettings(werewolves: 2, roles: {Role.witch}),
    );
    expect(storyFacts(later), {'deaths', 'wolves', 'witch'});
  });

  test('a tie announces the runoff', () {
    expect(
      keys(
        spokenMoments(
          view(Phase.vote, 2),
          view(Phase.vote, 2, runoff: [ada, bo]),
        ),
      ),
      ['runoff'],
    );
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
      'intro',
      'reveal',
      'night_late',
      'morning_late',
      'discuss_late',
      'vote_late',
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
      'runoff',
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
    Set<String> only(Object? variant) => switch (variant) {
      final Map<String, Object?> v => {
        for (final f in v['if']! as List<Object?>) f! as String,
      },
      _ => const {},
    };
    // Every table these facts can describe.
    final tables = [
      for (final dead in ['deaths', 'no_deaths'])
        for (final wolves in ['wolves', 'wolf'])
          for (final witch in [true, false]) {dead, wolves, if (witch) 'witch'},
    ];
    for (final key in needed) {
      expect(moments, contains(key), reason: key);
      final m = moments[key]!;
      final de = m['de']! as List<Object?>;
      final en = m['en']! as List<Object?>;
      expect(de.length, en.length, reason: '$key: as many in both languages');
      for (var i = 0; i < de.length; i++) {
        expect(only(de[i]), only(en[i]), reason: '$key ${i + 1}: same facts');
        expect(knownFacts.containsAll(only(de[i])), isTrue, reason: key);
      }
      for (final facts in tables) {
        expect(
          de.where((v) => facts.containsAll(only(v))).length,
          greaterThanOrEqualTo(5),
          reason: '$key: at least five lines fit a table with $facts',
        );
      }
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
