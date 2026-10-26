import 'package:game_core/src/actions.dart';
import 'package:game_core/src/model.dart';
import 'package:game_core/src/role.dart';
import 'package:game_core/src/rules.dart';
import 'package:game_core/src/settings.dart';

/// A seat at the table as one viewer sees it.
class SeatView {
  /// Creates a seat view.
  const SeatView({
    required this.id,
    required this.name,
    required this.isAlive,
    this.persona = Persona.farmer,
    this.role,
  });

  /// The player's id.
  final PlayerId id;

  /// The player's name.
  final String name;

  /// Whether the player is alive.
  final bool isAlive;

  /// The character the player appears as.
  final Persona persona;

  /// The player's role, only if the viewer may know it.
  final Role? role;
}

/// A death as one viewer sees it.
class DeathView {
  /// Creates a death view.
  const DeathView({
    required this.player,
    required this.round,
    required this.cause,
    this.role,
  });

  /// Who died.
  final PlayerId player;

  /// In which round.
  final int round;

  /// How.
  final DeathCause cause;

  /// Their role, if revealed.
  final Role? role;
}

/// Everything one player may know about the game, and nothing more. This is
/// all a client ever receives.
class PlayerView {
  /// Creates a player view.
  const PlayerView({
    required this.you,
    required this.phase,
    required this.round,
    required this.seats,
    required this.deaths,
    required this.waitingFor,
    this.settings = const GameSettings(),
    this.yourRole,
    this.youConfirmed = false,
    this.nightStep = NightStep.hunt,
    this.yourNightTask,
    this.yourNightTargets = const [],
    this.youActed = false,
    this.yourVote,
    this.youVoted = false,
    this.packChoices = const {},
    this.seerResults = const [],
    this.lastNightSheep = const {},
    this.dreams = const {},
    this.yourFlock,
    this.yourDoorSign,
    this.packMark,
    this.couple = const [],
    this.victim,
    this.potions = const {},
    this.shooter,
    this.winner,
  });

  /// The viewer.
  final PlayerId you;

  /// Current phase.
  final Phase phase;

  /// Current round.
  final int round;

  /// Everyone at the table in seating order.
  final List<SeatView> seats;

  /// Deaths so far, oldest first.
  final List<DeathView> deaths;

  /// How many living players still have to act in this phase (or night
  /// step).
  final int waitingFor;

  /// The game's settings (everyone sees them).
  final GameSettings settings;

  /// The viewer's own role, once dealt.
  final Role? yourRole;

  /// Whether the viewer confirmed their role.
  final bool youConfirmed;

  /// The current step of the night.
  final NightStep nightStep;

  /// At night: what the viewer is asked to do in this step (their own
  /// ability or a decoy); `null` for the dead and outside the night.
  final NightAbility? yourNightTask;

  /// Whom the viewer picked in this night step (empty for a witch who
  /// keeps her potions).
  final List<PlayerId> yourNightTargets;

  /// Whether the viewer has acted in this night step.
  final bool youActed;

  /// Whom the viewer picked first in this night step.
  PlayerId? get yourNightChoice => yourNightTargets.firstOrNull;

  /// Whom the viewer voted for (`null` with [youVoted] means abstained).
  final PlayerId? yourVote;

  /// Whether the viewer has voted in the current vote.
  final bool youVoted;

  /// For werewolves: tonight's pick of each living werewolf.
  final Map<PlayerId, PlayerId> packChoices;

  /// For the seer: everything seen so far.
  final List<SeerResult> seerResults;

  /// Sheep each player counted last night (public in the morning).
  final Map<PlayerId, int> lastNightSheep;

  /// Dream points per player over the whole game (public).
  final Map<PlayerId, int> dreams;

  /// At night: how many sheep run across the viewer's meadow.
  final int? yourFlock;

  /// At night, with [GameSettings.doorSigns]: the sign on the viewer's own
  /// door ([doorSignLength] symbols). Nobody ever sees another's sign.
  final List<int>? yourDoorSign;

  /// For living werewolves: tonight's door sign attempt of the pack, and
  /// whether the sign was right.
  final DoorMark? packMark;

  /// The two lovers, for the lovers themselves and cupid (and for
  /// everyone once the game is over); empty otherwise.
  final List<PlayerId> couple;

  /// For the witch in her night step: tonight's victim of the werewolves
  /// (`null` if they did not agree).
  final PlayerId? victim;

  /// For the witch: her potions still unused.
  final Set<Potion> potions;

  /// In [Phase.hunterShot]: the dead hunter who takes aim (public).
  final PlayerId? shooter;

  /// The winning faction once the game is over.
  final Faction? winner;

  /// The viewer's lover, if they are in love.
  PlayerId? get partner =>
      couple.contains(you) ? couple.where((p) => p != you).firstOrNull : null;

