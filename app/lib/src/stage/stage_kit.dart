import 'package:flutter/material.dart';
import 'package:whowolf/src/theme.dart';

/// The small line above a title: spaced small capitals between two dashes
/// ("— SPIELABEND —"), as on a theatre bill.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ink = color ?? Palette.stageIvorySoft.withValues(alpha: 0.85);
    Widget dash() => Container(width: 16, height: 1.2, color: ink);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dash(),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: displayFont,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.6,
              color: ink,
              shadows: const [Shadow(color: Color(0xE6000000), blurRadius: 6)],
            ),
          ),
        ),
        const SizedBox(width: 10),
        dash(),
      ],
    );
  }
}

/// The look of a plaque: warm black board, a little see-through so the
/// scene glows behind it, with a double brass edge and a soft shadow.
class PlaqueDecoration extends Decoration {
  const PlaqueDecoration({this.lit = false, this.radius = Radii.m});

  /// Its edge glows in lantern light (chosen, active).
  final bool lit;
  final double radius;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _PlaquePainter(lit: lit, radius: radius);
}

class _PlaquePainter extends BoxPainter {
  _PlaquePainter({required this.lit, required this.radius});

  final bool lit;
  final double radius;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size!;
    final rect = offset & size;
    final outer = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    // Shadow onto the scene, then the board.
    canvas
      ..drawRRect(
        outer.shift(const Offset(0, 6)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      )
      ..drawRRect(
        outer,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF231E1A).withValues(alpha: 0.9),
              Palette.stagePlaque.withValues(alpha: 0.88),
            ],
          ).createShader(rect),
      );
    // Outer brass edge, lit from above.
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = lit ? 2.2 : 1.6
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: lit
            ? [Palette.stageLanternTop, Palette.stageLanternBottom]
            : [Palette.stageBrassLight, Palette.stageBrassDark],
      ).createShader(rect);
    canvas
      ..drawRRect(outer.deflate(0.8), edge)
      // The fine inner line.
      ..drawRRect(
        outer.deflate(5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = (lit ? Palette.stageLanternTop : Palette.stageBrass)
              .withValues(alpha: 0.45),
      );
    if (lit) {
      canvas.drawRRect(
        outer,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = Palette.stageLanternTop.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }
}

/// The face of the main action: lantern orange, lighter at the top, with
/// a darker rim and a thin highlight, as lit from above.
class LanternDecoration extends Decoration {
  const LanternDecoration({this.press = 0, this.enabled = true});

  /// 0 at rest, 1 fully pressed.
  final double press;
  final bool enabled;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _LanternPainter(press: press, enabled: enabled);
}

class _LanternPainter extends BoxPainter {
  _LanternPainter({required this.press, required this.enabled});

  final double press;
  final bool enabled;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size!;
    final rect = offset & size;
    final shape = RRect.fromRectAndRadius(rect, const Radius.circular(Radii.m));
    final (top, middle, bottom) = enabled
        ? (
            Palette.stageLanternTop,
            Palette.stageLantern,
            Palette.stageLanternBottom,
          )
        : (Palette.stageNight4, Palette.stageNight3, Palette.stageNight3);
    if (enabled) {
      // Lantern glow on the scene.
      canvas.drawRRect(
        shape.shift(Offset(0, 5 - 3 * press)),
        Paint()
          ..color = Palette.stageLanternBottom.withValues(
            alpha: 0.45 - 0.2 * press,
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }
    canvas
      ..drawRRect(
        shape,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(top, bottom, press * 0.5)!,
              middle,
              bottom,
            ],
            stops: const [0, 0.55, 1],
          ).createShader(rect),
      )
      // The dark rim.
      ..drawRRect(
        shape.deflate(0.75),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = enabled
              ? const Color(0xFF8A4A16)
              : Palette.stageBrassDark.withValues(alpha: 0.6),
      );
    if (enabled) {
      // A thin highlight along the top edge.
      final highlight = RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left + 6, rect.top + 2.5, rect.width - 12, 3),
        const Radius.circular(2),
      );
      canvas.drawRRect(
        highlight,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35 * (1 - press))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
    }
  }
}

/// Only the brass edge of a plaque, laid over a picture (the meadow).
class PlaqueFrame extends Decoration {
  const PlaqueFrame({this.radius = Radii.m});

  final double radius;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _FramePainter(radius);
}

class _FramePainter extends BoxPainter {
  _FramePainter(this.radius);

  final double radius;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final rect = offset & configuration.size!;
    final shape = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas
      ..drawRRect(
        shape.deflate(0.8),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Palette.stageBrassLight, Palette.stageBrassDark],
          ).createShader(rect),
      )
      ..drawRRect(
        shape.deflate(5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = Palette.stageBrass.withValues(alpha: 0.45),
      );
  }
}
