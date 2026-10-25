import 'package:game_core/src/actions.dart';
import 'package:game_core/src/events.dart';
import 'package:game_core/src/model.dart';
import 'package:game_core/src/role.dart';
import 'package:game_core/src/violation.dart';

/// Longest allowed player name, in characters.
const maxNameLength = 24;

/// The result of [apply]: the new state and what happened.
class GameUpdate {
  /// Creates an update.
  const GameUpdate(this.state, [this.events = const []]);

  /// The state after the action.
  final GameState state;

  /// What the narrator can tell, in order.
  final List<GameEvent> events;
}

/// Applies [action] to [state]. Pure: the same input always gives the same
/// output, and [state] itself is never modified.
///
/// Throws a [RuleViolation] for an action that breaks the rules.
GameUpdate apply(GameState state, GameAction action) => switch (action) {
  AddPlayer() => _addPlayer(state, action),
  RemovePlayer() => _removePlayer(state, action),
  StartGame() => _startGame(state, action),
  ConfirmRole() => _confirmRole(state, action),
  WerewolfVote(:final wolf, :final target) => _night(
    state,
    wolf,
    target,
    NightAbility.hunt,
  ),
  SeerInspect(:final seer, :final target) => _night(
    state,
    seer,
    target,
    NightAbility.inspect,
  ),
  NightDecoy(:final player, :final target) => _night(
    state,
    player,
    target,
    NightAbility.decoy,
  ),
  EndDiscussion() => _endDiscussion(state),
  CastVote() => _castVote(state, action),
  PhaseTimeout() => _timeout(state),
};

Never _refuse(Violation reason) => throw RuleViolation(reason);

void _expectPhase(GameState state, Phase phase) {
  if (state.phase != phase) _refuse(Violation.wrongPhase);
}

Player _living(GameState state, PlayerId id) {
  final player = state.player(id) ?? _refuse(Violation.unknownPlayer);
  if (!player.isAlive) _refuse(Violation.playerDead);
  return player;
}

GameUpdate _addPlayer(GameState state, AddPlayer action) {
  _expectPhase(state, Phase.lobby);
  if (state.player(action.player) != null) _refuse(Violation.duplicatePlayer);
  if (state.players.length >= maxPlayers) _refuse(Violation.gameFull);
  final name = action.name.trim();
  final taken = state.players.any(
    (p) => p.name.toLowerCase() == name.toLowerCase(),
  );
  if (name.isEmpty || name.length > maxNameLength || taken) {
    _refuse(Violation.invalidName);
  }
  return GameUpdate(
    state.copyWith(
      players: [
        ...state.players,
        Player(id: action.player, name: name),
      ],
    ),
    [PlayerJoined(action.player)],
  );
}

GameUpdate _removePlayer(GameState state, RemovePlayer action) {
  _expectPhase(state, Phase.lobby);
  if (state.player(action.player) == null) _refuse(Violation.unknownPlayer);
  return GameUpdate(
    state.copyWith(
      players: [
        for (final p in state.players)
          if (p.id != action.player) p,
      ],
    ),
    [PlayerLeft(action.player)],
  );
}

GameUpdate _startGame(GameState state, StartGame action) {
  _expectPhase(state, Phase.lobby);
  final count = state.players.length;
  if (count < minPlayers || count > maxPlayers) {
    _refuse(Violation.playerCount);
  }
  final roles = [...(action.roles ?? suggestRoles(count))];
  final wolves = roles.where((r) => r.faction == Faction.werewolves).length;
  if (roles.length != count || wolves == 0 || wolves >= count - wolves) {
    _refuse(Violation.invalidRoles);
  }
  roles.shuffle(action.random);
  return GameUpdate(
    state.copyWith(
      phase: Phase.roleReveal,
      players: [
        for (var i = 0; i < count; i++)
          state.players[i].copyWith(role: roles[i]),
      ],
    ),
    const [GameStarted()],
  );
}

GameUpdate _confirmRole(GameState state, ConfirmRole action) {
  _expectPhase(state, Phase.roleReveal);
  if (state.player(action.player) == null) _refuse(Violation.unknownPlayer);
  final confirmed = {...state.confirmed, action.player};
  if (confirmed.length < state.players.length) {
    return GameUpdate(state.copyWith(confirmed: confirmed));
  }
  return GameUpdate(
    state.copyWith(confirmed: confirmed, phase: Phase.night, round: 1),
    const [NightFell(1)],
  );
}

