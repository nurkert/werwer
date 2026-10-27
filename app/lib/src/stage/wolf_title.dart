import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  /// The slow clock everything moves by.
  late final AnimationController _time = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
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

  @override
  void initState() {
    super.initState();
    _time.addListener(_move);
  }

  /// Two slow swings of different length for each piece: the turn never
  /// repeats quite the same, the board's edge shows now left, now right.
  void _move() {
    final t = _time.value * 60;
    _wolfAngle.value =
        0.26 * sin(2 * pi * t / 7.3) + 0.1 * sin(2 * pi * t / 3.1);
    _wordAngle.value =
        0.2 * sin(2 * pi * t / 9.7 + 1.3) + 0.07 * sin(2 * pi * t / 4.3);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _time
        ..stop()
        ..value = 0.02;
      _move();
    } else if (!_time.isAnimating) {
      unawaited(_time.repeat());
    }
  }

  @override
  void dispose() {
    _time.dispose();
    _wolfAngle.dispose();
    _wordAngle.dispose();
    super.dispose();
  }

  /// Rests, leans forward and reaches over, settles back (every 8 s).
  double get _reach {
    final t = (_time.value * 60 / 8) % 1;
    return pow(sin(pi * (t * 2).clamp(0.0, 1.0)), 2).toDouble();
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

    Widget wolf(String asset, {bool printOnly = false}) => AnimatedBuilder(
      animation: _time,
      builder: (context, child) {
        final reach = _reach;
        return Transform(
          alignment: Alignment.bottomLeft,
          transform: Matrix4.identity()
            ..translateByDouble(0, wolfHeight * 0.05 * reach, 0, 1)
            ..rotateZ(0.07 * reach),
          child: child,
        );
      },
      child: SizedBox(
        width: wolfWidth,
        height: wolfHeight,
        child: TurningFigure(
          asset: asset,
          height: wolfHeight,
          angle: _wolfAngle,
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
  }) : super(reclip: angle);

  final List<Offset> tops;
  final double top;
  final double height;
  final ValueListenable<double> angle;

  @override
  Path getClip(Size size) {
    final depth = height * 0.22;
    final centre = Offset(size.width / 2, top + height / 2);
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
      old.angle != angle;
}
