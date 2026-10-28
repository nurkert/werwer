import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:game_core/src/actions.dart';
import 'package:game_core/src/events.dart';
import 'package:game_core/src/model.dart';
import 'package:game_core/src/role.dart';
import 'package:game_core/src/settings.dart';
import 'package:game_core/src/violation.dart';

/// Longest allowed player name, in characters.
const maxNameLength = 24;

/// Characters a name may not hold: control characters (a terminal would run
/// them as commands) and the invisible marks that flip text direction (a
/// name could pretend to be another). Names reach every player's screen.
final _unprintable = RegExp(
  '[\u0000-\u001f\u007f-\u009f' // control characters
  '\u200b\u200e\u200f\u2028-\u202e\u2060-\u2069\ufeff]', // invisible
);

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
  BackMayor() => _backMayor(state, action),
  ProtectorGuard(:final protector, :final target) => _night(
    state,
    protector,
    NightAbility.protect,
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
  MarkDoor() => _markDoor(state, action),
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
  // A called step runs at least this long whatever happens in it, and no
  // longer once nobody is left to decide: a dead role's step and a quick
  // living role's look the same from outside.
  Phase.night when _called(state) && !calledStepPending(state) =>
    calledStepTime,
  // Whowolf's hunt with every pick in: over after a fixed time from its
  // start, the same in every night, so a quick pack shows nowhere.
  Phase.night
      when !_called(state) &&
          state.nightStep == NightStep.hunt &&
          everyonePicked(state) =>
    togetherHuntTime < state.settings.nightTime
        ? togetherHuntTime
        : state.settings.nightTime,
  Phase.night => switch (state.nightStep) {
    NightStep.hunt => state.settings.nightTime,
    NightStep.brew ||
    NightStep.link ||
    NightStep.inspect ||
    NightStep.protect => brewTime,
  },
  // The night's dead speak their last words first: the talk starts after.
  Phase.day =>
    state.settings.dayTime +
        (state.deaths.any((d) => d.round == state.round)
            ? lastWordsTime
            : Duration.zero),
  // A runoff is between few, and everyone has heard the arguments.
  Phase.vote when state.runoff.isNotEmpty => state.settings.voteTime ~/ 2,
  Phase.vote => state.settings.voteTime,
  Phase.hunterShot => shotTime,
  Phase.lobby || Phase.roleReveal || Phase.ended => null,
};

/// How long Whowolf's hunt lasts at least, counted from its start, once
/// everyone has picked (or as long as the night, if that is shorter).
const togetherHuntTime = Duration(seconds: 25);

/// Whether every living player has made a pick in the current night step.
bool everyonePicked(GameState state) =>
    state.alive.every((p) => state.nightChoices.containsKey(p.id));

/// How long the dead have for their last words, on every screen alike.
const lastWordsTime = Duration(seconds: 7);

/// How long a called step lasts at least, counted from its start, once
/// nobody is left to decide (or from the start, if its role is dead): as
/// long as a living player typically takes, so nobody can count who is
/// gone or how quickly someone picked (the host adds a little chance to a
/// dead role's step, see GameHost).
const calledStepTime = Duration(seconds: 16);

bool _called(GameState state) => state.settings.nightMode == NightMode.called;

/// Whether someone called in the current step still has to decide: a
/// living role that has not picked, or a pack that does not agree yet.
bool calledStepPending(GameState state) {
  final called = [
    for (final p in state.alive)
      if (nightTask(state, p.id) != null) p.id,
  ];
  if (called.any((p) => !state.nightChoices.containsKey(p))) return true;
  if (state.nightStep != NightStep.hunt) return false;
  // The pack agrees on one victim before the step can end; until the time
  // runs out they can change their minds.
  return {for (final p in called) state.nightChoices[p]!.first}.length > 1;
}

