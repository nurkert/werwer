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
}
