import 'package:game_core/src/role.dart';

/// Stable identifier of a player within one game.
extension type const PlayerId(String value) {}

/// Options the host picks before a game.
class GameSettings {
  /// Creates settings; the defaults are the recommended rules.
  const GameSettings({this.revealRoleOnDeath = true, this.seerSeesRole = true});

  /// Whether a dead player's role is shown to everyone.
  final bool revealRoleOnDeath;

  /// Whether the seer learns the exact role (otherwise only the faction).
  final bool seerSeesRole;
}

/// A player at the table. The list order in [GameState.players] is the
/// seating order.
class Player {
  /// Creates a player.
  const Player({
    required this.id,
    required this.name,
    this.role,
    this.isAlive = true,
  });

  /// Stable id.
  final PlayerId id;

  /// Display name, unique within the game.
  final String name;

  /// Assigned role; `null` until the game starts.
  final Role? role;

  /// Whether the player is still in the game.
  final bool isAlive;

  /// Returns a copy with the given fields replaced.
  Player copyWith({Role? role, bool? isAlive}) => Player(
    id: id,
    name: name,
    role: role ?? this.role,
    isAlive: isAlive ?? this.isAlive,
  );
}

/// Where a game currently is.
enum Phase {
  /// Players join; nothing is secret yet.
  lobby,

  /// Everyone looks at their role and confirms.
  roleReveal,

  /// Secret actions.
  night,

  /// Open discussion at the table.
  day,

  /// Everyone votes on whom to eliminate.
  vote,

  /// A faction has won.
  ended,
}

/// How a player died.
enum DeathCause {
  /// Taken by the werewolves.
  night,

  /// Voted out by the village.
  vote,
}

/// A death, kept so that late (re)joiners can be told what happened.
class Death {
  /// Creates a record of a death.
  const Death({required this.player, required this.round, required this.cause});

  /// Who died.
  final PlayerId player;

  /// In which round.
  final int round;

  /// How.
  final DeathCause cause;
}

/// What the seer learnt about a player.
class SeerResult {
  /// Creates a seer result.
  const SeerResult({
    required this.target,
    required this.round,
    required this.faction,
    this.role,
  });

  /// Who was looked at.
  final PlayerId target;

  /// In which night.
  final int round;

  /// The target's faction (always known).
  final Faction faction;

  /// The exact role, if [GameSettings.seerSeesRole].
  final Role? role;
}

/// The complete, authoritative state of one game. Only the host holds it;
/// players get a filtered `PlayerView`.
class GameState {
  /// Creates a state; use [GameState.lobby] to start a new game.
  GameState({
    required List<Player> players,
    required this.phase,
    required this.round,
    required this.settings,
    Set<PlayerId> confirmed = const {},
    Map<PlayerId, PlayerId> nightChoices = const {},
    Map<PlayerId, PlayerId?> votes = const {},
    Map<PlayerId, List<SeerResult>> seerResults = const {},
    List<Death> deaths = const [],
    this.winner,
  }) : players = List.unmodifiable(players),
       confirmed = Set.unmodifiable(confirmed),
       nightChoices = Map.unmodifiable(nightChoices),
       votes = Map.unmodifiable(votes),
       seerResults = Map.unmodifiable(seerResults),
       deaths = List.unmodifiable(deaths);

  /// An empty lobby.
  factory GameState.lobby({GameSettings settings = const GameSettings()}) =>
      GameState(
        players: const [],
        phase: Phase.lobby,
        round: 0,
        settings: settings,
      );

  /// Players in seating order.
  final List<Player> players;

  /// Current phase.
  final Phase phase;

  /// Current round; the first night is round 1.
  final int round;

  /// Rules for this game.
  final GameSettings settings;

  /// Players who confirmed their role during [Phase.roleReveal].
  final Set<PlayerId> confirmed;

  /// Target chosen by each player in the current night.
  final Map<PlayerId, PlayerId> nightChoices;

  /// Votes in the current vote; `null` is an abstention.
  final Map<PlayerId, PlayerId?> votes;

  /// Everything each seer has learnt so far.
  final Map<PlayerId, List<SeerResult>> seerResults;

  /// All deaths so far, oldest first.
  final List<Death> deaths;

  /// The winning faction once [phase] is [Phase.ended].
  final Faction? winner;

  /// Living players in seating order.
  Iterable<Player> get alive => players.where((p) => p.isAlive);

  /// The player with [id], or `null`.
  Player? player(PlayerId id) {
    for (final p in players) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Returns a copy with the given fields replaced.
  GameState copyWith({
    List<Player>? players,
    Phase? phase,
    int? round,
    Set<PlayerId>? confirmed,
    Map<PlayerId, PlayerId>? nightChoices,
    Map<PlayerId, PlayerId?>? votes,
    Map<PlayerId, List<SeerResult>>? seerResults,
    List<Death>? deaths,
    Faction? winner,
  }) => GameState(
    players: players ?? this.players,
    phase: phase ?? this.phase,
    round: round ?? this.round,
    settings: settings,
    confirmed: confirmed ?? this.confirmed,
    nightChoices: nightChoices ?? this.nightChoices,
    votes: votes ?? this.votes,
    seerResults: seerResults ?? this.seerResults,
    deaths: deaths ?? this.deaths,
    winner: winner ?? this.winner,
  );
}
