import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:whowolf/src/game/figures.dart';

/// The start screen's title (task 012): the werewolf stands big behind the
/// wordmark, both cut from corrugated board, each swaying in its own time
/// so their edges show from ever other sides. Now and then the werewolf
/// leans forward and its paw reaches over the letters: the paw is a
/// picture of its own (`werwolf_paw.webp`, the hand on the werewolf's
/// canvas) laid in front, turning with the werewolf at the same angle.
class WolfTitle extends StatefulWidget {
  const WolfTitle({required this.width, super.key});

  /// How wide the wordmark is.
  final double width;

  @override
  State<WolfTitle> createState() => _WolfTitleState();
}

class _WolfTitleState extends State<WolfTitle> with TickerProviderStateMixin {
  /// The slow clock everything moves by, in seconds; it never wraps, so
  /// the turns never jump.
  final ValueNotifier<double> _time = ValueNotifier(0);
  late final Ticker _ticker = createTicker(
    (elapsed) => _time.value = elapsed.inMicroseconds / 1e6,
  );
  final ValueNotifier<double> _wolfAngle = ValueNotifier(0);
  final ValueNotifier<double> _wordAngle = ValueNotifier(0);

  /// The top edge of the letters (x, y as fractions of the wordmark),
  /// gaps between letters bridged: the werewolf behind is cut along it.
  static const List<Offset> _letterTops = [
    Offset(0, 0.106), Offset(0.031, 0.041), Offset(0.062, 0.041), //
    Offset(0.094, 0.041), Offset(0.125, 0.067), Offset(0.156, 0.082), //
    Offset(0.188, 0), Offset(0.219, 0), Offset(0.25, 0), Offset(0.281, 0), //
    Offset(0.312, 0.127), Offset(0.344, 0.182), Offset(0.375, 0.182), //
    Offset(0.406, 0.194), Offset(0.438, 0.391), Offset(0.469, 0.38), //
    Offset(0.5, 0.38), Offset(0.531, 0.38), Offset(0.562, 0.38), //
    Offset(0.594, 0.356), Offset(0.625, 0.346), Offset(0.656, 0.337), //
    Offset(0.688, 0.337), Offset(0.719, 0.337), Offset(0.75, 0.247), //
    Offset(0.781, 0.219), Offset(0.812, 0.207), Offset(0.844, 0.207), //
    Offset(0.875, 0.207), Offset(0.906, 0.207), Offset(0.938, 0.213), //
    Offset(0.969, 0.213), Offset(1, 0.217),
  ];

  static const _wolf = 'assets/figures/werwolf.webp';
  static const _paw = 'assets/figures/werwolf_paw.webp';
  static const double _aspect = 512 / 640;
  static const double _wordAspect = 1336 / 530;

  /// Where the paw grips the letters, on the werewolf's canvas (512 × 640):
  /// werewolf and wordmark both turn around it, so the paw stays on its
  /// letter however differently the two turn.
  static const Offset _grip = Offset(440, 440);

  @override
  void initState() {
    super.initState();
    _time.addListener(_move);
  }

