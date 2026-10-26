import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

const GameSettings signs = GameSettings(doorSigns: true);

const Role w = Role.werewolf;
const Role v = Role.villager;

/// Two werewolves (p0, p1) and five others, so one night never ends the
/// game; [extra] replaces p2.
GameState signNight({int seed = 0, Role extra = v}) => night([
  w,
  w,
  extra,
  v,
  v,
  v,
  Role.seer,
], settings: signs).copyWith(seed: seed);

/// Plays only the werewolves' step: they pick [victim], everyone else the
/// first other living player.
GameState hunt(GameState state, int victim) {
  var current = state;
  for (final p in state.alive) {
    if (current.nightStep != NightStep.hunt) break;
    final other = current.alive.firstWhere((o) => o.id != p.id).id;
    final pick = nightTask(current, p.id) == NightAbility.hunt
        ? id(victim)
        : other;
    final picks = nightTask(current, p.id) == NightAbility.link
        ? [other, p.id]
        : [pick];
    current = apply(current, nightAction(current, p.id, picks)).state;
  }
  return current;
}

/// [sign] with its first symbol changed.
List<int> wrong(List<int> sign) => [
  (sign.first + 1) % doorSignSymbols,
  ...sign.skip(1),
];

/// Whether a right sign on p4 takes p4 in the first night of [seed] (the
/// wolves hunt p3).
bool strikes(int seed) {
  var state = signNight(seed: seed);
  state = apply(
    state,
    MarkDoor(id(0), id(4), doorSignFor(state, id(4))),
  ).state;
  return !playNight(state, {0: 3, 1: 3}).state.player(id(4))!.isAlive;
}

/// The first seed whose coin takes a marked player, or spares them.
int seedWhere({required bool strike}) =>
    Iterable<int>.generate(1000).firstWhere((s) => strikes(s) == strike);

