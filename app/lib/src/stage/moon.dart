import 'dart:math';

import 'package:flutter/material.dart';
import 'package:whowolf/src/theme.dart';

/// How the sky's light looks: the moon in a phase, or the sun.
enum MoonPhase {
  /// Evening: a thin crescent.
  crescent,

  /// Half lit.
  half,

  /// The night's full moon.
  full,

  /// The end of the werewolves' game.
  blood,

  /// Morning and day.
  sun,
}

/// The stage's moon, the motif of the whole app: it shows the time of day
/// and, with [progress], a glowing ring that runs round it like a clock.
///
/// The ring shows only what everyone may know. At night it runs evenly
/// over the whole night (from the phase's start and the night's length),
/// never the time a called role has left: that would tell when someone
/// picked (see task 012).
class Moon extends StatelessWidget {
  const Moon({
    required this.size,
    super.key,
    this.phase = MoonPhase.full,
    this.progress,
    this.glow = true,
  });

  final double size;
  final MoonPhase phase;

  /// From 0 to 1, how far the ring has run; none without.
  final double? progress;

  /// A soft halo of light around it.
  final bool glow;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: CustomPaint(
        size: Size.square(size),
        painter: MoonPainter(phase: phase, progress: progress, glow: glow),
      ),
    ),
  );
}

/// Paints [Moon]. Public for the scenes, which draw the moon into the sky.
class MoonPainter extends CustomPainter {
  const MoonPainter({required this.phase, this.progress, this.glow = true});

  final MoonPhase phase;
  final double? progress;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ring = progress != null;
    // The disc leaves room for the ring and the halo.
    final radius = size.shortestSide / 2 * (ring ? 0.72 : 0.8);
    final (light, shade, halo) = switch (phase) {
      MoonPhase.blood => (
        const Color(0xFFE8705A),
        const Color(0xFF7A1C1E),
        Palette.stageBlood,
      ),
      MoonPhase.sun => (
        const Color(0xFFFFE6A8),
        const Color(0xFFF2B455),
        Palette.stageLanternTop,
      ),
      _ => (Palette.stageMoonlight, const Color(0xFFD9B57E), Palette.moon100),
    };
    if (glow) {
      canvas.drawCircle(
        center,
        size.shortestSide / 2,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  halo.withValues(alpha: 0.35),
                  halo.withValues(alpha: 0.08),
                  halo.withValues(alpha: 0),
                ],
                stops: const [0.45, 0.75, 1],
              ).createShader(
                Rect.fromCircle(center: center, radius: size.shortestSide / 2),
              ),
      );
    }
    final disc = Rect.fromCircle(center: center, radius: radius);
    final lit = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.35),
        colors: [Color.lerp(light, Colors.white, 0.25)!, light, shade],
        stops: const [0, 0.6, 1],
      ).createShader(disc);
    switch (phase) {
      case MoonPhase.crescent || MoonPhase.half:
        // The lit part: the disc minus a shifted disc of night.
        final cut = phase == MoonPhase.crescent ? 0.55 : 1.0;
        final path = Path.combine(
          PathOperation.difference,
          Path()..addOval(disc),
          Path()..addOval(disc.shift(Offset(-radius * cut, -radius * 0.12))),
        );
        canvas.drawPath(path, lit);
      case MoonPhase.sun:
        canvas.drawCircle(center, radius, lit);
      case MoonPhase.full || MoonPhase.blood:
        canvas.drawCircle(center, radius, lit);
        _craters(canvas, center, radius, shade);
    }
    if (ring) _ring(canvas, center, size.shortestSide / 2 * 0.86, progress!);
  }

  /// A few soft maria, always the same.
  void _craters(Canvas canvas, Offset center, double radius, Color shade) {
    final paint = Paint()
      ..color = shade.withValues(alpha: 0.28)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.05);
    const spots = [
      (-0.32, -0.2, 0.22),
      (0.18, -0.32, 0.14),
      (0.28, 0.12, 0.2),
      (-0.1, 0.3, 0.16),
      (-0.42, 0.18, 0.1),
    ];
    for (final (x, y, r) in spots) {
      canvas.drawCircle(
        center + Offset(x * radius, y * radius),
        r * radius,
        paint,
      );
    }
  }

  void _ring(Canvas canvas, Offset center, double radius, double progress) {
    final width = radius * 0.035 + 1.5;
    final track = Paint()
      ..color = Palette.stageBrassLight.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    canvas.drawCircle(center, radius, track);
    final sweep = 2 * pi * progress.clamp(0, 1);
    if (sweep <= 0) return;
    final arc = Rect.fromCircle(center: center, radius: radius);
    canvas
      ..drawArc(
        arc,
        -pi / 2,
        sweep,
        false,
        Paint()
          ..color = Palette.stageLanternTop.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * 3
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 1.5),
      )
      ..drawArc(
        arc,
        -pi / 2,
        sweep,
        false,
        Paint()
          ..color = Palette.stageMoonlight
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = width,
      );
    // A bright bead at the ring's tip.
    final tip = center + Offset(sin(sweep), -cos(sweep)) * radius;
    canvas.drawCircle(tip, width * 1.4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(MoonPainter old) =>
      old.phase != phase || old.progress != progress || old.glow != glow;
}

/// The night's ring: how far the night has run, the same for everyone.
/// From the phase's start (this device's clock) and the night's length
/// only; never from a called step's time left.
double nightRing({
  required int nowMs,
  required int? phaseStartedAtMs,
  required Duration nightLength,
}) {
  final start = phaseStartedAtMs;
  if (start == null || nightLength <= Duration.zero) return 0;
  return ((nowMs - start) / nightLength.inMilliseconds).clamp(0.0, 1.0);
}
