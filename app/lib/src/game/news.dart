import 'package:game_core/game_core.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/widgets.dart';

/// The deaths the table learns about in [view]'s phase, in the order they
/// happened (a victim, then a lover's grief, then the hunter's shot).
///
/// Deaths are recorded in order with their round. The morning reports the
/// night's round so far; after a vote (and in the hunter's moment or at the
/// end that may follow it) the news starts at the vote.
List<DeathView> freshDeaths(PlayerView view) {
  final round = view.phase == Phase.night ? view.round - 1 : view.round;
  final ofRound = [
    for (final d in view.deaths)
      if (d.round == round) d,
  ];
  if (view.phase == Phase.day) return ofRound;
  final vote = ofRound.indexWhere((d) => d.cause == DeathCause.vote);
  if (vote >= 0) return ofRound.sublist(vote);
  // No vote death: at night that means nobody was voted out; otherwise the
  // news is still the night's.
  return view.phase == Phase.night ? const [] : ofRound;
}

extension DeathText on AppLocalizations {
  /// One sentence about [death], e.g. "Mira did not wake up."
  String death(PlayerView view, DeathView death) {
    final name = view.nameOf(death.player);
    return switch (death.cause) {
      DeathCause.night => killedAtNight(name),
      DeathCause.vote => eliminated(name),
      DeathCause.heartbreak => diedOfGrief(name),
      DeathCause.shot => shotByHunter(name),
    };
  }

  /// What happened, for the narrator: every death with its role (if roles
  /// are revealed), or [nobody] if there was none.
  String news(PlayerView view, List<DeathView> deaths, String nobody) {
    if (deaths.isEmpty) return nobody;
    return [
      for (final d in deaths) ...[
        death(view, d),
        if (d.role != null) narrateRole(role(d.role!)),
      ],
    ].join(' ');
  }

  /// Who won, as the narrator says it.
  String winner(Faction? faction) => switch (faction) {
    Faction.werewolves => werewolvesWin,
    Faction.lovers => loversWin,
    Faction.village || null => villageWins,
  };
}
