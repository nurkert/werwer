import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/src/game/narration_script.dart';
import 'package:whowolf/src/game/walking_narrator.dart';

/// One spoken moment with the screen change it belongs to.
typedef Told = ({int change, Phase phase, String key, PlayerId? to});

/// Plays a random game through the rules (every role, the mayor, ties and
/// runoffs, both nights) and records what the narrator says on every
/// screen change, as every player's phone would plan it.
({List<Told> story, GameState end, int nights}) _play(int seed) {
  final random = Random(seed);
  final count = 5 + random.nextInt(8);
  final roles = {
    for (final r in specialRoles)
      if (random.nextBool()) r,
  };
  final settings = GameSettings(
    roles: roles,
    narratorMode: NarratorMode.always,
    nightMode: random.nextBool() ? NightMode.called : NightMode.together,
    mayor: random.nextBool(),
    tieRule: random.nextBool() ? TieRule.runoff : TieRule.nobody,
    revealRoleOnDeath: random.nextInt(4) > 0,
    sheepCounting: random.nextBool(),
  );
  var state = GameState.lobby(settings: settings);
  for (var i = 0; i < count; i++) {
    state = apply(state, AddPlayer(PlayerId('p$i'), 'P$i')).state;
  }
  state = apply(state, StartGame(random: random)).state;
  final ids = [for (final p in state.players) p.id];
  final before = <PlayerId, PlayerView?>{for (final id in ids) id: null};
  final story = <Told>[];
  var change = 0;
  var nights = 0;

  void listen() {
    change++;
    List<Spoken>? first;
    for (final id in ids) {
      final view = viewFor(state, id);
      final spoken = spokenMoments(before[id], view);
      before[id] = view;
      // Every phone says the same: the narrator knows only what all see.
      if (first == null) {
        first = spoken;
        for (final s in spoken) {
          story.add((change: change, phase: view.phase, key: s.key, to: s.to));
        }
      } else {
        expect(spoken, first, reason: 'seed $seed: the same on every phone');
      }
    }
  }

  listen();
  PlayerId pick(Iterable<Player> from) {
    final list = from.toList();
    return list[random.nextInt(list.length)].id;
  }

  for (var i = 0; i < 4000 && state.phase != Phase.ended; i++) {
    final alive = state.alive.toList();
    final actor = alive[random.nextInt(alive.length)].id;
    final target = pick(alive);
    final action = switch (state.phase) {
      Phase.roleReveal => ConfirmRole(pick(state.players)),
      _ when random.nextInt(12) == 0 => const PhaseTimeout(),
      Phase.night => switch (random.nextInt(6)) {
        0 => WerewolfVote(actor, target),
        1 => SeerInspect(actor, target),
        2 => CupidLink(actor, target, pick(alive)),
        3 => WitchBrew(
          actor,
          heal: random.nextBool(),
          poison: random.nextBool() ? target : null,
        ),
        _ => NightDecoy(actor, target),
      },
      Phase.day => switch (random.nextInt(5)) {
        0 => const EndDiscussion(),
        _ => BackMayor(actor, target),
      },
      Phase.vote => CastVote(actor, random.nextInt(8) == 0 ? null : target),
      Phase.hunterShot => HunterShoot(state.shooter ?? actor, target),
      Phase.lobby || Phase.ended => const PhaseTimeout(),
    };
    final GameUpdate update;
    try {
      update = apply(state, action);
    } on RuleViolation {
      continue;
    }
    if (update.state.phase != state.phase && state.phase == Phase.night) {
      nights++;
    }
    if (identical(update.state, state)) continue;
    state = update.state;
    listen();
  }
  return (story: story, end: state, nights: nights);
}

