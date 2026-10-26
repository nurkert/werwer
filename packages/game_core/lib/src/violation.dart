/// Why an action was refused.
enum Violation {
  /// The action is not allowed in the current phase.
  wrongPhase,

  /// The acting or targeted player does not exist.
  unknownPlayer,

  /// A player with this id is already in the game.
  duplicatePlayer,

  /// The name is empty, too long or already taken.
  invalidName,

  /// The game is full.
  gameFull,

  /// The acting player is dead.
  playerDead,

  /// The acting player's role cannot do this.
  notYourAction,

  /// The target is not allowed (dead, yourself, a fellow werewolf, …).
  invalidTarget,

  /// The action was already used this phase.
  alreadyActed,

  /// Not enough or too many players to start.
  playerCount,

  /// The roles do not fit the players or make no game.
  invalidRoles,

  /// A number is out of the allowed range.
  outOfRange,

  /// Another player already has this persona (and others are still free).
  personaTaken,

  /// The game's settings switch this off.
  disabled,

  /// The werewolves already tried a door sign tonight.
  markUsed,
}

/// Thrown by `apply` for an action that breaks the rules. The state is never
/// changed by a refused action.
class RuleViolation implements Exception {
  /// Creates the exception.
  const RuleViolation(this.reason);

  /// Why the action was refused.
  final Violation reason;

  @override
  String toString() => 'RuleViolation(${reason.name})';
}
