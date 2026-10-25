/// The two sides of the game.
enum Faction {
  /// Wins when no werewolf is left.
  village,

  /// Win when they are at least as many as everyone else alive.
  werewolves,
}

/// What a role does at night.
///
/// Every living player acts at night, so nobody stands out by tapping
/// (anti-tell). Roles without a real ability get a decoy task that has no
/// effect on the game.
enum NightAbility {
  /// Picks a victim together with the other werewolves.
  hunt,

  /// Looks at one player's role (or faction).
  inspect,

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
  seer(Faction.village, NightAbility.inspect);

  const Role(this.faction, this.nightAbility);

  /// The side this role plays for.
  final Faction faction;

  /// What this role does at night.
  final NightAbility nightAbility;
}

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
}

/// Fewest players a game can start with (for play tests; fun starts at
/// [recommendedMinPlayers]).
const minPlayers = 3;

/// Fewest players for a proper round.
const recommendedMinPlayers = 5;

/// Most players a game can have.
const maxPlayers = 20;

/// A sensible role set for [playerCount] players: about one werewolf per four
/// players, a seer from four players on, villagers for the rest.
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
  final wolves = playerCount < recommendedMinPlayers ? 1 : playerCount ~/ 4;
  final seers = playerCount >= 4 ? 1 : 0;
  return [
    for (var i = 0; i < wolves; i++) Role.werewolf,
    for (var i = 0; i < seers; i++) Role.seer,
    for (var i = 0; i < playerCount - wolves - seers; i++) Role.villager,
  ];
}