void main() {
  group('door signs', () {
    test('are three symbols, stable per night, new every night', () {
      final state = signNight(seed: 42);
      final sign = doorSignFor(state, id(3));
      expect(sign, hasLength(doorSignLength));
      expect(sign.every((s) => s >= 0 && s < doorSignSymbols), isTrue);
      expect(doorSignFor(state, id(3)), sign);
      // Across many players, seeds and rounds every symbol shows up and the
      // signs differ.
      final all = <String>{};
      final symbols = <int>{};
      for (var seed = 0; seed < 50; seed++) {
        for (var round = 1; round < 4; round++) {
          for (var p = 0; p < 7; p++) {
            final s = doorSignFor(
              state.copyWith(seed: seed, round: round),
              id(p),
            );
            all.add(s.join(','));
            symbols.addAll(s);
          }
        }
      }
      expect(symbols, hasLength(doorSignSymbols));
      expect(all.length, greaterThan(900));
    });

    test('each player sees only their own, only at night and alive', () {
      final state = signNight(seed: 7);
      for (final p in state.players) {
        expect(viewFor(state, p.id).yourDoorSign, doorSignFor(state, p.id));
      }
      expectNoLeaks(state);
      expect(publicView(state).yourDoorSign, isNull);
      final day = playNight(state, {0: 3, 1: 3}).state;
      expect(day.phase, Phase.day);
      expect(viewFor(day, id(2)).yourDoorSign, isNull);
      final next = voteOut(day, 2).state;
      expect(next.phase, Phase.night);
      expect(viewFor(next, id(2)).yourDoorSign, isNull, reason: 'dead');
      expect(viewFor(next, id(4)).yourDoorSign, doorSignFor(next, id(4)));
      // Without the setting nobody has one.
      final plain = night([w, v, v, v, v]);
      expect(viewFor(plain, id(1)).yourDoorSign, isNull);
    });

    test('only a living werewolf in the hunt may mark, the pack once', () {
      final state = signNight(seed: 3);
      final sign = doorSignFor(state, id(3));
      final cases = <GameAction, Violation>{
        MarkDoor(id(2), id(3), sign): Violation.notYourAction,
        MarkDoor(id(6), id(3), sign): Violation.notYourAction,
        MarkDoor(id(0), id(1), sign): Violation.invalidTarget,
        MarkDoor(id(0), id(0), sign): Violation.invalidTarget,
        MarkDoor(id(0), const PlayerId('nope'), sign): Violation.unknownPlayer,
        MarkDoor(id(0), id(3), const [1, 2]): Violation.outOfRange,
        MarkDoor(id(0), id(3), const [1, 2, 3, 4]): Violation.outOfRange,
        MarkDoor(id(0), id(3), const [1, 2, 16]): Violation.outOfRange,
        MarkDoor(id(0), id(3), const [-1, 2, 3]): Violation.outOfRange,
      };
      for (final MapEntry(key: action, value: reason) in cases.entries) {
        expect(() => apply(state, action), refuses(reason));
      }

      final marked = apply(state, MarkDoor(id(0), id(3), wrong(sign))).state;
      expect(marked.packMark, (target: id(3), correct: false));
      for (final wolf in [id(0), id(1)]) {
        expect(
          () => apply(marked, MarkDoor(wolf, id(4), doorSignFor(state, id(4)))),
          refuses(Violation.markUsed),
        );
      }
      // Not a night pick: nobody has acted, the step goes on.
      final view = viewFor(marked, id(0));
      expect(view.youActed, isFalse);
      expect(view.waitingFor, 7);
      expect(marked.nightChoices, isEmpty);
      expect(view.packMark, (target: id(3), correct: false));
      expect(viewFor(marked, id(1)).packMark, marked.packMark);
      expectNoLeaks(marked);

      // A new night brings a new attempt.
      final day = playNight(marked, {0: 3, 1: 3}).state;
      expect(day.packMark, isNull);
      final next = voteOut(day, 5).state;
      expect(next.phase, Phase.night);
      expect(viewFor(next, id(0)).packMark, isNull);
      apply(next, MarkDoor(id(1), id(4), doorSignFor(next, id(4))));
    });

    test('outside the hunt, for the dead and when switched off: refused', () {
      final state = signNight(extra: Role.witch);
      final sign = doorSignFor(state, id(3));
      final brew = hunt(state, 4);
      expect(brew.nightStep, NightStep.brew);
      expect(
        () => apply(brew, MarkDoor(id(0), id(3), sign)),
        refuses(Violation.notYourAction),
      );
      final day = playNight(brew, const {}).state;
      expect(
        () => apply(day, MarkDoor(id(0), id(3), sign)),
        refuses(Violation.wrongPhase),
      );
      final wolfOut = voteOut(day, 1).state;
      expect(wolfOut.phase, Phase.night);
      expect(
        () => apply(
          wolfOut,
          MarkDoor(id(1), id(3), doorSignFor(wolfOut, id(3))),
        ),
        refuses(Violation.playerDead),
      );
      expect(
        () => apply(night([w, v, v, v, v]), MarkDoor(id(0), id(1), sign)),
        refuses(Violation.disabled),
      );
    });

    test('a wrong sign never kills', () {
      for (var seed = 0; seed < 200; seed++) {
        var state = signNight(seed: seed);
        state = apply(
          state,
          MarkDoor(id(1), id(4), wrong(doorSignFor(state, id(4)))),
        ).state;
        final morning = playNight(state, {0: 3, 1: 3}).state;
        expect(morning.player(id(4))!.isAlive, isTrue, reason: 'seed $seed');
        expect(morning.deaths, hasLength(1));
      }
    });

    test('a right sign kills in about half of the games, the same each '
        'time', () {
      var kills = 0;
      for (var seed = 0; seed < 400; seed++) {
        final killed = strikes(seed);
        expect(strikes(seed), killed, reason: 'seed $seed');
        if (killed) kills++;
      }
      expect(kills, inInclusiveRange(160, 240));
    });

    test('a marked death is a night death; nobody sees how it came', () {
      var state = signNight(seed: seedWhere(strike: true));
      state = apply(
        state,
        MarkDoor(id(0), id(4), doorSignFor(state, id(4))),
      ).state;
      final update = playNight(state, {0: 3, 1: 3});
      expect(
        update.state.deaths.map((d) => (d.player, d.cause)),
        [(id(3), DeathCause.night), (id(4), DeathCause.night)],
      );
      expect(update.events.whereType<PlayerKilled>(), hasLength(2));
      expect(update.state.packMark, isNull);
      expectNoLeaks(update.state);
    });

    test('the witch cannot save a marked player', () {
      var state = signNight(seed: seedWhere(strike: true), extra: Role.witch);
      state = apply(
        state,
        MarkDoor(id(0), id(4), doorSignFor(state, id(4))),
      ).state;
      final brew = hunt(state, 3);
      expect(viewFor(brew, id(2)).victim, id(3));
      final morning = playNight(brew, const {}, brew: [3]).state;
      expect(morning.player(id(3))!.isAlive, isTrue);
      expect(morning.player(id(4))!.isAlive, isFalse);
    });

    test('marking the victim kills nobody twice', () {
      var state = signNight(seed: seedWhere(strike: true));
      state = apply(
        state,
        MarkDoor(id(0), id(3), doorSignFor(state, id(3))),
      ).state;
      final morning = playNight(state, {0: 3, 1: 3}).state;
      expect(morning.deaths.map((d) => d.player), [id(3)]);
    });

    test('a marked death takes the lover and gives the hunter his shot', () {
      final seed = seedWhere(strike: true);
      var state = signNight(seed: seed, extra: Role.cupid);
      state = apply(
        state,
        MarkDoor(id(0), id(4), doorSignFor(state, id(4))),
      ).state;
      final morning = playNight(state, {0: 3, 1: 3}, link: [4, 5]).state;
      expect(
        morning.deaths.map((d) => (d.player, d.cause)),
        [
          (id(3), DeathCause.night),
          (id(4), DeathCause.night),
          (id(5), DeathCause.heartbreak),
        ],
      );

      var hunted = signNight(seed: seed, extra: Role.hunter);
      hunted = apply(
        hunted,
        MarkDoor(id(1), id(2), doorSignFor(hunted, id(2))),
      ).state;
      final shot = playNight(hunted, {0: 3, 1: 3}).state;
      expect(shot.phase, Phase.hunterShot);
      expect(shot.shooter, id(2));
    });

    test('a marked lover of the victim dies of grief, not of the mark', () {
      var state = signNight(seed: seedWhere(strike: true), extra: Role.cupid);
      state = apply(
        state,
        MarkDoor(id(0), id(4), doorSignFor(state, id(4))),
      ).state;
      final morning = playNight(state, {0: 3, 1: 3}, link: [3, 4]).state;
      expect(
        morning.deaths.map((d) => (d.player, d.cause)),
        [(id(3), DeathCause.night), (id(4), DeathCause.heartbreak)],
      );
    });

    test('the coin can spare a right sign', () {
      var state = signNight(seed: seedWhere(strike: false));
      state = apply(
        state,
        MarkDoor(id(0), id(4), doorSignFor(state, id(4))),
      ).state;
      expect(viewFor(state, id(1)).packMark, (target: id(4), correct: true));
      final morning = playNight(state, {0: 3, 1: 3}).state;
      expect(morning.player(id(4))!.isAlive, isTrue);
    });
  });
}