void main() {
  final script =
      jsonDecode(File('../tool/voice/script.json').readAsStringSync())
          as Map<String, Object?>;
  final scripted = {
    for (final m in script['moments']! as List<Object?>)
      (m! as Map<String, Object?>)['key']! as String,
  };
  final manifest =
      jsonDecode(File('assets/voice/manifest.json').readAsStringSync())
          as Map<String, Object?>;

  test('in hundreds of games every death is told once, in a whole story, '
      'the same on every phone', () {
    var games = 0;
    for (var seed = 0; seed < 400; seed++) {
      final (:story, :end, :nights) = _play(seed);
      if (end.phase != Phase.ended) continue;
      games++;
      final why = 'seed $seed: ${[for (final t in story) t.key]}';
      int told(String key, PlayerId? to) =>
          story.where((t) => t.key == key && t.to == to).length;
      for (final t in story) {
        expect(scripted, contains(t.key), reason: why);
      }
      for (final d in end.deaths) {
        final player = end.player(d.player)!;
        switch (d.cause) {
          case DeathCause.vote:
            expect(told('voted_out', d.player), 1, reason: why);
          case DeathCause.heartbreak:
            expect(told('grief', d.player), 1, reason: why);
          case DeathCause.shot:
            expect(told('shot', d.player), 1, reason: why);
          case DeathCause.night:
            break;
        }
        // What the dead were, once: by their role's line, or for a hunter
        // about to shoot by the hunter's. With roles kept secret, only the
        // end tells them (for the deaths that end the game).
        final role = 'role_${player.role!.name}';
        final aimed = told('hunter', d.player);
        expect(
          told(role, d.player) + aimed,
          end.settings.revealRoleOnDeath || aimed > 0
              ? 1
              : inInclusiveRange(0, 1),
          reason: '$why: ${d.player} ${d.cause}',
        );
      }
      // One morning for every night that ended, and its news.
      final mornings = story.where((t) => t.key.startsWith('morning')).length;
      expect(mornings, nights, reason: why);
      expect(
        story.where((t) => t.key.startsWith('died_')).length,
        nights,
        reason: why,
      );
      // A vote ends in a verdict or a tie, said once.
      final verdicts = story.where(
        (t) => t.key == 'voted_out' || t.key == 'vote_tie',
      );
      expect(
        verdicts.length,
        story.where((t) => t.key == 'vote' || t.key == 'vote_late').length,
        reason: why,
      );
      expect(story.last.key, startsWith('win_'), reason: why);
      // The mayor is named when chosen, never twice for one choice.
      for (final (i, t) in story.indexed) {
        if (t.key != 'mayor') continue;
        expect(
          story.skip(i + 1).takeWhile((n) => n.key != 'mayor').length,
          greaterThan(0),
          reason: why,
        );
      }
    }
    expect(games, greaterThan(300));
  });

  test('every moment of the story has a recording, or waits for its '
      'first and stays silent as a whole', () {
    // Written in the script, not recorded yet (tool/voice/README.md).
    const awaiting = {'runoff', 'shot', 'mayor'};
    for (final lang in ['de', 'en']) {
      final recorded = (manifest[lang]! as Map<String, Object?>).keys.toSet();
      expect(
        scripted.difference(recorded),
        awaiting,
        reason: '$lang: recordings missing beyond those awaited',
      );
    }
  });

  test('a whole evening flows: no dead air between the lines, and pauses '
      'inside them no longer than a breath', () async {
    final bank = await _bank(manifest);
    for (var seed = 0; seed < 60; seed++) {
      final (:story, end: _, nights: _) = _play(seed);
      final changes = <int, List<Told>>{};
      for (final t in story) {
        (changes[t.change] ??= []).add(t);
      }
      for (final moments in changes.values) {
        final planned = WalkingNarrator(bank: bank, room: '4711').plan(
          moments: [for (final t in moments) (key: t.key, to: t.to)],
          language: NarratorLanguage.de,
          round: 1,
          startMs: 0,
          speakers: const [
            PlayerId('a'),
            PlayerId('b'),
            PlayerId('c'),
            PlayerId('d'),
            PlayerId('e'),
            PlayerId('f'),
            PlayerId('g'),
            PlayerId('h'),
          ],
          stage: NarratorStage.theater,
        );
        for (var i = 1; i < planned.length; i++) {
          final gap =
              planned[i].at - planned[i - 1].at - planned[i - 1].clip.ms;
          // A breath, a walk of a few footsteps, or time to close the
          // eyes; never more.
          expect(
            gap,
            inInclusiveRange(600, 2000),
            reason: 'seed $seed: ${planned[i - 1].key} -> ${planned[i].key}',
          );
        }
      }
    }
    for (final lang in ['de', 'en']) {
      for (final variants in (manifest[lang]! as Map<String, Object?>).values) {
        for (final clip in variants! as List<Object?>) {
          final c = clip! as Map<String, Object?>;
          for (final p in (c['pauses'] as List<Object?>?) ?? []) {
            final pause = p! as List<Object?>;
            expect(
              (pause[1]! as int) - (pause[0]! as int),
              lessThanOrEqualTo(800),
              reason: '${c['file']}: a pause like a broken-off voice',
            );
          }
        }
      }
    }
  });
}

/// The build's recordings as the app reads them.
Future<VoiceBank> _bank(Map<String, Object?> manifest) async {
  Clip clip(Object? json) {
    final v = json! as Map<String, Object?>;
    return (
      file: v['file']! as String,
      ms: v['ms']! as int,
      only: {for (final f in (v['if'] as List<Object?>?) ?? []) f! as String},
      pauses: [
        for (final p in (v['pauses'] as List<Object?>?) ?? [])
          (
            start: (p! as List<Object?>)[0]! as int,
            end: (p as List<Object?>)[1]! as int,
          ),
      ],
    );
  }

  return VoiceBank({
    for (final MapEntry(key: lang, :value) in manifest.entries)
      lang: {
        for (final MapEntry(:key, value: variants)
            in (value! as Map<String, Object?>).entries)
          key: [for (final v in variants! as List<Object?>) clip(v)],
      },
  });
}
