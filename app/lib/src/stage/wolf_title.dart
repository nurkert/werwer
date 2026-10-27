import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

/// The start screen's title (task 012): the werewolf stands big behind the
/// wordmark, looking out over it, and leans forward now and then so its
/// paw reaches over the letters. The paw is the same picture again, cut
/// to the hand and laid in front of the wordmark; both move as one.
class WolfTitle extends StatefulWidget {
  const WolfTitle({required this.width, super.key});

  /// How wide the wordmark is.
  final double width;

  @override
  State<WolfTitle> createState() => _WolfTitleState();
}

class _WolfTitleState extends State<WolfTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lean = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  );

  /// Where the hand is in the werewolf's picture (fractions).
  static const Rect _paw = Rect.fromLTRB(0.6, 0.46, 1, 0.72);

  static const _wolf = 'assets/figures/werwolf.webp';
  static const double _aspect = 512 / 640;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _lean
        ..stop()
        ..value = 0.25;
    } else if (!_lean.isAnimating) {
      unawaited(_lean.repeat());
    }
  }

  @override
  void dispose() {
    _lean.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final wordHeight = w * 0.4;
    final wolfHeight = w * 0.92;
    final wolfWidth = wolfHeight * _aspect;
    // The wordmark's top sits at the paw's height; the wolf stands behind,
    // a little to the right, its head well above the letters.
    final wordTop = wolfHeight * 0.55;
    final wolfLeft = w * 0.5 - wolfWidth * 0.42;
    final height = wordTop + wordHeight;

    Widget wolf({required bool pawOnly}) {
      final picture = Image.asset(
        _wolf,
        width: wolfWidth,
        height: wolfHeight,
        fit: BoxFit.fill,
      );
      final cut = pawOnly
          ? ClipRect(clipper: const _PawClip(_paw), child: picture)
          : picture;
      return AnimatedBuilder(
        animation: _lean,
        builder: (context, child) {
          // Rests, leans forward and reaches over, settles back.
          final t = _lean.value;
          final reach = pow(sin(pi * (t * 2).clamp(0.0, 1.0)), 2).toDouble();
          return Transform(
            alignment: Alignment.bottomLeft,
            transform: Matrix4.identity()
              ..translateByDouble(0, wolfHeight * 0.05 * reach, 0, 1)
              ..rotateZ(0.07 * reach),
            child: child,
          );
        },
        child: cut,
      );
    }

    return ExcludeSemantics(
      excluding: false,
      child: Semantics(
        label: 'Whowolf',
        image: true,
        child: SizedBox(
          width: w,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Behind the letters, cut off halfway down them: no legs
              // showing below the wordmark.
              Positioned(
                left: wolfLeft - wolfWidth * 0.2,
                top: 0,
                width: wolfWidth * 1.4,
                height: wordTop + wordHeight * 0.55,
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    minWidth: wolfWidth,
                    maxWidth: wolfWidth,
                    minHeight: wolfHeight,
                    maxHeight: wolfHeight,
                    child: ExcludeSemantics(child: wolf(pawOnly: false)),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: wordTop,
                height: wordHeight,
                child: ExcludeSemantics(
                  child: Image.asset(
                    'assets/brand/wordmark.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                left: wolfLeft,
                top: 0,
                child: ExcludeSemantics(child: wolf(pawOnly: true)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PawClip extends CustomClipper<Rect> {
  const _PawClip(this.part);

  final Rect part;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(
    part.left * size.width,
    part.top * size.height,
    part.right * size.width,
    part.bottom * size.height,
  );

  @override
  bool shouldReclip(_PawClip old) => old.part != part;
}