GameUpdate _night(
  GameState state,
  PlayerId actorId,
  PlayerId targetId,
  NightAbility ability,
) {
  _expectPhase(state, Phase.night);
  final actor = _living(state, actorId);
  if (actor.role?.nightAbility != ability) _refuse(Violation.notYourAction);
  final target = state.player(targetId) ?? _refuse(Violation.unknownPlayer);
  if (!target.isAlive || target.id == actor.id) {
    _refuse(Violation.invalidTarget);
  }
  if (ability == NightAbility.hunt &&
      target.role?.faction == Faction.werewolves) {
    _refuse(Violation.invalidTarget);
  }
  final events = <GameEvent>[];
  var next = state;
  if (ability == NightAbility.inspect) {
    if (state.nightChoices.containsKey(actor.id)) {
      _refuse(Violation.alreadyActed);
    }
    final role = target.role!;
    final result = SeerResult(
      target: target.id,
      round: state.round,
      faction: role.faction,
      role: state.settings.seerSeesRole ? role : null,
    );
    events.add(SeerSaw(actor.id, result));
    next = next.copyWith(
      seerResults: {
        ...state.seerResults,
        actor.id: [...?state.seerResults[actor.id], result],
      },
    );
  }
  next = next.copyWith(
    nightChoices: {...state.nightChoices, actor.id: target.id},
  );
  if (next.alive.every((p) => next.nightChoices.containsKey(p.id))) {
    final resolved = _resolveNight(next);
    return GameUpdate(resolved.state, [...events, ...resolved.events]);
  }
  return GameUpdate(next, events);
}

/// The player with the most votes, or `null` for a tie or no votes.
PlayerId? _majority(Iterable<PlayerId> votes) {
  final tally = <PlayerId, int>{};
  for (final v in votes) {
    tally[v] = (tally[v] ?? 0) + 1;
  }
  if (tally.isEmpty) return null;
  final top = tally.values.reduce((a, b) => a > b ? a : b);
  final leaders = tally.entries.where((e) => e.value == top).toList();
  return leaders.length == 1 ? leaders.single.key : null;
}

GameUpdate _resolveNight(GameState state) {
  final wolfVotes = [
    for (final MapEntry(:key, :value) in state.nightChoices.entries)
      if (state.player(key)?.role?.nightAbility == NightAbility.hunt) value,
  ];
  final victim = _majority(wolfVotes);
  final cleared = state.copyWith(nightChoices: const {});
  if (victim == null) {
    return GameUpdate(cleared.copyWith(phase: Phase.day), [
      const NobodyDied(),
      DayBroke(state.round),
    ]);
  }
  return _kill(cleared, victim, DeathCause.night, Phase.day);
}

GameUpdate _kill(
  GameState state,
  PlayerId victimId,
  DeathCause cause,
  Phase nextPhase,
) {
  final victim = state.player(victimId)!;
  final shownRole = state.settings.revealRoleOnDeath ? victim.role : null;
  final after = state.copyWith(
    players: [
      for (final p in state.players)
        p.id == victimId ? p.copyWith(isAlive: false) : p,
    ],
    deaths: [
      ...state.deaths,
      Death(player: victimId, round: state.round, cause: cause),
    ],
  );
  final events = <GameEvent>[
    if (cause == DeathCause.night)
      PlayerKilled(victimId, shownRole)
    else
      PlayerEliminated(victimId, shownRole),
  ];
  final winner = _winner(after);
  if (winner != null) {
    return GameUpdate(after.copyWith(phase: Phase.ended, winner: winner), [
      ...events,
      GameEnded(winner),
    ]);
  }
  final round = nextPhase == Phase.night ? after.round + 1 : after.round;
  return GameUpdate(after.copyWith(phase: nextPhase, round: round), [
    ...events,
    if (nextPhase == Phase.night) NightFell(round) else DayBroke(round),
  ]);
}

Faction? _winner(GameState state) {
  final wolves = state.alive
      .where((p) => p.role?.faction == Faction.werewolves)
      .length;
  final others = state.alive.length - wolves;
  if (wolves == 0) return Faction.village;
  if (wolves >= others) return Faction.werewolves;
  return null;
}

GameUpdate _endDiscussion(GameState state) {
  _expectPhase(state, Phase.day);
  return GameUpdate(state.copyWith(phase: Phase.vote, votes: const {}), const [
    VotingStarted(),
  ]);
}

GameUpdate _castVote(GameState state, CastVote action) {
  _expectPhase(state, Phase.vote);
  final voter = _living(state, action.voter);
  final targetId = action.target;
  if (targetId != null) {
    final target = state.player(targetId) ?? _refuse(Violation.unknownPlayer);
    if (!target.isAlive || target.id == voter.id) {
      _refuse(Violation.invalidTarget);
    }
  }
  final next = state.copyWith(votes: {...state.votes, voter.id: targetId});
  if (next.alive.every((p) => next.votes.containsKey(p.id))) {
    return _resolveVote(next);
  }
  return GameUpdate(next);
}

GameUpdate _resolveVote(GameState state) {
  final cast = state.votes.values.whereType<PlayerId>().toList();
  final out = _majority(cast);
  final cleared = state.copyWith(votes: const {});
  if (out == null) {
    final round = state.round + 1;
    return GameUpdate(cleared.copyWith(phase: Phase.night, round: round), [
      NobodyEliminated(tie: cast.isNotEmpty),
      NightFell(round),
    ]);
  }
  return _kill(cleared, out, DeathCause.vote, Phase.night);
}

GameUpdate _timeout(GameState state) => switch (state.phase) {
  Phase.night => _resolveNight(state),
  Phase.day => _endDiscussion(state),
  Phase.vote => _resolveVote(state),
  _ => _refuse(Violation.wrongPhase),
};