/// The steps of a called night, in order: every role in the game gets
/// its step, alive or not.
List<NightStep> calledSteps(GameState state) {
  bool has(Role role) => state.players.any((p) => p.role == role);
  return [
    if (state.round == 1 && has(Role.cupid)) NightStep.link,
    if (has(Role.protector)) NightStep.protect,
    NightStep.hunt,
    if (has(Role.seer)) NightStep.inspect,
    if (has(Role.witch)) NightStep.brew,
  ];
}

/// The night begins: the first step for the night mode.
GameState _nightfall(GameState state) => state.copyWith(
  nightStep: _called(state) ? calledSteps(state).first : NightStep.hunt,
);

/// What [player] is asked to do right now: their own ability when it
/// applies in this night step, otherwise a decoy. When the narrator calls
/// the roles, only whoever is called has a task; everyone else has their
/// eyes closed (`null`). `null` outside the night and for the dead.
NightAbility? nightTask(GameState state, PlayerId player) {
  final p = state.player(player);
  if (state.phase != Phase.night || p == null || !p.isAlive) return null;
  final ability = p.role?.nightAbility ?? NightAbility.decoy;
  if (_called(state)) {
    final step = switch (ability) {
      NightAbility.link => NightStep.link,
      NightAbility.hunt => NightStep.hunt,
      NightAbility.inspect => NightStep.inspect,
      NightAbility.brew => NightStep.brew,
      NightAbility.protect => NightStep.protect,
      NightAbility.decoy => null,
    };
    return step == state.nightStep ? ability : null;
  }
  final applies = switch (ability) {
    NightAbility.hunt ||
    NightAbility.inspect ||
    NightAbility.protect => state.nightStep == NightStep.hunt,
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
  // Eyes closed (a called night, not this one's turn): nothing to pick.
  final task = nightTask(state, actor) ?? _refuse(Violation.notYourAction);
  return switch (task) {
    NightAbility.hunt => WerewolfVote(actor, single()),
    NightAbility.inspect => SeerInspect(actor, single()),
    NightAbility.protect => ProtectorGuard(actor, single()),
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
  final victim = state.unguardedVictim;
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
  if (name.isEmpty ||
      name.length > maxNameLength ||
      taken ||
      _unprintable.hasMatch(name)) {
    _refuse(Violation.invalidName);
  }
  final count = state.players.length;
  return GameUpdate(
    state.copyWith(
      settings: state.settings.retimed(count, count + 1),
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
  final count = state.players.length;
  return GameUpdate(
    state.copyWith(
      settings: state.settings.retimed(count, count - 1),
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
    // Too many roles for this table: the ones that do not fit stay out.
    ...?(action.roles ?? state.settings.fittedFor(count).rolesFor(count)),
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
      secret: [
        for (var i = 0; i < secretLength; i++) action.random.nextInt(256),
      ],
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
  _nightfall(state.copyWith(phase: Phase.night, round: 1)),
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
    NightAbility.inspect ||
    NightAbility.link ||
    NightAbility.brew ||
    NightAbility.protect => true,
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
    // Himself too, but not last night's again.
    NightAbility.protect => targets.single.id != state.lastGuarded,
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
  // Whowolf's night: a step ends once everyone has picked, the hunt not
  // before [togetherHuntTime] (see timeLimit). A called step ends by its
  // time, so its length tells nobody anything.
  if (!_called(next) &&
      next.nightStep != NightStep.hunt &&
      everyonePicked(next)) {
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
  final victim = state.unguardedVictim;
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
GameUpdate _endStep(GameState state) {
  if (_called(state)) return _endCalledStep(state);
  return switch (state.nightStep) {
    NightStep.hunt => _endHunt(state),
    NightStep.brew ||
    NightStep.link ||
    NightStep.inspect ||
    NightStep.protect => _resolveNight(state),
  };
}

/// A called step is over: what it decided counts, and the narrator calls
/// the next role, or the night is resolved after the last.
GameUpdate _endCalledStep(GameState state) {
  final events = <GameEvent>[];
  var next = state;
  switch (state.nightStep) {
    case NightStep.protect:
      next = next.copyWith(
        guarded: _picks(state, NightAbility.protect).firstOrNull?.first,
      );
    case NightStep.link:
      for (final MapEntry(:key, :value) in state.nightChoices.entries) {
        if (nightTask(state, key) == NightAbility.link) {
          next = next.copyWith(lovers: value);
          events.add(LoversLinked(key, value[0], value[1]));
        }
      }
    case NightStep.hunt:
      next = next.copyWith(
        nightVictim: _majority(
          _picks(state, NightAbility.hunt).map((t) => t.first),
        ),
      );
    case NightStep.inspect:
      // The seer's look already counted when she picked.
      break;
    case NightStep.brew:
      return _resolveNight(state);
  }
  final steps = calledSteps(state);
  final at = steps.indexOf(state.nightStep);
  if (at + 1 >= steps.length) {
    final resolved = _resolveNight(next);
    return GameUpdate(resolved.state, [...events, ...resolved.events]);
  }
  final step = steps[at + 1];
  return GameUpdate(
    next.copyWith(nightStep: step, nightChoices: const {}),
    [...events, if (step == NightStep.brew) const BrewStepBegan()],
  );
}

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
    guarded: _picks(state, NightAbility.protect).firstOrNull?.first,
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

/// The players with the most votes, in seating order of [state]: one for
/// a clear result, several for a tie, none without votes.
List<PlayerId> _leaders(GameState state, Iterable<PlayerId> votes) {
  final tally = <PlayerId, int>{};
  for (final v in votes) {
    tally[v] = (tally[v] ?? 0) + 1;
  }
  if (tally.isEmpty) return const [];
  final top = tally.values.reduce((a, b) => a > b ? a : b);
  return [
    for (final p in state.players)
      if (tally[p.id] == top) p.id,
  ];
}

/// Bytes of [GameState.secret].
const secretLength = 32;

/// 32 bits of HMAC-SHA256 under the game's secret over [salt], the round,
/// [player] and [extra]: stable and serializable without a `Random`, and
/// without the secret no player can predict another's values from their
/// own. Each use has its own salt, so flocks, door signs and the mark's coin
/// do not depend on each other.
int _keyed(
  GameState state, {
  required String salt,
  PlayerId? player,
  List<int> extra = const [],
}) {
  final message = utf8.encode(
    [salt, state.round, player?.value ?? '', ...extra].join('|'),
  );
  final mac = Hmac(sha256, state.secret).convert(message).bytes;
  // Assembled by multiplication, not shifts: shifts are 32-bit on the web.
  return ((mac[0] * 256 + mac[1]) * 256 + mac[2]) * 256 + mac[3];
}

/// How many sheep run across [player]'s meadow in this night. Decided by the
/// game, not by the role: some nights bring a big flock, some only a few
/// sheep, so a low count in the morning is a hint at most, never proof.
int flockFor(GameState state, PlayerId player) {
  final u = _keyed(state, salt: 'flock', player: player) / 0xffffffff;
  // Skewed towards small flocks: a few players get very little each night.
  return minFlock + (u * u * (maxFlock - minFlock)).round();
}

/// The sign on [player]'s door in this night: [doorSignLength] symbols, each
/// `0 <= s < doorSignSymbols`, new every night. Only [player] is ever shown
/// it (see [GameSettings.doorSigns]).
List<int> doorSignFor(GameState state, PlayerId player) => List.unmodifiable([
  for (var i = 0; i < doorSignLength; i++)
    // Scaled down, not shifted: shifts are 32-bit on the web.
    _keyed(state, salt: 'door', player: player, extra: [i]) *
        doorSignSymbols ~/
        0x100000000,
]);

/// Whether a right door sign takes its player tonight: a coin, so a mark is
/// a threat, never a sure kill.
bool _markStrikes(GameState state) => _keyed(state, salt: 'mark') >= 0x80000000;

/// Records the pack's door sign attempt of tonight. Unlike the hunt pick it
/// is not a night choice: it neither ends the step nor counts as acting.
GameUpdate _markDoor(GameState state, MarkDoor action) {
  _expectPhase(state, Phase.night);
  final wolf = _living(state, action.actor);
  if (!state.settings.doorSignsInPlay) _refuse(Violation.disabled);
  if (nightTask(state, wolf.id) != NightAbility.hunt) {
    _refuse(Violation.notYourAction);
  }
  if (state.packMark != null) _refuse(Violation.markUsed);
  final target =
      state.player(action.target) ?? _refuse(Violation.unknownPlayer);
  if (!target.isAlive ||
      target.id == wolf.id ||
      target.role?.faction == Faction.werewolves) {
    _refuse(Violation.invalidTarget);
  }
  final sign = action.sign;
  if (sign.length != doorSignLength ||
      sign.any((s) => s < 0 || s >= doorSignSymbols)) {
    _refuse(Violation.outOfRange);
  }
  final real = doorSignFor(state, target.id);
  var correct = true;
  for (var i = 0; i < doorSignLength; i++) {
    if (sign[i] != real[i]) correct = false;
  }
  return GameUpdate(
    state.copyWith(packMark: (target: target.id, correct: correct)),
  );
}

GameUpdate _countSheep(GameState state, CountSheep action) {
  _expectPhase(state, Phase.night);
  _living(state, action.player);
  if (!state.settings.sheepInPlay) _refuse(Violation.disabled);
  if (action.sheep.abs() > maxSheepPerNight ||
      action.sheep > flockFor(state, action.player)) {
    _refuse(Violation.outOfRange);
  }
  return GameUpdate(
    state.copyWith(sheep: {...state.sheep, action.player: action.sheep}),
  );
}

/// Morning: the werewolves' victim dies unless the witch saved them, her
/// poison kills, a right door sign may kill, and the sheep counts become
/// public.
GameUpdate _resolveNight(GameState state) {
  // Shielded by the protector, the pack's victim lives (the witch did not
  // even see them).
  final victim = state.unguardedVictim;
  final protector = state.players
      .where((p) => p.role == Role.protector)
      .firstOrNull
      ?.id;
  final brew = state.nightStep == NightStep.brew
      ? _picks(state, NightAbility.brew).firstOrNull ?? const <PlayerId>[]
      : const <PlayerId>[];
  final healed = victim != null && brew.contains(victim);
  final poisoned = brew.where((t) => t != victim).firstOrNull;
  final counted = state.settings.sheepInPlay
      ? {for (final p in state.alive) p.id: state.sheep[p.id] ?? 0}
      : const <PlayerId, int>{};
  final witch = state.players
      .where((p) => p.role == Role.witch)
      .firstOrNull
      ?.id;
  final cleared = state.copyWith(
    chronicle: [
      ...state.chronicle,
      ChronicleEntry(
        round: state.round,
        kind: ChronicleKind.hunt,
        target: state.nightVictim,
      ),
      if (state.guarded != null)
        ChronicleEntry(
          round: state.round,
          kind: ChronicleKind.protect,
          actor: protector,
          target: state.guarded,
        ),
      if (healed)
        ChronicleEntry(
          round: state.round,
          kind: ChronicleKind.heal,
          actor: witch,
          target: victim,
        ),
      if (poisoned != null)
        ChronicleEntry(
          round: state.round,
          kind: ChronicleKind.poison,
          actor: witch,
          target: poisoned,
        ),
    ],
    nightStep: NightStep.hunt,
    nightChoices: const {},
    nightVictim: null,
    packMark: null,
    guarded: null,
    lastGuarded: state.guarded,
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
  // The witch only ever sees the pack's victim, so she cannot save a marked
  // player. Whoever dies tonight anyway (also of grief) is left alone.
  final mark = state.packMark;
  if (mark != null && mark.correct) {
    final dying = {for (final (id, _) in deaths) id};
    final target = mark.target;
    if (state.player(target)!.isAlive &&
        !dying.contains(target) &&
        !dying.contains(state.loverOf(target)) &&
        _markStrikes(state)) {
      deaths.add((target, DeathCause.night));
    }
  }
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
  final moved = state.copyWith(phase: then, round: round);
  return GameUpdate(then == Phase.night ? _nightfall(moved) : moved, [
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
  // The ballot for mayor closes with the talk: whoever leads alone wins,
  // a tie leaves the village without a mayor until tomorrow.
  final elected = state.electsMayor ? _elect(state) : null;
  final next = elected?.state ?? state;
  return GameUpdate(
    next.copyWith(phase: Phase.vote, votes: const {}, mayorVotes: const {}),
    [...?elected?.events, const VotingStarted()],
  );
}

/// Backs a candidate for mayor in today's open ballot. Once every living
/// player has backed someone and one leads alone, they are elected at once.
GameUpdate _backMayor(GameState state, BackMayor action) {
  _expectPhase(state, Phase.day);
  if (!state.electsMayor) _refuse(Violation.wrongPhase);
  final voter = _living(state, action.voter);
  final candidate = _living(state, action.candidate);
  final next = state.copyWith(
    mayorVotes: {...state.mayorVotes, voter.id: candidate.id},
  );
  if (next.alive.every((p) => next.mayorVotes.containsKey(p.id))) {
    return _elect(next) ?? GameUpdate(next);
  }
  return GameUpdate(next);
}

/// The ballot's single leader becomes mayor; `null` if nobody leads alone.
GameUpdate? _elect(GameState state) {
  final leaders = _leaders(state, state.mayorVotes.values);
  if (leaders.length != 1) return null;
  return GameUpdate(
    state.copyWith(mayor: leaders.single, mayorVotes: const {}),
    [MayorElected(leaders.single)],
  );
}

GameUpdate _castVote(GameState state, CastVote action) {
  _expectPhase(state, Phase.vote);
  final voter = _living(state, action.voter);
  final targetId = action.target;
  if (targetId != null) {
    final target = state.player(targetId) ?? _refuse(Violation.unknownPlayer);
    if (!target.isAlive ||
        target.id == voter.id ||
        (state.runoff.isNotEmpty && !state.runoff.contains(target.id))) {
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
  // The mayor's vote counts twice.
  final mayor = state.mayor;
  final cast = [
    for (final MapEntry(:key, :value) in state.votes.entries)
      if (value != null) ...[value, if (key == mayor) value],
  ];
  final leaders = _leaders(state, cast);
  final cleared = state.copyWith(
    votes: const {},
    runoff: const [],
    chronicle: [
      ...state.chronicle,
      for (final p in state.alive)
        if (state.votes.containsKey(p.id))
          ChronicleEntry(
            round: state.round,
            kind: ChronicleKind.vote,
            actor: p.id,
            target: state.votes[p.id],
            runoff: state.runoff.isNotEmpty,
          ),
    ],
  );
  if (leaders.length > 1 &&
      state.runoff.isEmpty &&
      state.settings.tieRule == TieRule.runoff) {
    // One more vote, between the tied only; a second tie spares them all.
    return GameUpdate(cleared.copyWith(runoff: leaders), [
      RunoffStarted(leaders),
    ]);
  }
  final out = leaders.length == 1 ? leaders.single : null;
  if (out == null) {
    final round = state.round + 1;
    return GameUpdate(
      _nightfall(cleared.copyWith(phase: Phase.night, round: round)),
      [
        NobodyEliminated(tie: cast.isNotEmpty),
        NightFell(round),
      ],
    );
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
