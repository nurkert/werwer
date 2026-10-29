import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whowolf/src/stage/motion.dart';
import 'package:whowolf/src/stage/stage_clock.dart';

/// Reads, in the tree below [motion], what the stage would do: the
/// motion seen, whether animations are asked to stop, the stage clock.
Future<(StageMotion, bool, ValueListenable<double>)> _seen(
  WidgetTester tester,
  StageMotion motion, {
  bool systemReduces = false,
}) async {
  late StageMotion seen;
  late bool reduced;
  late ValueListenable<double> clock;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: systemReduces),
      child: StageMotionScope(
        motion: motion,
        child: StageClock(
          child: Builder(
            builder: (context) {
              seen = StageMotionScope.of(context);
              reduced = MediaQuery.of(context).disableAnimations;
              clock = StageClock.of(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    ),
  );
  return (seen, reduced, clock);
}

void main() {
  testWidgets('the full stage keeps its clock running', (tester) async {
    final (seen, reduced, clock) = await _seen(tester, StageMotion.full);
    expect(seen, StageMotion.full);
    expect(reduced, isFalse);
    final before = clock.value;
    await tester.pump(const Duration(seconds: 1));
    expect(clock.value, greaterThan(before));
  });

  testWidgets('the battery saver stops what runs on its own, not the rest', (
    tester,
  ) async {
    final (seen, reduced, clock) = await _seen(tester, StageMotion.calm);
    expect(seen, StageMotion.calm);
    // Cards may still turn and the curtain fall.
    expect(reduced, isFalse);
    final before = clock.value;
    await tester.pump(const Duration(seconds: 1));
    expect(clock.value, before);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('a still stage asks every animation for reduced motion', (
    tester,
  ) async {
    final (seen, reduced, _) = await _seen(tester, StageMotion.still);
    expect(seen, StageMotion.still);
    expect(reduced, isTrue);
  });

  testWidgets('the system setting wins over a full stage', (tester) async {
    final (seen, _, _) = await _seen(
      tester,
      StageMotion.full,
      systemReduces: true,
    );
    expect(seen, StageMotion.still);
  });

  test('the first start picks a fitting stage', () {
    expect(
      initialStageMotion(web: false, reduceMotion: false),
      StageMotion.full,
    );
    expect(
      initialStageMotion(web: true, reduceMotion: false),
      StageMotion.calm,
    );
    expect(
      initialStageMotion(web: false, reduceMotion: true),
      StageMotion.still,
    );
    expect(
      initialStageMotion(web: true, reduceMotion: true),
      StageMotion.still,
    );
  });

  test('every level has a sign of its own', () {
    final icons = {for (final m in StageMotion.values) stageMotionIcon(m)};
    expect(icons, hasLength(StageMotion.values.length));
  });

  group('the battery saver', () {
    test('calms a full stage and gives it back afterwards', () {
      final choice = StageChoice(StageMotion.full)..saver(on: true);
      expect(choice.shown, StageMotion.calm);
      choice.saver(on: false);
      expect(choice.shown, StageMotion.full);
    });

    test('leaves a calmer pick alone', () {
      final still = StageChoice(StageMotion.still)..saver(on: true);
      expect(still.shown, StageMotion.still);
      final calm = StageChoice(StageMotion.calm)..saver(on: true);
      expect(calm.shown, StageMotion.calm);
    });

    test('a pick while it is on lasts only until it goes off', () {
      final choice = StageChoice(StageMotion.full)..saver(on: true);
      expect(choice.pick(StageMotion.full), isFalse);
      expect(choice.shown, StageMotion.full);
      choice.saver(on: false);
      expect(choice.preferred, StageMotion.full);
      // And the next time it comes on, it calms down again.
      choice.saver(on: true);
      expect(choice.shown, StageMotion.calm);
    });

    test('a pick while it is off is kept', () {
      final choice = StageChoice(StageMotion.full);
      expect(choice.pick(StageMotion.still), isTrue);
      choice
        ..saver(on: true)
        ..saver(on: false);
      expect(choice.shown, StageMotion.still);
    });
  });
}
