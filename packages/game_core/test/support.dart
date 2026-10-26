import 'dart:math';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

const names = ['Ada', 'Bo', 'Cem', 'Dina', 'Eli', 'Fynn', 'Gul', 'Hans'];

PlayerId id(int i) => PlayerId('p$i');

int seatOf(PlayerId player) => int.parse(player.value.substring(1));

/// A lobby with [count] players p0…p(count-1).
GameState lobby(int count, {GameSettings settings = const GameSettings()}) {
  var state = GameState.lobby(settings: settings);
  for (var i = 0; i < count; i++) {
    state = apply(state, AddPlayer(id(i), names[i])).state;
  }
  return state;
}

/// A started game with fixed roles in seat order, everyone confirmed.
GameState night(
  List<Role> roles, {
  GameSettings settings = const GameSettings(),
}) {
  // Dealing shuffles; for readable tests, put the roles back in seat order.
  var state = apply(
    lobby(roles.length, settings: settings),
    StartGame(random: Random(1), roles: roles),
  ).state;
  state = GameState(
    players: [
      for (var i = 0; i < roles.length; i++)
        state.players[i].copyWith(role: roles[i]),
    ],
    phase: state.phase,
    round: state.round,
    settings: settings,
  );
  for (var i = 0; i < roles.length; i++) {
    state = apply(state, ConfirmRole(id(i))).state;
  }
  return state;
}

/// Plays the current night to its end. In the werewolves' step, seats in
/// [targets] pick that seat; cupid links [link] (default: the first two
/// others). In the witch's step she picks [brew] (default: nothing).
/// Everyone else decoys on the first other living player.
GameUpdate playNight(
  GameState state,
  Map<int, int> targets, {
  List<int> brew = const [],
  List<int>? link,
}) {
  final round = state.round;
  final events = <GameEvent>[];
  var current = state;
  while (current.phase == Phase.night && current.round == round) {
    final step = current.nightStep;
    for (final p in current.alive.toList()) {
      if (current.phase != Phase.night || current.nightStep != step) break;
      final i = seatOf(p.id);
      final explicit = step == NightStep.hunt ? targets[i] : null;
      if (explicit == null && current.nightChoices.containsKey(p.id)) {
        continue;
      }
      final others = [
        for (final o in current.alive)
          if (o.id != p.id) o.id,
      ];
      final picks = switch (nightTask(current, p.id)!) {
        NightAbility.brew => [for (final b in brew) id(b)],
        NightAbility.link =>
          link == null
              ? others.take(2).toList()
              : [for (final l in link) id(l)],
        _ => [if (explicit != null) id(explicit) else others.first],
      };
      final update = apply(current, nightAction(current, p.id, picks));
      events.addAll(update.events);
      current = update.state;
    }
  }
  return GameUpdate(current, events);
}

GameUpdate playVote(GameState state, Map<int, int?> votes) {
  var update = apply(state, const EndDiscussion());
  final events = [...update.events];
  for (final MapEntry(:key, :value) in votes.entries) {
    update = apply(
      update.state,
      CastVote(id(key), value == null ? null : id(value)),
    );
    events.addAll(update.events);
  }
  return GameUpdate(update.state, events);
}

/// Everyone alive votes for [out] (who votes for someone else).
GameUpdate voteOut(GameState state, int out) => playVote(state, {
  for (final p in state.alive)
    seatOf(p.id): seatOf(p.id) == out
        ? seatOf(state.alive.firstWhere((o) => o.id != p.id).id)
        : out,
});

Matcher refuses(Violation reason) => throwsA(
  isA<RuleViolation>().having((e) => e.reason, 'reason', reason),
);

/// Checks every player's view of [state] against what they may know.
void expectNoLeaks(GameState state) {
  final over = state.phase == Phase.ended;
  for (final viewer in state.players) {
    final view = viewFor(state, viewer.id);
    final isWolf = viewer.role == Role.werewolf;
    for (final seat in view.seats) {
      final p = state.player(seat.id)!;
      final allowed =
          p.id == viewer.id ||
          (isWolf && p.role == Role.werewolf) ||
          (!p.isAlive && state.settings.revealRoleOnDeath) ||
          over;
      if (!allowed) {
        expect(seat.role, isNull, reason: '${viewer.id} sees ${p.id}');
      }
    }
    expect(view.yourRole, viewer.role);
    if (!isWolf) expect(view.packChoices, isEmpty);
    if (viewer.role != Role.seer) expect(view.seerResults, isEmpty);
    // Lovers know each other, cupid knows them; nobody else.
    if (!over &&
        viewer.role != Role.cupid &&
        !state.lovers.contains(viewer.id)) {
      expect(view.couple, isEmpty, reason: '${viewer.id} sees the lovers');
    }
    // Only the living witch sees the victim and her potions.
    if (viewer.role != Role.witch || !viewer.isAlive) {
      expect(view.victim, isNull, reason: '${viewer.id} sees the victim');
      expect(view.potions, isEmpty);
    }
    if (view.victim != null) expect(state.nightStep, NightStep.brew);
    // Own choices only.
    expect(view.yourNightTargets, state.nightChoices[viewer.id] ?? []);
    expect(view.yourVote, state.votes[viewer.id]);
  }
  final public = publicView(state);
  expect(public.packChoices, isEmpty);
  expect(public.victim, isNull);
  expect(public.potions, isEmpty);
  if (!over) {
    expect(public.couple, isEmpty);
    for (final seat in public.seats) {
      if (seat.isAlive) expect(seat.role, isNull);
    }
  }
}
