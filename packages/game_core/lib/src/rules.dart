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
  ChoosePersona() => _choosePersona(state, action),
  SwapSeats() => _swapSeats(state, action),
  ChangeSettings() => _changeSettings(state, action),
  StartGame() => _startGame(state, action),
  ConfirmRole() => _confirmRole(state, action),
  WerewolfVote(:final wolf, :final target) => _night(
    state,
    wolf,
    NightAbility.hunt,
    [target],
  ),
  SeerInspect(:final seer, :final target) => _night(
    state,
    seer,
    NightAbility.inspect,
    [target],
  ),
  CupidLink(:final cupid, :final first, :final second) => _night(
    state,
    cupid,
    NightAbility.link,
    [first, second],
  ),
  WitchBrew() => _brew(state, action),
  NightDecoy(:final player, :final target) => _night(
    state,
    player,
    NightAbility.decoy,
    [target],
  ),
  HunterShoot() => _shoot(state, action),
  CountSheep() => _countSheep(state, action),
  EndDiscussion() => _endDiscussion(state),
  CastVote() => _castVote(state, action),
  PhaseTimeout() => _timeout(state),
};

/// How long the witch's step of a night lasts.
const brewTime = Duration(seconds: 30);

/// How long the dying hunter has to take aim.
const shotTime = Duration(seconds: 30);

/// How long the current phase (or night step) may take before a
/// [PhaseTimeout] resolves it; `null` where the rules set no limit (the
/// host decides how long players may look at their role).
Duration? timeLimit(GameState state) => switch (state.phase) {
  Phase.night => switch (state.nightStep) {
    NightStep.hunt => state.settings.nightTime,
    NightStep.brew => brewTime,
  },
  Phase.day => state.settings.dayTime,
  Phase.vote => state.settings.voteTime,
  Phase.hunterShot => shotTime,
  Phase.lobby || Phase.roleReveal || Phase.ended => null,
};

/// What [player] is asked to do right now: their own ability when it
/// applies in this night step, otherwise a decoy. `null` outside the night
/// and for the dead.
NightAbility? nightTask(GameState state, PlayerId player) {
  final p = state.player(player);
  if (state.phase != Phase.night || p == null || !p.isAlive) return null;
  final ability = p.role?.nightAbility ?? NightAbility.decoy;
  final applies = switch (ability) {
    NightAbility.hunt ||
    NightAbility.inspect => state.nightStep == NightStep.hunt,
    NightAbility.link => state.nightStep == NightStep.hunt && state.round == 1,
    NightAbility.brew => state.nightStep == NightStep.brew,
    NightAbility.decoy => true,
  };
  return applies ? ability : NightAbility.decoy;
}

/// The action for [actor]'s night pick of [targets].
///
/// Every night screen sends the same kind of pick; [nightTask] decides what
/// it means. Most tasks take one target, cupid two; the witch picks
/// tonight's victim to heal them and anyone else to poison them, both or
/// none.
///
/// Throws a [RuleViolation] if the pick does not fit the task.
GameAction nightAction(
  GameState state,
  PlayerId actor,
  List<PlayerId> targets,
) {
  _expectPhase(state, Phase.night);
  _living(state, actor);
  PlayerId single() =>
      targets.length == 1 ? targets.single : _refuse(Violation.invalidTarget);
  return switch (nightTask(state, actor)!) {
    NightAbility.hunt => WerewolfVote(actor, single()),
    NightAbility.inspect => SeerInspect(actor, single()),
    NightAbility.decoy => NightDecoy(actor, single()),
    NightAbility.link => switch (targets) {
      [final a, final b] => CupidLink(actor, a, b),
      _ => _refuse(Violation.invalidTarget),
    },
    NightAbility.brew => _brewAction(state, actor, targets),
  };
}

/// The witch's pick: tonight's victim means the healing potion, anyone else
/// the poison.
WitchBrew _brewAction(GameState state, PlayerId witch, List<PlayerId> picks) {
  final victim = state.nightVictim;
  final others = [
    for (final t in picks)
      if (t != victim) t,
  ];
  if (picks.length > 2 || others.length > 1) _refuse(Violation.invalidTarget);
  return WitchBrew(
    witch,
    heal: victim != null && picks.contains(victim),
    poison: others.firstOrNull,
  );
}

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
        Player(
          id: action.player,
          name: name,
          persona: _persona(state, action.player, action.persona),
        ),
      ],
    ),
    [PlayerJoined(action.player)],
  );
}

