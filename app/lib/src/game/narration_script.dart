import 'package:game_core/game_core.dart';
import 'package:whowolf/src/game/news.dart';

/// One spoken moment of the narrator's script (tool/voice/script.json),
/// and the seat the narrator walks to while saying it, if any.
typedef Spoken = ({String key, PlayerId? to});

/// What the narrator says when the game moves from [before] to [after]:
/// the moments of the script, in order. Built only from what every player
/// sees, so all phones say the same; and the narrator only ever walks to
/// someone whose fate is public (the dead, the voted out, the hunter).
List<Spoken> spokenMoments(PlayerView? before, PlayerView after) {
  final called = after.settings.nightMode == NightMode.called;
  Spoken say(String key, [PlayerId? to]) => (key: key, to: to);
  final samePhase =
      before != null &&
      before.phase == after.phase &&
      before.round == after.round;
  if (samePhase) {
    if (called &&
        after.phase == Phase.night &&
        before.nightStep != after.nightStep) {
      return [say('sleep'), say(_wake(after.nightStep))];
    }
    return const [];
  }
  final deaths = freshDeaths(after);
  List<Spoken> news({bool morning = false}) {
    final night = deaths.where((d) => d.cause != DeathCause.vote).toList();
    final died = [
      if (morning)
        switch (night.where((d) => d.cause == DeathCause.night).length) {
          0 => say('died_none'),
          1 => say(
            'died_one',
            night.firstWhere((d) => d.cause == DeathCause.night).player,
          ),
          _ => say('died_two'),
        },
    ];
    return [
      ...died,
      for (final d in deaths) ...[
        if (d.cause == DeathCause.heartbreak) say('grief', d.player),
        if (d.role case final role?) say('role_${role.name}', d.player),
      ],
    ];
  }

  final fromVote =
      before?.phase == Phase.vote || before?.phase == Phase.hunterShot;
  final voted = deaths.where((d) => d.cause == DeathCause.vote).firstOrNull;

  return switch (after.phase) {
    Phase.lobby => const [],
    Phase.roleReveal => [say('reveal')],
    Phase.night => [
      if (fromVote) ...[
        if (voted == null) say('vote_tie') else say('voted_out', voted.player),
        ...news(),
      ],
      if (called) ...[
        say(after.round == 1 ? 'night_first_called' : 'night_called'),
        say(_wake(after.nightStep)),
      ] else
        say('night_together'),
    ],
    Phase.day => [
      say(after.round == 1 ? 'morning_first' : 'morning'),
      ...news(morning: true),
      say('discuss'),
    ],
    Phase.hunterShot => [
      if (before?.phase == Phase.night) ...[
        say(after.round == 1 ? 'morning_first' : 'morning'),
        ...news(morning: true),
      ] else
        ...news(),
      say('hunter', after.shooter),
    ],
    Phase.vote => [say('vote')],
    Phase.ended => [
      ...news(morning: before?.phase == Phase.night),
      say(switch (after.winner) {
        Faction.werewolves => 'win_wolves',
        Faction.lovers => 'win_lovers',
        Faction.village || null => 'win_village',
      }),
    ],
  };
}

String _wake(NightStep step) => switch (step) {
  NightStep.link => 'wake_cupid',
  NightStep.hunt => 'wake_wolves',
  NightStep.inspect => 'wake_seer',
  NightStep.brew => 'wake_witch',
};

/// Which of a moment's [count] recorded variants to play: the same on every
/// phone (from the room and the round), never the same one in two rounds
/// running, and different for a moment said twice in one round
/// ([occurrence]).
int pickVariant({
  required String room,
  required int round,
  required String key,
  required int count,
  int occurrence = 0,
}) {
  if (count <= 1) return 0;
  var hash = 0x811c9dc5;
  for (final unit in '$room/$key'.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }
  return (hash + round + occurrence) % count;
}
