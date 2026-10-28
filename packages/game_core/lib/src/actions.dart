import 'dart:math';

import 'package:game_core/src/model.dart';
import 'package:game_core/src/role.dart';
import 'package:game_core/src/settings.dart';

/// Something that changes the game. The host turns player intents and timers
/// into actions and feeds them to `apply`.
sealed class GameAction {
  const GameAction();
}

/// A player joins the lobby. Without a [persona], the first free one is
/// given.
final class AddPlayer extends GameAction {
  /// Creates the action.
  const AddPlayer(this.player, this.name, {this.persona});

  /// The wished persona.
  final Persona? persona;

  /// New player's id.
  final PlayerId player;

  /// Display name.
  final String name;
}

/// A player leaves (or is removed from) the lobby.
final class RemovePlayer extends GameAction {
  /// Creates the action.
  const RemovePlayer(this.player);

  /// Who leaves.
  final PlayerId player;
}

/// A player picks another persona in the lobby.
final class ChoosePersona extends GameAction {
  /// Creates the action.
  const ChoosePersona(this.player, this.persona);

  /// Who picks.
  final PlayerId player;

  /// The persona.
  final Persona persona;
}

/// Two players swap seats in the lobby (the seating order is the order
/// around the real table, needed for the wolf trail later).
final class SwapSeats extends GameAction {
  /// Creates the action.
  const SwapSeats(this.first, this.second);

  /// One player.
  final PlayerId first;

  /// The other player.
  final PlayerId second;
}

/// The host changes the settings in the lobby.
final class ChangeSettings extends GameAction {
  /// Creates the action.
  const ChangeSettings(this.settings);

  /// The new settings, replacing the old ones as a whole.
  final GameSettings settings;
}

/// Deals the roles and starts the game.
final class StartGame extends GameAction {
  /// Creates the action. Without [roles], the settings decide, fitted to
  /// the table ([GameSettings.fittedFor]).
  const StartGame({required this.random, this.roles});

  /// Source of randomness for dealing, injected so games are reproducible.
  final Random random;

  /// Roles to deal, one per player.
  final List<Role>? roles;
}

/// A player has seen their role.
final class ConfirmRole extends GameAction {
  /// Creates the action.
  const ConfirmRole(this.player);

  /// Who confirms.
  final PlayerId player;
}

/// A werewolf picks (or changes) the victim.
final class WerewolfVote extends GameAction {
  /// Creates the action.
  const WerewolfVote(this.wolf, this.target);

  /// The voting werewolf.
  final PlayerId wolf;

  /// The proposed victim.
  final PlayerId target;
}

/// The seer looks at a player, once per night.
final class SeerInspect extends GameAction {
  /// Creates the action.
  const SeerInspect(this.seer, this.target);

  /// The seer.
  final PlayerId seer;

  /// Who is looked at.
  final PlayerId target;
}

/// The protector shields [target] from the werewolves tonight (himself
/// too, but nobody two nights in a row).
final class ProtectorGuard extends GameAction {
  /// Creates the action.
  const ProtectorGuard(this.protector, this.target);

  /// The protector.
  final PlayerId protector;

  /// Who is shielded.
  final PlayerId target;
}

/// Cupid links two players as lovers in the first night (himself included,
/// if he likes).
final class CupidLink extends GameAction {
  /// Creates the action.
  const CupidLink(this.cupid, this.first, this.second);

  /// Cupid.
  final PlayerId cupid;

  /// One lover.
  final PlayerId first;

  /// The other lover.
  final PlayerId second;
}

/// The witch decides, after the werewolves, once per night.
final class WitchBrew extends GameAction {
  /// Creates the action; without potions she lets the night take its
  /// course.
  const WitchBrew(this.witch, {this.heal = false, this.poison});

  /// The witch.
  final PlayerId witch;

  /// Whether she saves tonight's victim.
  final bool heal;

  /// Whom she poisons, if anyone.
  final PlayerId? poison;
}

/// The dead hunter takes someone along, or [target] `null` to spare
/// everyone.
final class HunterShoot extends GameAction {
  /// Creates the action.
  const HunterShoot(this.hunter, this.target);

  /// The hunter.
  final PlayerId hunter;

  /// Whom he takes along.
  final PlayerId? target;
}

/// Anti-tell: a player without a night task picks someone, without effect.
final class NightDecoy extends GameAction {
  /// Creates the action.
  const NightDecoy(this.player, this.target);

  /// Who acts.
  final PlayerId player;

  /// Whom they picked.
  final PlayerId target;
}

/// How many symbols a door sign has.
const doorSignLength = 3;

/// How many different symbols a door sign is made of; each symbol of a
/// sign is a number `0 <= s < doorSignSymbols`.
const doorSignSymbols = 16;

/// A werewolf guesses [target]'s door sign tonight (see
/// [GameSettings.doorSigns]). The pack has one attempt per night; it is not
/// the werewolf's night pick. A right guess may take [target] in the
/// morning as well.
final class MarkDoor extends GameAction {
  /// Creates the action.
  const MarkDoor(this.actor, this.target, this.sign);

  /// The guessing werewolf.
  final PlayerId actor;

  /// Whose door is marked.
  final PlayerId target;

  /// The guessed sign: [doorSignLength] symbols.
  final List<int> sign;
}

/// Most sheep (or least, negative) a player can count in one night.
const maxSheepPerNight = 500;

/// Fewest sheep a player gets in a night.
const minFlock = 3;

/// Most sheep a player gets in a night.
const maxFlock = 30;

/// How many sheep a player has counted so far tonight (a running total that
/// replaces the previous one). Has no effect on the night itself; the totals
/// are told to everyone in the morning.
final class CountSheep extends GameAction {
  /// Creates the action.
  const CountSheep(this.player, this.sheep);

  /// Who counted.
  final PlayerId player;

  /// The running total for tonight.
  final int sheep;
}

/// The discussion is over; voting starts.
final class EndDiscussion extends GameAction {
  /// Creates the action.
  const EndDiscussion();
}

/// A vote (or abstention) during the day vote; can be changed until resolved.
final class CastVote extends GameAction {
  /// Creates the action.
  const CastVote(this.voter, this.target);

  /// Who votes.
  final PlayerId voter;

  /// Whom to eliminate; `null` abstains.
  final PlayerId? target;
}

/// The phase timer ran out: resolve with what has been chosen so far.
final class PhaseTimeout extends GameAction {
  /// Creates the action.
  const PhaseTimeout();
}
