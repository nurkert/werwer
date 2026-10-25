import 'package:game_core/src/model.dart';
import 'package:game_core/src/role.dart';
import 'package:game_core/src/rules.dart';

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
    this.yourRole,
    this.youConfirmed = false,
    this.yourNightChoice,
    this.yourVote,
    this.youVoted = false,
    this.packChoices = const {},
    this.seerResults = const [],
    this.lastNightSheep = const {},
    this.dreams = const {},
    this.yourFlock,
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

  /// How many living players still have to act in this phase.
  final int waitingFor;

  /// The viewer's own role, once dealt.
  final Role? yourRole;

  /// Whether the viewer confirmed their role.
  final bool youConfirmed;

  /// Whom the viewer picked tonight.
  final PlayerId? yourNightChoice;

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

  /// The winning faction once the game is over.
  final Faction? winner;

  /// The viewer's own seat.
  SeatView get yourSeat => seats.firstWhere((s) => s.id == you);
}

/// What [viewer] may know about [state].
///
/// Never contains other players' roles (except fellow werewolves for a
/// werewolf, revealed dead players and everyone once the game is over),
/// other players' night choices, decoys or votes.
PlayerView viewFor(GameState state, PlayerId viewer) {
  final me = state.player(viewer);
  if (me == null) throw ArgumentError.value(viewer, 'viewer', 'not in game');
  final isWolf = me.role?.faction == Faction.werewolves;
  final over = state.phase == Phase.ended;

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
    yourRole: me.role,
    youConfirmed: state.confirmed.contains(viewer),
    yourNightChoice: state.nightChoices[viewer],
    yourVote: state.votes[viewer],
    youVoted: state.votes.containsKey(viewer),
    packChoices: isWolf && me.isAlive
        ? {
            for (final MapEntry(:key, :value) in state.nightChoices.entries)
              if (state.player(key)?.role?.faction == Faction.werewolves)
                key: value,
          }
        : const {},
    seerResults: state.seerResults[viewer] ?? const [],
    lastNightSheep: state.lastNightSheep,
    dreams: state.dreams,
    yourFlock: state.phase == Phase.night && me.isAlive
        ? flockFor(state, viewer)
        : null,
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
  lastNightSheep: state.lastNightSheep,
  dreams: state.dreams,
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
  _ => 0,
};