/// [wish] if it is free (or nothing is free any more), else the first free
/// persona. Personas repeat only once all are taken.
Persona _persona(GameState state, PlayerId player, Persona? wish) {
  final taken = {
    for (final p in state.players)
      if (p.id != player) p.persona,
  };
  final free = Persona.values.where((p) => !taken.contains(p));
  if (wish != null && (free.isEmpty || !taken.contains(wish))) return wish;
  if (wish != null) _refuse(Violation.personaTaken);
  return free.firstOrNull ??
      Persona.values[state.players.length % Persona.values.length];
}

GameUpdate _choosePersona(GameState state, ChoosePersona action) {
  _expectPhase(state, Phase.lobby);
  if (state.player(action.player) == null) _refuse(Violation.unknownPlayer);
  if (!state.settings.personaChoice) _refuse(Violation.disabled);
  final persona = _persona(state, action.player, action.persona);
  return GameUpdate(
    state.copyWith(
      players: [
        for (final p in state.players)
          p.id == action.player ? p.copyWith(persona: persona) : p,
      ],
    ),
  );
}

GameUpdate _swapSeats(GameState state, SwapSeats action) {
  _expectPhase(state, Phase.lobby);
  final a = state.player(action.first) ?? _refuse(Violation.unknownPlayer);
  final b = state.player(action.second) ?? _refuse(Violation.unknownPlayer);
  return GameUpdate(
    state.copyWith(
      players: [
        for (final p in state.players)
          p.id == a.id
              ? b
              : p.id == b.id
              ? a
              : p,
      ],
    ),
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

GameUpdate _changeSettings(GameState state, ChangeSettings action) {
  _expectPhase(state, Phase.lobby);
  action.settings.validate();
  return GameUpdate(state.copyWith(settings: action.settings));
}

GameUpdate _startGame(GameState state, StartGame action) {
  _expectPhase(state, Phase.lobby);
  final count = state.players.length;
  if (count < minPlayers || count > maxPlayers) {
    _refuse(Violation.playerCount);
  }
  final roles = [
    ...?(action.roles ?? state.settings.rolesFor(count)),
  ];
  final wolves = roles.where((r) => r.faction == Faction.werewolves).length;
  final twice = specialRoles.any((s) => roles.where((r) => r == s).length > 1);
  if (roles.length != count ||
      wolves == 0 ||
      wolves >= count - wolves ||
      twice) {
    _refuse(Violation.invalidRoles);
  }
  roles.shuffle(action.random);
  return GameUpdate(
    state.copyWith(
      phase: Phase.roleReveal,
      seed: action.random.nextInt(1 << 32),
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
  return _beginFirstNight(state.copyWith(confirmed: confirmed));
}

/// Everyone has seen their role, or the time to look ran out (someone's
/// phone is away; they can still look later from their own view).
GameUpdate _beginFirstNight(GameState state) => GameUpdate(
  state.copyWith(phase: Phase.night, round: 1),
  const [NightFell(1)],
);

/// Checks and records a night pick; the step ends once every living
/// player has picked.
GameUpdate _night(
  GameState state,
  PlayerId actorId,
  NightAbility ability,
  List<PlayerId> targetIds,
) {
  _expectPhase(state, Phase.night);
  final actor = _living(state, actorId);
  if (nightTask(state, actor.id) != ability) _refuse(Violation.notYourAction);
  final targets = [
    for (final id in targetIds)
      state.player(id) ?? _refuse(Violation.unknownPlayer),
  ];
  if (targets.any((t) => !t.isAlive)) _refuse(Violation.invalidTarget);
  final once = switch (ability) {
    NightAbility.inspect || NightAbility.link || NightAbility.brew => true,
    NightAbility.hunt || NightAbility.decoy => false,
  };
  if (once && state.nightChoices.containsKey(actor.id)) {
    _refuse(Violation.alreadyActed);
  }
  final valid = switch (ability) {
    // Cupid may link himself; the two must differ.
    NightAbility.link => targets[0].id != targets[1].id,
    NightAbility.hunt =>
      targets.single.id != actor.id &&
          targets.single.role?.faction != Faction.werewolves,
    NightAbility.inspect || NightAbility.decoy => targets.single.id != actor.id,
    // Checked by _brew.
    NightAbility.brew => true,
  };
  if (!valid) _refuse(Violation.invalidTarget);
  final events = <GameEvent>[];
  var next = state;
  if (ability == NightAbility.inspect) {
    final target = targets.single;
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
    nightChoices: {...state.nightChoices, actor.id: targetIds},
  );
  if (next.alive.every((p) => next.nightChoices.containsKey(p.id))) {
    final ended = _endStep(next);
    return GameUpdate(ended.state, [...events, ...ended.events]);
  }
  return GameUpdate(next, events);
}

GameUpdate _brew(GameState state, WitchBrew action) {
  _expectPhase(state, Phase.night);
  final witch = _living(state, action.witch);
  if (nightTask(state, witch.id) != NightAbility.brew) {
    _refuse(Violation.notYourAction);
  }
  final victim = state.nightVictim;
  if (action.heal) {
    if (victim == null) _refuse(Violation.invalidTarget);
    if (state.potionsUsed.contains(Potion.heal)) {
      _refuse(Violation.alreadyActed);
    }
  }
  final poison = action.poison;
  if (poison != null) {
    if (state.potionsUsed.contains(Potion.poison)) {
      _refuse(Violation.alreadyActed);
    }
    // Poisoning tonight's victim would change nothing: a pick of the
    // victim always means the healing potion.
    if (poison == witch.id || poison == victim) {
      _refuse(Violation.invalidTarget);
    }
  }
  return _night(state, witch.id, NightAbility.brew, [
    if (action.heal) victim!,
    ?poison,
  ]);
}

/// Ends the current night step: after the werewolves the witch decides (in
/// games with a witch), after her the night is resolved.
GameUpdate _endStep(GameState state) => switch (state.nightStep) {
  NightStep.hunt => _endHunt(state),
  NightStep.brew => _resolveNight(state),
};

/// The picks of the living players whose task tonight is [ability].
Iterable<List<PlayerId>> _picks(GameState state, NightAbility ability) => [
  for (final MapEntry(:key, :value) in state.nightChoices.entries)
    if (nightTask(state, key) == ability) value,
];

GameUpdate _endHunt(GameState state) {
  final victim = _majority(
    _picks(state, NightAbility.hunt).map((t) => t.first),
  );
  final events = <GameEvent>[];
  var lovers = state.lovers;
  for (final MapEntry(:key, :value) in state.nightChoices.entries) {
    if (nightTask(state, key) == NightAbility.link) {
      lovers = value;
      events.add(LoversLinked(key, value[0], value[1]));
    }
  }
  final next = state.copyWith(
    nightVictim: victim,
    lovers: lovers,
    nightChoices: const {},
  );
  if (!state.hasWitch) {
    final resolved = _resolveNight(next);
    return GameUpdate(resolved.state, [...events, ...resolved.events]);
  }
  return GameUpdate(next.copyWith(nightStep: NightStep.brew), [
    ...events,
    const BrewStepBegan(),
  ]);
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

/// How many sheep run across [player]'s meadow in this night. Decided by the
/// game, not by the role: some nights bring a big flock, some only a few
/// sheep, so a low count in the morning is a hint at most, never proof.
int flockFor(GameState state, PlayerId player) {
  // FNV-1a over seed, round and player id: stable, serializable, no Random.
  var hash = 0x811c9dc5;
  void mix(int value) {
    hash = ((hash ^ (value & 0xff)) * 0x01000193) & 0xffffffff;
  }

  for (var shift = 0; shift < 32; shift += 8) {
    mix(state.seed >> shift);
  }
  mix(state.round);
  player.value.codeUnits.forEach(mix);
  final u = hash / 0xffffffff;
  // Skewed towards small flocks: a few players get very little each night.
  return minFlock + (u * u * (maxFlock - minFlock)).round();
}

GameUpdate _countSheep(GameState state, CountSheep action) {
  _expectPhase(state, Phase.night);
  _living(state, action.player);
  if (!state.settings.sheepCounting) _refuse(Violation.disabled);
  if (action.sheep.abs() > maxSheepPerNight ||
      action.sheep > flockFor(state, action.player)) {
    _refuse(Violation.outOfRange);
  }
  return GameUpdate(
    state.copyWith(sheep: {...state.sheep, action.player: action.sheep}),
  );
}

/// Morning: the werewolves' victim dies unless the witch saved them, her
/// poison kills, and the sheep counts become public.
GameUpdate _resolveNight(GameState state) {
  final victim = state.nightVictim;
  final brew = state.nightStep == NightStep.brew
      ? _picks(state, NightAbility.brew).firstOrNull ?? const <PlayerId>[]
      : const <PlayerId>[];
  final healed = victim != null && brew.contains(victim);
  final poisoned = brew.where((t) => t != victim).firstOrNull;
  final counted = state.settings.sheepCounting
      ? {for (final p in state.alive) p.id: state.sheep[p.id] ?? 0}
      : const <PlayerId, int>{};
  final cleared = state.copyWith(
    nightStep: NightStep.hunt,
    nightChoices: const {},
    nightVictim: null,
    potionsUsed: {
      ...state.potionsUsed,
      if (healed) Potion.heal,
      if (poisoned != null) Potion.poison,
    },
    sheep: const {},
    lastNightSheep: counted,
    dreams: {
      ...state.dreams,
      for (final MapEntry(:key, :value) in counted.entries)
        key: (state.dreams[key] ?? 0) + value,
    },
  );
  final deaths = [
    if (victim != null && !healed) (victim, DeathCause.night),
    if (poisoned != null) (poisoned, DeathCause.night),
  ];
  if (deaths.isEmpty) {
    return GameUpdate(cleared.copyWith(phase: Phase.day), [
      const NobodyDied(),
      DayBroke(state.round),
    ]);
  }
  return _die(cleared, deaths, then: Phase.day);
}

/// Kills [deaths] and everyone they take along: a lover dies of grief, a
/// dying hunter gets his shot ([Phase.hunterShot]) before the game goes on
/// to [then] or ends.
GameUpdate _die(
  GameState state,
  List<(PlayerId, DeathCause)> deaths, {
  required Phase then,
}) {
  var next = state;
  final events = <GameEvent>[];
  final queue = [...deaths];
  PlayerId? shooter;
  while (queue.isNotEmpty) {
    final (id, cause) = queue.removeAt(0);
    final dead = next.player(id)!;
    if (!dead.isAlive) continue;
    next = next.copyWith(
      players: [
        for (final p in next.players)
          p.id == id ? p.copyWith(isAlive: false) : p,
      ],
      deaths: [
        ...next.deaths,
        Death(player: id, round: next.round, cause: cause),
      ],
    );
    final shown = next.settings.revealRoleOnDeath ? dead.role : null;
    events.add(switch (cause) {
      DeathCause.night => PlayerKilled(id, shown),
      DeathCause.vote => PlayerEliminated(id, shown),
      DeathCause.heartbreak => LoverDied(id, shown),
      DeathCause.shot => PlayerShot(id, shown),
    });
    final lover = next.loverOf(id);
    if (lover != null) queue.add((lover, DeathCause.heartbreak));
    if (dead.role == Role.hunter) shooter = id;
  }
  if (shooter != null && next.alive.isNotEmpty) {
    return GameUpdate(
      next.copyWith(
        phase: Phase.hunterShot,
        shooter: shooter,
        afterShot: then,
      ),
      [...events, HunterAims(shooter)],
    );
  }
  return _goOn(next, then, events);
}

/// Ends the game if a side has won, else moves on to [then].
GameUpdate _goOn(GameState state, Phase then, List<GameEvent> events) {
  final winner = _winner(state);
  if (winner != null) {
    return GameUpdate(state.copyWith(phase: Phase.ended, winner: winner), [
      ...events,
      GameEnded(winner),
    ]);
  }
  final round = then == Phase.night ? state.round + 1 : state.round;
  return GameUpdate(state.copyWith(phase: then, round: round), [
    ...events,
    if (then == Phase.night) NightFell(round) else DayBroke(round),
  ]);
}

GameUpdate _shoot(GameState state, HunterShoot action) {
  _expectPhase(state, Phase.hunterShot);
  if (action.hunter != state.shooter) _refuse(Violation.notYourAction);
  final targetId = action.target;
  if (targetId != null) {
    final target = state.player(targetId) ?? _refuse(Violation.unknownPlayer);
    if (!target.isAlive) _refuse(Violation.invalidTarget);
  }
  final then = state.afterShot ?? Phase.day;
  final cleared = state.copyWith(shooter: null, afterShot: null);
  if (targetId == null) {
    return _goOn(cleared, then, [HunterSpared(action.hunter)]);
  }
  return _die(cleared, [(targetId, DeathCause.shot)], then: then);
}

/// A couple cupid linked across the sides, while both live.
Set<PlayerId>? _mixedCouple(GameState state) {
  if (state.lovers case [final a, final b]) {
    final first = state.player(a)!;
    final second = state.player(b)!;
    if (first.isAlive &&
        second.isAlive &&
        first.role?.faction != second.role?.faction) {
      return {a, b};
    }
  }
  return null;
}

Faction? _winner(GameState state) {
  final alive = state.alive.toList();
  final couple = _mixedCouple(state);
  if (couple != null && alive.length == 2) return Faction.lovers;
  bool isWolf(Player p) => p.role?.faction == Faction.werewolves;
  if (!alive.any(isWolf)) return Faction.village;
  // A werewolf in a mixed couple no longer plays for the pack.
  final wolves = alive
      .where((p) => isWolf(p) && !(couple?.contains(p.id) ?? false))
      .length;
  if (wolves > 0 && wolves >= alive.length - wolves) return Faction.werewolves;
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
  return _die(cleared, [(out, DeathCause.vote)], then: Phase.night);
}

GameUpdate _timeout(GameState state) => switch (state.phase) {
  Phase.roleReveal => _beginFirstNight(state),
  Phase.night => _endStep(state),
  Phase.day => _endDiscussion(state),
  Phase.vote => _resolveVote(state),
  Phase.hunterShot => _shoot(state, HunterShoot(state.shooter!, null)),
  _ => _refuse(Violation.wrongPhase),
};
