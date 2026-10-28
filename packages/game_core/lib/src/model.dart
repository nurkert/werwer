import 'package:game_core/src/role.dart';
import 'package:game_core/src/settings.dart';

/// Stable identifier of a player within one game.
extension type const PlayerId(String value) {}

/// A player at the table. The list order in [GameState.players] is the
/// seating order.
class Player {
  /// Creates a player.
  const Player({
    required this.id,
    required this.name,
    this.persona = Persona.farmer,
    this.role,
    this.isAlive = true,
  });

  /// Stable id.
  final PlayerId id;

  /// Display name, unique within the game.
  final String name;

  /// The character this player appears as.
  final Persona persona;

  /// Assigned role; `null` until the game starts.
  final Role? role;

  /// Whether the player is still in the game.
  final bool isAlive;

  /// Returns a copy with the given fields replaced.
  Player copyWith({Persona? persona, Role? role, bool? isAlive}) => Player(
    id: id,
    name: name,
    persona: persona ?? this.persona,
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

  /// The hunter just died and takes someone along. Comes after the night or
  /// the vote that killed him; the game goes on (or ends) after the shot.
  hunterShot,

  /// A faction has won.
  ended,
}

/// How a player died.
enum DeathCause {
  /// Taken by the werewolves.
  night,

  /// Voted out by the village.
  vote,

  /// Died of grief because their lover died.
  heartbreak,

  /// Taken along by the dying hunter.
  shot,
}

/// The steps of a night.
///
/// In Whowolf's night ([NightMode.together]) everyone alive acts in every
/// step, and there are two: [hunt] and [brew]. When the narrator calls the
/// roles ([NightMode.called]) every role has its own step, in this order:
/// [link] (first night), [hunt], [inspect], [brew]. A role's step comes in
/// every night it is in the game, even after its death, so a night always
/// takes the same course.
enum NightStep {
  /// The werewolves hunt (together: the seer looks and cupid links too).
  hunt,

  /// The witch decides about the werewolves' victim. Only in games with a
  /// witch.
  brew,

  /// Called night, first night only: cupid links two players.
  link,

  /// Called night: the seer looks at someone.
  inspect,
}

/// The witch's potions, each good for one use per game.
enum Potion {
  /// Saves the werewolves' victim.
  heal,

  /// Kills someone.
  poison,
}

/// The werewolves' door sign attempt of a night: whose door they marked
/// and whether the sign was right.
typedef DoorMark = ({PlayerId target, bool correct});

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

/// What a [ChronicleEntry] records.
enum ChronicleKind {
  /// The werewolves' pick for the night (`target` null: they did not
  /// agree).
  hunt,

  /// The witch saved the werewolves' victim.
  heal,

  /// The witch poisoned someone.
  poison,

  /// One vote of the day (`target` null: an abstention).
  vote,

  /// The seer looked at `target` (only in a view of the ended game).
  look,

  /// Cupid linked `actor`'s pick: the lovers are `target` and the other
  /// entry of the pair (only in a view of the ended game).
  link,
}

/// One line of the game's chronicle, told to everyone when the game is
/// over (the votes earlier with open voting). The seer's looks and the
/// lovers are kept elsewhere already.
class ChronicleEntry {
  /// Creates an entry.
  const ChronicleEntry({
    required this.round,
    required this.kind,
    this.actor,
    this.target,
    this.runoff = false,
  });

  /// In which round (night and the day after share it).
  final int round;

  /// What happened.
  final ChronicleKind kind;

  /// Who did it (the witch, the voter), if one player did.
  final PlayerId? actor;

  /// To whom.
  final PlayerId? target;