  /// The viewer's own seat.
  SeatView get yourSeat => seats.firstWhere((s) => s.id == you);
}

/// What [viewer] may know about [state].
///
/// Never contains other players' roles (except fellow werewolves for a
/// werewolf, revealed dead players and everyone once the game is over),
/// other players' night choices, decoys or votes. The lovers are known only
/// to themselves and cupid, tonight's victim only to the werewolves (by
/// their picks) and the witch in her step. Each player sees only their own
/// door sign, the pack's door sign attempt only the living werewolves.
PlayerView viewFor(GameState state, PlayerId viewer) {
  final me = state.player(viewer);
  if (me == null) throw ArgumentError.value(viewer, 'viewer', 'not in game');
  final isWolf = me.role?.faction == Faction.werewolves;
  final over = state.phase == Phase.ended;
  final isWitch = me.role == Role.witch && me.isAlive;
  final knowsCouple =
      over || me.role == Role.cupid || state.lovers.contains(viewer);

  Role? known(Player p) {
    if (p.id == viewer || over) return p.role;
    if (isWolf && p.role?.faction == Faction.werewolves) return p.role;
    if (!p.isAlive && state.settings.revealRoleOnDeath) return p.role;
    return null;
  }

  return PlayerView(
    you: viewer,
    phase: state.phase,
    round: state.round,
    seats: [
      for (final p in state.players)
        SeatView(
          id: p.id,
          name: p.name,
          isAlive: p.isAlive,
          persona: p.persona,
          role: known(p),
        ),
    ],
    deaths: _deaths(state),
    waitingFor: _waitingFor(state),
    settings: state.settings,
    yourRole: me.role,
    youConfirmed: state.confirmed.contains(viewer),
    nightStep: state.nightStep,
    yourNightTask: nightTask(state, viewer),
    yourNightTargets: state.nightChoices[viewer] ?? const [],
    youActed: state.nightChoices.containsKey(viewer),
    yourVote: state.votes[viewer],
    youVoted: state.votes.containsKey(viewer),
    packChoices: isWolf && me.isAlive
        ? {
            for (final MapEntry(:key, :value) in state.nightChoices.entries)
              if (nightTask(state, key) == NightAbility.hunt) key: value.first,
          }
        : const {},
    seerResults: state.seerResults[viewer] ?? const [],
    lastNightSheep: state.lastNightSheep,
    dreams: state.dreams,
    yourFlock:
        state.phase == Phase.night && me.isAlive && state.settings.sheepCounting
        ? flockFor(state, viewer)
        : null,
    yourDoorSign:
        state.phase == Phase.night && me.isAlive && state.settings.doorSigns
        ? doorSignFor(state, viewer)
        : null,
    packMark: isWolf && me.isAlive ? state.packMark : null,
    couple: knowsCouple ? state.lovers : const [],
    victim: isWitch && state.phase == Phase.night ? state.nightVictim : null,
    potions: isWitch
        ? {
            for (final p in Potion.values)
              if (!state.potionsUsed.contains(p)) p,
          }
        : const {},
    shooter: state.shooter,
    winner: state.winner,
  );
}

/// What anyone at the table may know, e.g. for a shared screen.
PlayerView publicView(GameState state) => PlayerView(
  you: const PlayerId(''),
  phase: state.phase,
  round: state.round,
  seats: [
    for (final p in state.players)
      SeatView(
        id: p.id,
        name: p.name,
        isAlive: p.isAlive,
        persona: p.persona,
        role:
            state.phase == Phase.ended ||
                (!p.isAlive && state.settings.revealRoleOnDeath)
            ? p.role
            : null,
      ),
  ],
  deaths: _deaths(state),
  waitingFor: _waitingFor(state),
  settings: state.settings,
  nightStep: state.nightStep,
  lastNightSheep: state.lastNightSheep,
  dreams: state.dreams,
  couple: state.phase == Phase.ended ? state.lovers : const [],
  shooter: state.shooter,
  winner: state.winner,
);

List<DeathView> _deaths(GameState state) => [
  for (final d in state.deaths)
    DeathView(
      player: d.player,
      round: d.round,
      cause: d.cause,
      role: state.settings.revealRoleOnDeath || state.phase == Phase.ended
          ? state.player(d.player)?.role
          : null,
    ),
];

int _waitingFor(GameState state) => switch (state.phase) {
  Phase.roleReveal => state.players.length - state.confirmed.length,
  Phase.night =>
    state.alive.where((p) => !state.nightChoices.containsKey(p.id)).length,
  Phase.vote => state.alive.where((p) => !state.votes.containsKey(p.id)).length,
  Phase.hunterShot => 1,
  Phase.lobby || Phase.day || Phase.ended => 0,
};
