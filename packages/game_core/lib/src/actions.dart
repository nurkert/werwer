import 'dart:math';

import 'package:game_core/src/model.dart';
import 'package:game_core/src/role.dart';

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

/// Deals the roles and starts the game.
final class StartGame extends GameAction {
  /// Creates the action. Without [roles], [suggestRoles] is used.
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

/// Anti-tell: a player without a night ability picks someone, without effect.
final class NightDecoy extends GameAction {
  /// Creates the action.
  const NightDecoy(this.player, this.target);

  /// Who acts.
  final PlayerId player;

  /// Whom they picked.
  final PlayerId target;
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

/// The night action for a player with [role] who picked [target].
///
/// Every night screen looks the same and sends the same kind of choice; the
/// role decides what the choice means.
GameAction nightAction(Role role, PlayerId actor, PlayerId target) =>
    switch (role.nightAbility) {
      NightAbility.hunt => WerewolfVote(actor, target),
      NightAbility.inspect => SeerInspect(actor, target),
      NightAbility.decoy => NightDecoy(actor, target),
    };
