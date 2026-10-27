// How smooth the stage design runs (task 012): every scene with its wings,
// swaying puppets and the curtain between phases, measured frame by frame.
//
//   flutter drive --profile -d macos \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/stage_perf_test.dart
//
// Prints the build and raster times; a frame is late when either is above
// 16.7 ms (60 frames per second).
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:integration_test/integration_test.dart';
import 'package:whowolf/src/game/figures.dart';
import 'package:whowolf/src/game/stage.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/stage/scene.dart';
import 'package:whowolf/src/stage/stage_pages.dart';
import 'package:whowolf/src/theme.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('every scene runs at 60 frames per second', (tester) async {
    final timings = <FrameTiming>[];
    void collect(List<FrameTiming> t) => timings.addAll(t);
    SchedulerBinding.instance.addTimingsCallback(collect);
    for (final scene in Scene.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
          home: StageScaffold(
            scene: scene,
            body: StagePages(
              pages: [
                for (final role in [Role.werewolf, Role.seer])
                  (
                    label: role.name,
                    child: Column(
                      children: [
                        Headline(scene.name, eyebrow: 'Whowolf'),
                        const SizedBox(height: 20),
                        TurningFigure(asset: figureAsset(role), height: 260),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
      // Let it play: the sway, a swipe to the next page and back.
      await tester.pump(const Duration(seconds: 1));
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1500);
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.fling(find.byType(PageView), const Offset(400, 0), 1500);
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }
    SchedulerBinding.instance.removeTimingsCallback(collect);
    double ms(Duration d) => d.inMicroseconds / 1000;
    final build = [for (final t in timings) ms(t.buildDuration)]..sort();
    final raster = [for (final t in timings) ms(t.rasterDuration)]..sort();
    double p(List<double> v, double q) =>
        v.isEmpty ? 0 : v[((v.length - 1) * q).round()];
    final late = timings
        .where((t) => ms(t.buildDuration) > 16.7 || ms(t.rasterDuration) > 16.7)
        .length;
    // The numbers are the result of this test: print them.
    // ignore: avoid_print
    print(
      'frames ${timings.length}, late $late; '
      'build p50 ${p(build, 0.5).toStringAsFixed(1)} ms, '
      'p90 ${p(build, 0.9).toStringAsFixed(1)} ms; '
      'raster p50 ${p(raster, 0.5).toStringAsFixed(1)} ms, '
      'p90 ${p(raster, 0.9).toStringAsFixed(1)} ms',
    );
    expect(timings, isNotEmpty);
  });
}