  /// Three long swings of unrelated lengths for each piece, and their
  /// strength swelling and ebbing itself: a slow, calm turn that never
  /// repeats, sometimes almost still, sometimes showing the board's edge.
  void _move() {
    final t = _time.value;
    double swing(List<(double, double, double)> waves, double ebb, double at) {
      var a = 0.0;
      for (final (amount, period, phase) in waves) {
        a += amount * sin(2 * pi * t / period + phase);
      }
      return a * (0.45 + 0.55 * pow(0.5 + 0.5 * sin(2 * pi * t / ebb + at), 2));
    }

    _wolfAngle.value = swing(
      const [
        (0.13, 23.7, 0),
        (0.06, 14.3, 1.1),
        (0.03, 9.1, 2.6),
      ],
      47,
      0.4,
    );
    _wordAngle.value = swing(
      const [
        (0.1, 29.3, 1.7),
        (0.045, 17.9, 0.3),
        (0.02, 11.3, 4.1),
      ],
      61,
      2.2,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _ticker.stop();
      _time.value = 1.2;
      _move();
    } else if (!_ticker.isActive) {
      unawaited(_ticker.start());
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    _wolfAngle.dispose();
    _wordAngle.dispose();
    super.dispose();
  }

  /// Rests long, then slowly leans over the letters and settles back;
  /// the rests are of different lengths.
  double get _reach {
    final t = _time.value;
    final cycle = (t / 13).floor();
    final into = t - cycle * 13;
    // Every cycle leans at its own moment and not every cycle leans.
    final start = 2 + 6 * ((sin(cycle * 12.9898) * 43758.5453) % 1).abs();
    if ((cycle * 7) % 5 == 3) return 0;
    final p = ((into - start) / 3.6).clamp(0.0, 1.0);
    return pow(sin(pi * p), 2).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final wordHeight = w * 0.4;
    final wolfHeight = w * 0.92;
    final wolfWidth = wolfHeight * _aspect;
    final wordTop = wolfHeight * 0.55;
    final wolfLeft = w * 0.5 - wolfWidth * 0.42;
    final height = wordTop + wordHeight;

    // The grip on the screen, and as an alignment on either piece.
    final grip = Offset(
      wolfLeft + _grip.dx / 512 * wolfWidth,
      _grip.dy / 640 * wolfHeight,
    );
    final wolfPivot = Alignment(
      _grip.dx / 512 * 2 - 1,
      _grip.dy / 640 * 2 - 1,
    );
    final wordWidth = wordHeight * _wordAspect;
    final wordLeft = (w - wordWidth) / 2;
    final wordPivot = Alignment(
      (grip.dx - wordLeft) / wordWidth * 2 - 1,
      (grip.dy - wordTop) / wordHeight * 2 - 1,
    );

    Widget wolf(String asset, {bool printOnly = false}) => AnimatedBuilder(
      animation: _time,
      // Leaning over the letters: the body tips forward around the paw,
      // which stays on its letter.
      builder: (context, child) => Transform.rotate(
        angle: 0.045 * _reach,
        alignment: wolfPivot,
        child: child,
      ),
      child: SizedBox(
        width: wolfWidth,
        height: wolfHeight,
        child: TurningFigure(
          asset: asset,
          height: wolfHeight,
          angle: _wolfAngle,
          pivot: wolfPivot,
          shadow: false,
          sway: false,
          printOnly: printOnly,
        ),
      ),
    );

    return Semantics(
      label: 'Whowolf',
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
          width: w,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Behind the letters, cut along their top: nothing of the
              // body shows through the gaps between them.
              Positioned.fill(
                child: ClipPath(
                  clipper: _AboveLetters(
                    tops: _letterTops,
                    top: wordTop,
                    height: wordHeight,
                    angle: _wordAngle,
                    pivot: grip,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(left: wolfLeft, top: 0, child: wolf(_wolf)),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: wordTop,
                height: wordHeight,
                child: Center(
                  child: TurningFigure(
                    asset: 'assets/brand/wordmark.png',
                    height: wordHeight,
                    angle: _wordAngle,
                    pivot: wordPivot,
                    shadow: false,
                    sway: false,
                  ),
                ),
              ),
              Positioned(
                left: wolfLeft,
                top: 0,
                child: wolf(_paw, printOnly: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Everything above the wordmark's letters, reaching a little way down
/// into them (they hide what is below). The line turns with the wordmark,
/// in the same perspective, so it stays on the letters as they turn.
class _AboveLetters extends CustomClipper<Path> {
  _AboveLetters({
    required this.tops,
    required this.top,
    required this.height,
    required this.angle,
    required this.pivot,
  }) : super(reclip: angle);

  final List<Offset> tops;
  final double top;
  final double height;
  final ValueListenable<double> angle;

  /// The upright the wordmark turns around, on the screen.
  final Offset pivot;

  @override
  Path getClip(Size size) {
    final depth = height * 0.22;
    final centre = pivot;
    // As TurningFigure turns the wordmark's print (see there).
    final turn = Matrix4.identity()
      ..setEntry(3, 2, 0.0011)
      ..rotateY(angle.value)
      ..translateByDouble(0, 0, height * 0.034 / 2 + 0.2, 1);
    Offset at(double x, double y) =>
        MatrixUtils.transformPoint(turn, Offset(x, y) - centre) + centre;
    final first = at(0, top + tops.first.dy * height + depth);
    final last = at(size.width, top + tops.last.dy * height + depth);
    final path = Path()
      ..moveTo(-size.width, -size.height)
      ..lineTo(size.width * 2, -size.height)
      ..lineTo(size.width * 2, last.dy);
    for (final p in tops.reversed) {
      final q = at(p.dx * size.width, top + p.dy * height + depth);
      path.lineTo(q.dx, q.dy);
    }
    return path
      ..lineTo(first.dx, first.dy)
      ..lineTo(-size.width, first.dy)
      ..close();
  }

  @override
  bool shouldReclip(_AboveLetters old) =>
      old.top != top ||
      old.height != height ||
      old.tops != tops ||
      old.angle != angle ||
      old.pivot != pivot;
}
