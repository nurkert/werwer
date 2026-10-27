// Renders every scene of the stage design alone, at a phone, a tablet and
// a desktop, for tuning the scenery (task 012):
//
//   SCREENSHOTS=/some/dir flutter test test/scene_shots_test.dart
//
// Without SCREENSHOTS the test is skipped.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whowolf/src/game/stage.dart';
import 'package:whowolf/src/stage/scene.dart';
import 'package:whowolf/src/theme.dart';

final String? _out = Platform.environment['SCREENSHOTS'];

void main() {
  testWidgets('every scene at every size', skip: _out == null, (tester) async {
    const sizes = {
      'phone': Size(390, 844),
      'tablet': Size(820, 1180),
      'desktop': Size(1440, 900),
    };
    final key = GlobalKey();
    for (final MapEntry(key: label, value: size) in sizes.entries) {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final scene in [
        for (final s in Scene.values)
          if (Platform.environment['SCENE'] case final only?)
            if (s.name == only) s else null
          else
            s,
      ].nonNulls) {
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MediaQuery(
              data: MediaQueryData(size: size, disableAnimations: true),
              child: MaterialApp(
                theme: buildTheme(),
                debugShowCheckedModeBanner: false,
                home: StageScaffold(scene: scene, body: const SizedBox()),
              ),
            ),
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 700)),
        );
        await tester.pump(const Duration(seconds: 1));
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$_out/$label-${scene.name}.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(png!.buffer.asUint8List());
        });
      }
    }
  });
}
