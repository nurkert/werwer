import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:whowolf/src/stage/motion.dart';

/// The time the stage's life runs on (task 015), in seconds: one ticker for
/// the whole stage, updated about 30 times a second. With reduced motion,
/// or a calmer stage picked to save battery ([StageMotion]), it stands
/// still, and everything shows a calm, lit still.
class StageClock extends StatefulWidget {
  const StageClock({required this.child, super.key});

  final Widget child;

  /// The clock of the stage around; a still one without a stage.
  static ValueListenable<double> of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_Clock>()?.time ?? _still;

  static final ValueNotifier<double> _still = ValueNotifier(3);

  @override
  State<StageClock> createState() => _StageClockState();
}

class _StageClockState extends State<StageClock>
    with SingleTickerProviderStateMixin {
  // A moment where every light is lit, for the still.
  final ValueNotifier<double> _time = ValueNotifier(3);
  late final Ticker _ticker = createTicker(_tick);
  Duration _shown = Duration.zero;

  void _tick(Duration elapsed) {
    if (elapsed - _shown < const Duration(milliseconds: 32)) return;
    _shown = elapsed;
    _time.value = 3 + elapsed.inMicroseconds / 1e6;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!StageMotionScope.idles(context)) {
      _ticker.stop();
      _time.value = 3;
    } else if (!_ticker.isActive) {
      _shown = Duration.zero;
      unawaited(_ticker.start());
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _Clock(time: _time, child: widget.child);
}

class _Clock extends InheritedWidget {
  const _Clock({required this.time, required super.child});

  final ValueNotifier<double> time;

  @override
  bool updateShouldNotify(_Clock old) => old.time != time;
}
