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
  final all = _allMoments(before, after);
  return switch (after.settings.narratorMode) {
    NarratorMode.off => const [],
    NarratorMode.always => all,
    NarratorMode.essential => [
      for (final m in all)
        if (isEssentialMoment(m.key)) m,
    ],
    NarratorMode.moments => [
      for (final m in all)
        if (isStoryMoment(m.key)) m,
    ],
  };
}

/// Whether the line [key] is needed to play at all, so the narrator says
/// it in [NarratorMode.essential]: nightfall, falling asleep, every call
/// and the village waking up. Who died, the vote and the end the screens
/// show.
bool isEssentialMoment(String key) =>
    key.startsWith('night_') ||
    key == 'sleep' ||
    key.startsWith('wake_') ||
    key.startsWith('morning');

/// Whether the line [key] carries the story, so the narrator says it in
/// [NarratorMode.moments]: the intro, nightfall, falling asleep and every
/// call of the called night (or nobody could play with closed eyes), the
/// news in the morning, the vote and its result, the hunter and the end.
/// The rest (the cards are dealt, discuss, the runoff, grief, a dead
/// player's role) the screens show.
bool isStoryMoment(String key) =>
    key == 'intro' ||
    key.startsWith('night_') ||
    key == 'sleep' ||
    key.startsWith('wake_') ||
    key.startsWith('morning') ||
    key.startsWith('died_') ||
    key == 'voted_out' ||
    key == 'vote_tie' ||
    key == 'vote' ||
    key == 'vote_late' ||
    key == 'hunter' ||
    key == 'shot' ||
    key == 'mayor' ||
    key.startsWith('win_');

List<Spoken> _allMoments(PlayerView? before, PlayerView after) {
  final called = after.settings.nightMode == NightMode.called;
  Spoken say(String key, [PlayerId? to]) => (key: key, to: to);
  final samePhase =
      before != null &&
      before.phase == after.phase &&
      before.round == after.round;
  final elected = after.mayor != null && before?.mayor != after.mayor
      ? say('mayor', after.mayor)
      : null;
  if (samePhase) {
    if (after.phase == Phase.vote &&
        before.runoff.isEmpty &&
        after.runoff.isNotEmpty) {
      return [say('runoff')];
    }
    if (called &&
        after.phase == Phase.night &&
        before.nightStep != after.nightStep) {
      return [say('sleep'), say(_wake(after.nightStep))];
    }
    // The village chose its mayor while it still talks.
    if (after.phase == Phase.day && elected != null) return [elected];
    return const [];
  }
  // Only what is new since the last screen: a death the narrator spoke of
  // before (in the morning, before the hunter's shot) is not told twice.
  final deaths = newDeaths(before, after);

  // The story tightens towards the end: once half the village is gone
  // (or only three are left) the narrator speaks of the last nights.
  final alive = after.seats.where((s) => s.isAlive).length;
  final late = alive * 2 <= after.seats.length || alive <= 3;
  String morning() => after.round == 1
      ? 'morning_first'
      : late
      ? 'morning_late'
      : 'morning';

  // What happened: the morning's news after a night, the verdict after a
  // vote, then every new death on its own (grief, the hunter's arrow) and
  // what the dead were. A hunter who is about to shoot is not told twice:
  // the hunter's line says who it was.
  final fromNight = before?.phase == Phase.night;
  final fromVote = before?.phase == Phase.vote;
  final aiming = after.phase == Phase.hunterShot ? after.shooter : null;
  final news = [
    if (fromNight) ...[
      say(morning()),
      switch (deaths.where((d) => d.cause == DeathCause.night).toList()) {
        [] => say('died_none'),
        [final one] => say('died_one', one.player),
        _ => say('died_two'),
      },
    ],
    if (fromVote)
      switch (deaths.where((d) => d.cause == DeathCause.vote).firstOrNull) {
        null => say('vote_tie'),
        final out => say('voted_out', out.player),
      },
    for (final d in deaths) ...[
      if (d.cause == DeathCause.heartbreak) say('grief', d.player),
      if (d.cause == DeathCause.shot) say('shot', d.player),
      if (d.role case final role? when d.player != aiming)
        say('role_${role.name}', d.player),
    ],
  ];

  return switch (after.phase) {
    Phase.lobby => const [],
    // The narrator sets the scene first (the owner may skip it).
    Phase.roleReveal => [say('intro'), say('reveal')],
    Phase.night => [
      ...news,
      if (called) ...[
        say(switch (after.round) {
          1 => 'night_first_called',
          _ when late => 'night_late',
          _ => 'night_called',
        }),
        say(_wake(after.nightStep)),
      ] else
        say('night_together'),
    ],
    Phase.day => [...news, say(late ? 'discuss_late' : 'discuss')],
    Phase.hunterShot => [...news, say('hunter', after.shooter)],
    Phase.vote => [?elected, say(late ? 'vote_late' : 'vote')],
    Phase.ended => [
      ...news,
      say(switch (after.winner) {
        Faction.werewolves => 'win_wolves',
        Faction.lovers => 'win_lovers',
        Faction.village || null => 'win_village',
      }),
    ],
  };
}

