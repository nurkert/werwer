import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/l10n/app_localizations_de.dart';
import 'package:whowolf/src/game/narrator.dart';
import 'package:whowolf/src/game/news.dart';

void main() {
  final l10n = AppLocalizationsDe();
  const seats = [
    SeatView(id: PlayerId('p1'), name: 'Ada', isAlive: true),
    SeatView(id: PlayerId('p2'), name: 'Bo', isAlive: false, role: Role.seer),
  ];
  PlayerView view(
    Phase phase,
    int round, {
    List<DeathView> deaths = const [],
  }) => PlayerView(
    you: const PlayerId('p1'),
    phase: phase,
    round: round,
    seats: seats,
    deaths: deaths,
    waitingFor: 0,
  );
  const night1 = DeathView(
    player: PlayerId('p2'),
    round: 1,
    cause: DeathCause.night,
    role: Role.seer,
  );

  test('announces each phase once', () {
    final night = view(Phase.night, 1);
    expect(
      narration(view(Phase.roleReveal, 0), night, l10n),
      contains('Nacht'),
    );
    expect(narration(night, night, l10n), isNull);
  });

  test('the morning names the victim and the revealed role', () {
    final line = narration(
      view(Phase.night, 1),
      view(Phase.day, 1, deaths: [night1]),
      l10n,
    )!;
    expect(line, contains('Bo ist nicht mehr aufgewacht.'));
    expect(line, contains('Seherin'));
  });

  test('the night after a vote first tells the result', () {
    final line = narration(view(Phase.vote, 1), view(Phase.night, 2), l10n)!;
    expect(line, startsWith('Niemand wurde verbannt.'));
  });

  test('the end names the winner', () {
    const ended = PlayerView(
      you: PlayerId('p1'),
      phase: Phase.ended,
      round: 1,
      seats: seats,
      deaths: [night1],
      waitingFor: 0,
      winner: Faction.werewolves,
    );
    expect(
      narration(view(Phase.night, 1), ended, l10n),
      endsWith('Die Werwölfe gewinnen!'),
    );
  });

  group('fresh news', () {
    const seats3 = [
      ...seats,
      SeatView(id: PlayerId('p3'), name: 'Cem', isAlive: false),
    ];
    PlayerView at(Phase phase, int round, List<DeathView> deaths) => PlayerView(
      you: const PlayerId('p1'),
      phase: phase,
      round: round,
      seats: seats3,
      deaths: deaths,
      waitingFor: 0,
    );
    const voted = DeathView(
      player: PlayerId('p3'),
      round: 1,
      cause: DeathCause.vote,
    );
    const grief = DeathView(
      player: PlayerId('p2'),
      round: 1,
      cause: DeathCause.heartbreak,
    );

    test('the morning reports the night, the next night the vote', () {
      expect(freshDeaths(at(Phase.day, 1, [night1])), [night1]);
      expect(freshDeaths(at(Phase.night, 2, [voted, grief])), [voted, grief]);
      // The night's victims are old news after the vote.
      expect(freshDeaths(at(Phase.night, 2, [night1, voted])), [voted]);
      expect(freshDeaths(at(Phase.night, 2, [night1])), isEmpty);
    });

    test('a death chain is told in order, with grief', () {
      final line = narration(
        at(Phase.vote, 1, const []),
        at(Phase.night, 2, [voted, grief]),
        l10n,
      )!;
      expect(line, contains('verbannt'));
      expect(line, contains('Kummer'));
      expect(line.indexOf('verbannt'), lessThan(line.indexOf('Kummer')));
    });

    test('the end names the lovers when they win', () {
      const ended = PlayerView(
        you: PlayerId('p1'),
        phase: Phase.ended,
        round: 2,
        seats: seats3,
        deaths: [],
        waitingFor: 0,
        winner: Faction.lovers,
      );
      expect(
        narration(at(Phase.vote, 2, const []), ended, l10n),
        contains(
          'Liebespaar',
        ),
      );
    });
  });
}
