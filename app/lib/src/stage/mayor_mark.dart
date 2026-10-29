import 'dart:math';

import 'package:flutter/material.dart';
import 'package:whowolf/src/theme.dart';

/// The mayor's chain of office: a brass chain hanging in a bow with a round
/// medallion and a star. No words, so every table reads it the same; the
/// [label] is for screen readers only.
class MayorMark extends StatelessWidget {
  const MayorMark({required this.label, super.key, this.size = 28});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    image: true,
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _ChainPainter()),
    ),
  );
}

/// [MayorMark] on a small round plaque, for the corner of a seat card: it
/// stands out on light and dark figures alike.
class MayorPlaque extends StatelessWidget {
  const MayorPlaque({required this.label, super.key, this.size = 30});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Palette.stagePlaque,
      border: Border.all(color: _brassLight, width: size < 26 ? 1.5 : 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x99000000),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    padding: EdgeInsets.all(size * 0.12),
    child: MayorMark(label: label, size: size * 0.76),
  );
}

const _brassLight = Color(0xFFF4D27A);
const _brass = Color(0xFFC8952E);
const _brassDeep = Color(0xFF8A5A17);
// The bold dark-brown outline of the cardboard figures.
const _outline = Color(0xFF3A2412);

class _ChainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final medal = Offset(s * 0.5, s * 0.66);
    final radius = s * 0.27;
    // The bow of the chain: from the two upper corners down to the medal.
    final left = Offset(s * 0.1, s * 0.1);
    final right = Offset(s * 0.9, s * 0.1);
    final control = Offset(s * 0.5, s * 0.62);
    Offset at(double t) {
      final u = 1 - t;
      return left * (u * u) + control * (2 * u * t) + right * (t * t);
    }

    if (s < 22) {
      // Too small for single links: one brass band with an outline.
      final path = Path()
        ..moveTo(left.dx, left.dy)
        ..quadraticBezierTo(control.dx, control.dy, right.dx, right.dy);
      canvas
        ..drawPath(
          path,
          Paint()
            ..color = _outline
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = s * 0.17,
        )
        ..drawPath(
          path,
          Paint()
            ..color = _brass
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = s * 0.09,
        );
    } else {
      // Single links along the bow, every other one turned edge-on.
      const links = 11;
      for (var i = 0; i < links; i++) {
        final t = i / (links - 1);
        final p = at(t);
        final d = at(min(t + 0.01, 1)) - at(max(t - 0.01, 0));
        final angle = atan2(d.dy, d.dx);
        final w = s * 0.13;
        final h = i.isEven ? s * 0.085 : s * 0.045;
        canvas
          ..save()
          ..translate(p.dx, p.dy)
          ..rotate(angle);
        final rect = Rect.fromCenter(center: Offset.zero, width: w, height: h);
        canvas
          ..drawOval(rect.inflate(s * 0.022), Paint()..color = _outline)
          ..drawOval(rect, Paint()..color = i.isEven ? _brass : _brassLight)
          ..restore();
      }
    }

    // The medallion: outline, brass disc lit from the upper left, a rim.
    canvas
      ..drawCircle(medal, radius + s * 0.035, Paint()..color = _outline)
      ..drawCircle(
        medal,
        radius,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.45, -0.5),
            colors: [_brassLight, _brass, _brassDeep],
            stops: [0, 0.55, 1],
          ).createShader(Rect.fromCircle(center: medal, radius: radius)),
      )
      ..drawCircle(
        medal,
        radius * 0.78,
        Paint()
          ..color = _brassDeep.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(0.8, s * 0.025),
      );
    // A five-pointed star struck into it.
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? radius * 0.55 : radius * 0.24;
      final a = -pi / 2 + i * pi / 5;
      final p = medal + Offset(cos(a), sin(a)) * r;
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    star.close();
    canvas
      ..drawPath(star, Paint()..color = _brassDeep)
      ..drawPath(
        star.shift(Offset(-s * 0.012, -s * 0.012)),
        Paint()..color = _brassLight,
      );
  }

  @override
  bool shouldRepaint(_ChainPainter oldDelegate) => false;
}