  /// For a vote: it was the runoff.
  final bool runoff;
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
    this.nightStep = NightStep.hunt,
    Map<PlayerId, List<PlayerId>> nightChoices = const {},
    this.nightVictim,
    this.packMark,
    List<PlayerId> lovers = const [],
    Set<Potion> potionsUsed = const {},
    this.shooter,
    this.afterShot,
    Map<PlayerId, PlayerId?> votes = const {},
    List<PlayerId> runoff = const [],
    Map<PlayerId, List<SeerResult>> seerResults = const {},
    List<Death> deaths = const [],
    List<ChronicleEntry> chronicle = const [],
    Map<PlayerId, int> sheep = const {},
    Map<PlayerId, int> lastNightSheep = const {},
    Map<PlayerId, int> dreams = const {},
    List<int> secret = const [],
    this.winner,
  }) : players = List.unmodifiable(players),
       secret = List.unmodifiable(secret),
       sheep = Map.unmodifiable(sheep),
       lastNightSheep = Map.unmodifiable(lastNightSheep),
       dreams = Map.unmodifiable(dreams),
       confirmed = Set.unmodifiable(confirmed),
       nightChoices = Map.unmodifiable({
         for (final MapEntry(:key, :value) in nightChoices.entries)
           key: List<PlayerId>.unmodifiable(value),
       }),
       lovers = List.unmodifiable(lovers),
       potionsUsed = Set.unmodifiable(potionsUsed),
       votes = Map.unmodifiable(votes),
       runoff = List.unmodifiable(runoff),
       seerResults = Map.unmodifiable(seerResults),
       deaths = List.unmodifiable(deaths),
       chronicle = List.unmodifiable(chronicle);

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

  /// The current step of the night.
  final NightStep nightStep;

  /// Targets picked by each player in the current night step (one for most
  /// tasks, two for cupid, none to two for the witch).
  final Map<PlayerId, List<PlayerId>> nightChoices;

  /// Tonight's victim of the werewolves, fixed when their step ends (the
  /// witch may still save them); `null` if they did not agree.
  final PlayerId? nightVictim;

  /// Tonight's door sign attempt of the werewolves, if they made one.
  final DoorMark? packMark;

  /// The two players cupid linked, or empty.
  final List<PlayerId> lovers;

  /// The witch's potions already used.
  final Set<Potion> potionsUsed;

  /// In [Phase.hunterShot]: the dead hunter who takes someone along.
  final PlayerId? shooter;

  /// In [Phase.hunterShot]: where the game goes after the shot
  /// ([Phase.day] or [Phase.night]).
  final Phase? afterShot;

  /// Votes in the current vote; `null` is an abstention.
  final Map<PlayerId, PlayerId?> votes;

  /// In a runoff ([TieRule.runoff]): the tied players, the only ones who
  /// may be voted for; empty in a first vote.
  final List<PlayerId> runoff;

  /// Everything each seer has learnt so far.
  final Map<PlayerId, List<SeerResult>> seerResults;

  /// All deaths so far, oldest first.
  final List<Death> deaths;

  /// What happened at night and in the votes, oldest first (see
  /// [ChronicleEntry]); secret until the game is over.
  final List<ChronicleEntry> chronicle;

  /// Sheep each player has counted so far tonight (secret until morning).
  final Map<PlayerId, int> sheep;

  /// Sheep each player counted last night, told to everyone in the morning.
  final Map<PlayerId, int> lastNightSheep;

  /// Dream points (all sheep counted) per player over the whole game.
  final Map<PlayerId, int> dreams;

  /// 32 random bytes drawn when the game starts. Flocks, door signs and the
  /// mark's coin are derived from it with a keyed hash, so nobody can work
  /// them out from what they see. Kept by the host only, never in a view.
  final List<int> secret;

  /// The winning faction once [phase] is [Phase.ended].
  final Faction? winner;

  /// Living players in seating order.
  Iterable<Player> get alive => players.where((p) => p.isAlive);

  /// The lover of [id], or `null` if [id] is not in love.
  PlayerId? loverOf(PlayerId id) => switch (lovers) {
    [final a, final b] when a == id => b,
    [final a, final b] when b == id => a,
    _ => null,
  };

  /// Whether a witch was dealt in this game (then every night has a
  /// [NightStep.brew]).
  bool get hasWitch => players.any((p) => p.role == Role.witch);

  /// The player with [id], or `null`.
  Player? player(PlayerId id) {
    for (final p in players) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Returns a copy with the given fields replaced.
  ///
  /// The nullable fields [nightVictim], [packMark], [shooter] and
  /// [afterShot] are replaced whenever they are passed, also by `null`.
  GameState copyWith({
    List<Player>? players,
    Phase? phase,
    int? round,
    GameSettings? settings,
    Set<PlayerId>? confirmed,
    NightStep? nightStep,
    Map<PlayerId, List<PlayerId>>? nightChoices,
    Object? nightVictim = _keep,
    Object? packMark = _keep,
    List<PlayerId>? lovers,
    Set<Potion>? potionsUsed,
    Object? shooter = _keep,
    Object? afterShot = _keep,
    Map<PlayerId, PlayerId?>? votes,
    List<PlayerId>? runoff,
    Map<PlayerId, List<SeerResult>>? seerResults,
    List<Death>? deaths,
    List<ChronicleEntry>? chronicle,
    Map<PlayerId, int>? sheep,
    Map<PlayerId, int>? lastNightSheep,
    Map<PlayerId, int>? dreams,
    List<int>? secret,
    Faction? winner,
  }) => GameState(
    players: players ?? this.players,
    phase: phase ?? this.phase,
    round: round ?? this.round,
    settings: settings ?? this.settings,
    confirmed: confirmed ?? this.confirmed,
    nightStep: nightStep ?? this.nightStep,
    nightChoices: nightChoices ?? this.nightChoices,
    nightVictim: identical(nightVictim, _keep)
        ? this.nightVictim
        : nightVictim as PlayerId?,
    packMark: identical(packMark, _keep)
        ? this.packMark
        : packMark as DoorMark?,
    lovers: lovers ?? this.lovers,
    potionsUsed: potionsUsed ?? this.potionsUsed,
    shooter: identical(shooter, _keep) ? this.shooter : shooter as PlayerId?,
    afterShot: identical(afterShot, _keep)
        ? this.afterShot
        : afterShot as Phase?,
    votes: votes ?? this.votes,
    runoff: runoff ?? this.runoff,
    seerResults: seerResults ?? this.seerResults,
    deaths: deaths ?? this.deaths,
    chronicle: chronicle ?? this.chronicle,
    sheep: sheep ?? this.sheep,
    lastNightSheep: lastNightSheep ?? this.lastNightSheep,
    dreams: dreams ?? this.dreams,
    secret: secret ?? this.secret,
    winner: winner ?? this.winner,
  );
}

/// Marks a `copyWith` argument that was not passed.
const Object _keep = Object();
