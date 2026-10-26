import 'package:game_core/src/model.dart';
import 'package:game_core/src/role.dart';

/// Who may learn about an event.
sealed class Audience {
  const Audience();

  /// Whether [player] may learn about the event.
  bool includes(PlayerId player);
}

/// Everyone at the table.
final class Everyone extends Audience {
  /// Creates the audience.
  const Everyone();

  @override
  bool includes(PlayerId player) => true;
}

/// Only some players.
final class OnlyPlayers extends Audience {
  /// Creates the audience.
  const OnlyPlayers(this.players);

  /// Who may learn about the event.
  final Set<PlayerId> players;

  @override
  bool includes(PlayerId player) => players.contains(player);
}

/// Something the narrator can tell. Data only; texts live in the app.
sealed class GameEvent {
  const GameEvent();

  /// Who may learn about this event.
  Audience get audience => const Everyone();
}

/// Someone joined the lobby.
final class PlayerJoined extends GameEvent {
  /// Creates the event.
  const PlayerJoined(this.player);

  /// Who joined.
  final PlayerId player;
}

/// Someone left the lobby.
final class PlayerLeft extends GameEvent {
  /// Creates the event.
  const PlayerLeft(this.player);

  /// Who left.
  final PlayerId player;
}

/// Roles were dealt.
final class GameStarted extends GameEvent {
  /// Creates the event.
  const GameStarted();
}

/// Night [round] begins.
final class NightFell extends GameEvent {
  /// Creates the event.
  const NightFell(this.round);

  /// The night's round.
  final int round;
}

/// Someone died at night (taken by the werewolves or poisoned: the
/// morning does not tell which).
final class PlayerKilled extends GameEvent {
  /// Creates the event.
  const PlayerKilled(this.player, this.role);

  /// Who died.
  final PlayerId player;

  /// Their role, if roles are revealed on death.
  final Role? role;
}

/// Nobody died at night.
final class NobodyDied extends GameEvent {
  /// Creates the event.
  const NobodyDied();
}

/// Day [round] begins.
final class DayBroke extends GameEvent {
  /// Creates the event.
  const DayBroke(this.round);

  /// The day's round.
  final int round;
}

/// The vote begins.
final class VotingStarted extends GameEvent {
  /// Creates the event.
  const VotingStarted();
}

/// The village voted a player out.
final class PlayerEliminated extends GameEvent {
  /// Creates the event.
  const PlayerEliminated(this.player, this.role);

  /// Who was voted out.
  final PlayerId player;

  /// Their role, if roles are revealed on death.
  final Role? role;
}

/// Nobody was voted out.
final class NobodyEliminated extends GameEvent {
  /// Creates the event.
  const NobodyEliminated({required this.tie});

  /// `true` for a tie, `false` when nobody voted.
  final bool tie;
}

/// What the seer saw. Only the seer learns about it.
final class SeerSaw extends GameEvent {
  /// Creates the event.
  const SeerSaw(this.seer, this.result);

  /// The seer.
  final PlayerId seer;

  /// What was seen.
  final SeerResult result;

  @override
  Audience get audience => OnlyPlayers({seer});
}

/// The werewolves' step is over and the witch decides (only in games with a
/// witch; everyone gets a step of their own, so nobody stands out).
final class BrewStepBegan extends GameEvent {
  /// Creates the event.
  const BrewStepBegan();
}

/// Cupid linked two lovers. Only the three of them learn about it.
final class LoversLinked extends GameEvent {
  /// Creates the event.
  const LoversLinked(this.cupid, this.first, this.second);

  /// Cupid.
  final PlayerId cupid;

  /// One lover.
  final PlayerId first;

  /// The other lover.
  final PlayerId second;

  @override
  Audience get audience => OnlyPlayers({cupid, first, second});
}

/// A lover died of grief after their partner died.
final class LoverDied extends GameEvent {
  /// Creates the event.
  const LoverDied(this.player, this.role);

  /// The lover.
  final PlayerId player;

  /// Their role, if roles are revealed on death.
  final Role? role;
}

/// The hunter died and takes aim.
final class HunterAims extends GameEvent {
  /// Creates the event.
  const HunterAims(this.hunter);

  /// The hunter.
  final PlayerId hunter;
}

/// The hunter took someone along.
final class PlayerShot extends GameEvent {
  /// Creates the event.
  const PlayerShot(this.player, this.role);

  /// Who was shot.
  final PlayerId player;

  /// Their role, if roles are revealed on death.
  final Role? role;
}

/// The hunter spared everyone (or his time ran out).
final class HunterSpared extends GameEvent {
  /// Creates the event.
  const HunterSpared(this.hunter);

  /// The hunter.
  final PlayerId hunter;
}

/// The game is over.
final class GameEnded extends GameEvent {
  /// Creates the event.
  const GameEnded(this.winner);

  /// Who won.
  final Faction winner;
}
