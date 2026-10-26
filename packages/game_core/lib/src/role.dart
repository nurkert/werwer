/// The sides of the game.
enum Faction {
  /// Wins when no werewolf is left.
  village,

  /// Win when they are at least as many as everyone else alive.
  werewolves,

  /// Never a role's side, only a winner: a couple that cupid linked across
  /// the sides (a werewolf and someone from the village) plays for itself
  /// and wins when the two of them are the last ones alive.
  lovers,
}

/// What a player does in one step of the night.
///
/// Every living player acts in every step, so nobody stands out by tapping
/// (anti-tell). Whoever has nothing real to do in a step gets a decoy task
/// that has no effect on the game.
enum NightAbility {
  /// Picks a victim together with the other werewolves.
  hunt,

  /// Looks at one player's role (or faction).
  inspect,

  /// First night only: links two players as lovers.
  link,

  /// After the werewolves: may save their victim with the healing potion
  /// and poison someone with the other, each once per game.
  brew,

  /// Picks someone too, without any effect.
  decoy,
}

/// A role a player can have.
///
/// New roles are added here with their faction and night ability; the state
/// machine resolves nights by ability, not by role.
enum Role {
  /// No special ability.
  villager(Faction.village, NightAbility.decoy),

  /// Hunts at night with the other werewolves.
  werewolf(Faction.werewolves, NightAbility.hunt),

  /// Looks into one player each night.
  seer(Faction.village, NightAbility.inspect),

  /// Has a healing and a poison potion, each good for one use per game.
  witch(Faction.village, NightAbility.brew),

  /// Takes someone along when dying, however that happens.
  hunter(Faction.village, NightAbility.decoy),

  /// Links two players as lovers in the first night.
  cupid(Faction.village, NightAbility.link);

  const Role(this.faction, this.nightAbility);

  /// The side this role plays for.
  final Faction faction;

  /// The role's own night ability. When it applies (cupid only in the
  /// first night, the witch only after the werewolves) is up to the rules;
  /// see `nightTask`.
  final NightAbility nightAbility;
}

/// Roles a game can have besides werewolves and villagers, each at most
/// once.
const Set<Role> specialRoles = {Role.seer, Role.witch, Role.hunter, Role.cupid};

/// A character a player appears as at the table. Any persona can have any
/// role: the persona is who you are, the role is your secret.
enum Persona {
  /// The maid with her bucket.
  maid,

  /// The cloaked woman with the lantern.
  lanternBearer,

  /// The grey wolf in the red vest.
  greyWolf,

  /// The farmer with the pitchfork.
  farmer,

  /// The hunter with the longbow.
  hunter,

  /// The herb witch.
  herbWitch,

  /// The little cupid.
  cupid,

  /// The guard with the shield.
  guard,

  /// The tracker.
  tracker,

  /// The listener.
  listener,

  /// The quiet paw.
  quietPaw,

  /// The baker with her bread peel.
  baker,

  /// The fisher with her net.
  fisher,

  /// The seamstress with her scissors.
  seamstress,

  /// The goose girl.
  gooseGirl,

  /// The innkeeper with two tankards.
  innkeeper,

  /// The young smith with his hammer.
  smith,

  /// The miller with a flour sack.
  miller,

  /// The minstrel with his lute.
  minstrel,

  /// The old beekeeper.
  beekeeper,
}

/// Fewest players a game can start with (for play tests; fun starts at
/// [recommendedMinPlayers]).
const minPlayers = 3;

/// Fewest players for a proper round.
const recommendedMinPlayers = 5;

/// Most players a game can have.
const maxPlayers = 20;

/// Most werewolves a game can have (they must be fewer than the others).
const int maxWerewolves = (maxPlayers - 1) ~/ 2;

/// The suggested number of werewolves for [playerCount] players: about one
/// per four players, at least one.
int suggestedWerewolves(int playerCount) =>
    playerCount < recommendedMinPlayers ? 1 : playerCount ~/ 4;

/// A sensible role set for [playerCount] players: [suggestedWerewolves],
/// a seer from four players on, villagers for the rest.
///
/// Throws an [ArgumentError] outside [minPlayers]..[maxPlayers].
List<Role> suggestRoles(int playerCount) {
  if (playerCount < minPlayers || playerCount > maxPlayers) {
    throw ArgumentError.value(
      playerCount,
      'playerCount',
      'must be between $minPlayers and $maxPlayers',
    );
  }
  final wolves = suggestedWerewolves(playerCount);
  final seers = playerCount >= 4 ? 1 : 0;
  return [
    for (var i = 0; i < wolves; i++) Role.werewolf,
    for (var i = 0; i < seers; i++) Role.seer,
    for (var i = 0; i < playerCount - wolves - seers; i++) Role.villager,
  ];
}
