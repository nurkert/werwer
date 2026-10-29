import 'package:flutter/material.dart';

/// How much the stage moves on this device: a battery choice, kept on the
/// device and never sent to the host.
enum StageMotion {
  /// Everything lives: flickering lights, mist, the tilting set, rocking
  /// figures.
  full,

  /// Only what answers a tap or a change of phase (a card turning, the
  /// curtain); nothing runs on its own, so the screen draws nothing
  /// while the stage stands still. The tilt sensor is off.
  calm,

  /// Nothing moves at all, as with the system's "reduce motion".
  still,
}

/// The choice on this device, loaded at start; the app follows changes
/// at once.
final stageMotion = ValueNotifier<StageMotion>(StageMotion.full);

/// What a device starts with before anyone picked (set once on the very
/// first start, then kept like a choice): nothing moves if the system asks
/// for reduced motion, a browser saves its battery, apps get the full stage.
StageMotion initialStageMotion({
  required bool web,
  required bool reduceMotion,
}) => reduceMotion
    ? StageMotion.still
    : web
    ? StageMotion.calm
    : StageMotion.full;

/// Each level's own sign, in the settings and the app bar.
IconData stageMotionIcon(StageMotion motion) => switch (motion) {
  StageMotion.full => Icons.auto_awesome_outlined,
  StageMotion.calm => Icons.battery_saver_outlined,
  StageMotion.still => Icons.motion_photos_off_outlined,
};

/// Hands [motion] down the tree; with [StageMotion.still] it also asks
/// every animation for reduced motion, the way the system setting does.
class StageMotionScope extends StatelessWidget {
  const StageMotionScope({
    required this.motion,
    required this.child,
    super.key,
  });

  final StageMotion motion;
  final Widget child;

  /// The motion for [context]: [StageMotion.still] whenever the system
  /// asks for reduced motion, whatever was picked in the app.
  static StageMotion of(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return StageMotion.still;
    return context.dependOnInheritedWidgetOfExactType<_Motion>()?.motion ??
        StageMotion.full;
  }

  /// Whether things may move on their own (lights, mist, tilt, rocking),
  /// not only in answer to the game.
  static bool idles(BuildContext context) => of(context) == StageMotion.full;

  @override
  Widget build(BuildContext context) {
    final inner = _Motion(motion: motion, child: child);
    if (motion != StageMotion.still) return inner;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: inner,
    );
  }
}

class _Motion extends InheritedWidget {
  const _Motion({required this.motion, required super.child});

  final StageMotion motion;

  @override
  bool updateShouldNotify(_Motion old) => old.motion != motion;
}
