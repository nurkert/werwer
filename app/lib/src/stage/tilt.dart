import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// How far the phone is tilted from where it was held, -1 to 1 on both
/// axes, smoothed: the stage set's layers shift by it at their own depth
/// (task 012), the wings in front more than the sky behind.
///
/// Only on phones and tablets, and never when the system asks for reduced
/// motion; elsewhere it stays at zero.
class StageTilt extends StatefulWidget {
  const StageTilt({required this.child, super.key});

  final Widget child;

  /// The current tilt, or zero without a [StageTilt] above.
  static Offset of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Tilt>()?.tilt ?? Offset.zero;

  @override
  State<StageTilt> createState() => _StageTiltState();
}

class _StageTiltState extends State<StageTilt> {
  StreamSubscription<AccelerometerEvent>? _sensor;
  Offset _tilt = Offset.zero;

  /// Where "level" is: the first readings, slowly following the hand.
  Offset? _rest;

  static bool get _hasSensor =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.of(context).disableAnimations;
    if (still || !_hasSensor) {
      unawaited(_sensor?.cancel());
      _sensor = null;
      _tilt = Offset.zero;
      return;
    }
    _sensor ??= accelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen(_read, onError: (Object _) {});
  }

  void _read(AccelerometerEvent event) {
    // Gravity along the screen's axes, in g.
    final now = Offset(event.x / 9.81, event.y / 9.81);
    final rest = _rest = _rest == null ? now : Offset.lerp(_rest, now, 0.01)!;
    final raw = now - rest;
    final next = Offset.lerp(
      _tilt,
      Offset(
        raw.dx.clamp(-0.35, 0.35) / 0.35,
        raw.dy.clamp(-0.35, 0.35) / 0.35,
      ),
      0.12,
    )!;
    if ((next - _tilt).distance > 0.004 && mounted) {
      setState(() => _tilt = next);
    }
  }

  @override
  void dispose() {
    unawaited(_sensor?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _Tilt(tilt: _tilt, child: widget.child);
}

class _Tilt extends InheritedWidget {
  const _Tilt({required this.tilt, required super.child});

  final Offset tilt;

  @override
  bool updateShouldNotify(_Tilt old) => old.tilt != tilt;
}
