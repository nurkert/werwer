import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// How far the phone is tilted from where it was held, -1 to 1 on both
/// axes: the stage set's layers shift by it at their own depth (task 012),
/// the wings in front more than the sky behind.
///
/// The sensor only sets where the tilt is heading; a ticker glides there
/// on every frame, so the layers move in step with the display, and only
/// their offset changes ([TiltShift]), nothing is built again.
///
/// Only on phones and tablets, and never when the system asks for reduced
/// motion; elsewhere it stays at zero.
class StageTilt extends StatefulWidget {
  const StageTilt({required this.child, super.key});

  final Widget child;

  /// The current tilt to listen to; zero without a [StageTilt] above.
  static ValueListenable<Offset> of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_Tilt>()?.tilt ?? _still;

  static final ValueNotifier<Offset> _still = ValueNotifier(Offset.zero);

  @override
  State<StageTilt> createState() => _StageTiltState();
}

class _StageTiltState extends State<StageTilt>
    with SingleTickerProviderStateMixin {
  StreamSubscription<AccelerometerEvent>? _sensor;
  final ValueNotifier<Offset> _tilt = ValueNotifier(Offset.zero);
  late final Ticker _ticker;
  Offset _target = Offset.zero;
  Duration _last = Duration.zero;

  static const double _amount = 0.35;

  /// Where "level" is: the first readings, slowly following the hand.
  Offset? _rest;

  static bool get _hasSensor =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_glide);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.of(context).disableAnimations;
    if (still || !_hasSensor) {
      unawaited(_sensor?.cancel());
      _sensor = null;
      _ticker.stop();
      _tilt.value = Offset.zero;
      return;
    }
    _sensor ??= accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(_read, onError: (Object _) {});
  }

  void _read(AccelerometerEvent event) {
    // Gravity along the screen's axes, in g.
    final now = Offset(event.x / 9.81, event.y / 9.81);
    final rest = _rest = _rest == null ? now : Offset.lerp(_rest, now, 0.01)!;
    final raw = now - rest;
    // Only a hint of depth: a third of the way at most, so the set never
    // swims about in the hand.
    _target = Offset(
      raw.dx.clamp(-0.35, 0.35) / 0.35 * _amount,
      raw.dy.clamp(-0.35, 0.35) / 0.35 * _amount,
    );
    if (!_ticker.isActive) {
      _last = Duration.zero;
      unawaited(_ticker.start());
    }
  }

  void _glide(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    // A slow damped follow, smooth at any frame rate: hand tremor is
    // smoothed away, only the lean of the phone comes through.
    final t = 1 - math.pow(0.02, dt).toDouble();
    final next = Offset.lerp(_tilt.value, _target, t)!;
    if ((next - _target).distance < 0.001) {
      _tilt.value = _target;
      _ticker.stop();
      return;
    }
    _tilt.value = next;
  }

  @override
  void dispose() {
    unawaited(_sensor?.cancel());
    _ticker.dispose();
    _tilt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _Tilt(tilt: _tilt, child: widget.child);
}

class _Tilt extends InheritedWidget {
  const _Tilt({required this.tilt, required super.child});

  final ValueNotifier<Offset> tilt;

  @override
  bool updateShouldNotify(_Tilt old) => old.tilt != tilt;
}

/// Shifts [child] by the stage's tilt times [depth], repainting nothing:
/// only the layer's offset changes, on every frame.
class TiltShift extends StatelessWidget {
  const TiltShift({required this.depth, required this.child, super.key});

  final double depth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tilt = StageTilt.of(context);
    return ValueListenableBuilder<Offset>(
      valueListenable: tilt,
      child: RepaintBoundary(child: child),
      builder: (context, value, child) =>
          Transform.translate(offset: value * -depth, child: child),
    );
  }
}