/// The deaths in [after] that [before] did not show yet, in the order
/// they happened. Without a [before] (this phone just came in) the
/// phase's own news, as far as it can tell.
List<DeathView> newDeaths(PlayerView? before, PlayerView after) {
  if (before == null) return freshDeaths(after);
  bool known(DeathView d) => before.deaths.any(
    (b) => b.player == d.player && b.round == d.round && b.cause == d.cause,
  );
  return [
    for (final d in after.deaths)
      if (!known(d)) d,
  ];
}

/// Whether the step from [before] to [after] starts a new clock on the
/// host (a phase, a called role, a runoff): the narrator then counts from
/// the shared start. Anything else (the mayor chosen mid-talk) is said
/// right away.
bool restartsClock(PlayerView? before, PlayerView after) =>
    before == null ||
    before.phase != after.phase ||
    before.round != after.round ||
    before.nightStep != after.nightStep ||
    before.runoff.isEmpty != after.runoff.isEmpty;

/// How long after the phase began the narrator starts speaking: after the
/// shared sounds that open it (the gong and the yawn at nightfall, the
/// rooster and the yawn in the morning, the bowl at the start, the bell
/// at the vote), so voice and sounds follow each other like one scene.
int narratorLeadIn(PlayerView? before, PlayerView after) {
  final samePhase =
      before != null &&
      before.phase == after.phase &&
      before.round == after.round;
  if (samePhase) return 700;
  return switch (after.phase) {
    Phase.night => 3800,
    Phase.day => 4300,
    Phase.hunterShot when before?.phase == Phase.night => 4300,
    Phase.roleReveal => 1600,
    Phase.vote => 1500,
    Phase.ended => 3400,
    _ => 700,
  };
}

/// The moments a death sound belongs before: the drum falls into the
/// pause just before the narrator says who is gone.
const deathMoments = {'died_one', 'died_two', 'voted_out', 'grief', 'shot'};

/// What the story may mention about this game, so that a line that names
/// a detail ("the village has grown smaller", "the werewolves wake") is
/// only said when it is true. Only public facts: the same on every phone,
/// and nothing a role or a night action could change unseen.
Set<String> storyFacts(PlayerView view) {
  // The wolves really dealt: the table may hold fewer than were asked for
  // (the lobby shows the fitted roles to everyone, so this is public).
  final count = view.seats.length;
  final fitted = view.settings.fittedFor(count);
  final wolves = fitted.werewolves ?? suggestedWerewolves(count);
  return {
    if (view.deaths.isEmpty) 'no_deaths' else 'deaths',
    if (wolves > 1) 'wolves' else 'wolf',
    if (fitted.roles.contains(Role.witch)) 'witch',
  };
}

/// Every fact a script line may depend on (`if` in tool/voice/script.json).
const knownFacts = {'deaths', 'no_deaths', 'wolves', 'wolf', 'witch'};

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
  return (stableHash('$room/$key') + round + occurrence) % count;
}
