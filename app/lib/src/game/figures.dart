import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/src/game/stage.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/theme.dart';

/// The cardboard figure of a role.
String figureAsset(Role role) => switch (role) {
  Role.villager => 'assets/figures/dorfbewohner.webp',
  Role.werewolf => 'assets/figures/werwolf.webp',
  Role.seer => 'assets/figures/seherin.webp',
  Role.witch => 'assets/figures/hexe.webp',
  Role.hunter => 'assets/figures/jaeger.webp',
  Role.cupid => 'assets/figures/amor.webp',
};

/// The cardboard figure of a persona.
String personaAsset(Persona persona) => switch (persona) {
  Persona.maid => 'assets/figures/magd.webp',
  Persona.lanternBearer => 'assets/figures/seherin.webp',
  Persona.greyWolf => 'assets/figures/werwolf.webp',
  Persona.farmer => 'assets/figures/dorfbewohner.webp',
  Persona.hunter => 'assets/figures/jaeger.webp',
  Persona.herbWitch => 'assets/figures/hexe.webp',
  Persona.cupid => 'assets/figures/amor.webp',
  Persona.guard => 'assets/figures/beschuetzer.webp',
  Persona.tracker => 'assets/figures/faehrtenleger.webp',
  Persona.listener => 'assets/figures/lauscherin.webp',
  Persona.quietPaw => 'assets/figures/stille_pfote.webp',
  Persona.baker => 'assets/figures/baeckerin.webp',
  Persona.fisher => 'assets/figures/fischerin.webp',
  Persona.seamstress => 'assets/figures/schneiderin.webp',
  Persona.gooseGirl => 'assets/figures/gaensehirtin.webp',
  Persona.innkeeper => 'assets/figures/wirtin.webp',
  Persona.smith => 'assets/figures/schmied.webp',
  Persona.miller => 'assets/figures/mueller.webp',
  Persona.minstrel => 'assets/figures/spielmann.webp',
  Persona.beekeeper => 'assets/figures/imker.webp',
};

/// Figures for decoration (start screen), all facing right.
const castAssets = [
  'assets/figures/magd.webp',
  'assets/figures/seherin.webp',
  'assets/figures/werwolf.webp',
  'assets/figures/dorfbewohner.webp',
  'assets/figures/jaeger.webp',
];

/// A role's figure, standing, with a soft shadow like on the website.
class RoleFigure extends StatelessWidget {
  const RoleFigure({required this.role, required this.height, super.key});

  final Role role;
  final double height;

  @override
  Widget build(BuildContext context) => Figure(
    asset: figureAsset(role),
    height: height,
  );
}

class Figure extends StatelessWidget {
  const Figure({required this.asset, required this.height, super.key});

  final String asset;
  final double height;

  @override
  Widget build(BuildContext context) =>
      Image.asset(asset, height: height, fit: BoxFit.contain);
}

/// Where a persona's face is in its figure: (x, y) as fractions of the
/// image, and the image's aspect ratio (width / height).
const _faces = <Persona, (double, double, double)>{
  Persona.cupid: (0.45, 0.12, 462 / 640),
  Persona.guard: (0.40, 0.10, 391 / 640),
  Persona.farmer: (0.45, 0.10, 355 / 640),
  Persona.tracker: (0.62, 0.15, 535 / 627),
  Persona.herbWitch: (0.45, 0.20, 435 / 640),
  Persona.hunter: (0.47, 0.09, 405 / 640),
  Persona.listener: (0.45, 0.12, 492 / 640),
  Persona.maid: (0.50, 0.09, 313 / 640),
  Persona.lanternBearer: (0.56, 0.10, 426 / 640),
  Persona.quietPaw: (0.72, 0.15, 414 / 640),
  Persona.baker: (0.55, 0.08, 404 / 640),
  Persona.fisher: (0.55, 0.08, 367 / 640),
  Persona.seamstress: (0.55, 0.07, 289 / 640),
  Persona.gooseGirl: (0.55, 0.08, 385 / 640),
  Persona.innkeeper: (0.55, 0.09, 415 / 640),
  Persona.smith: (0.52, 0.09, 394 / 640),
  Persona.miller: (0.55, 0.11, 410 / 640),
  Persona.minstrel: (0.60, 0.13, 379 / 640),
  Persona.beekeeper: (0.70, 0.17, 424 / 640),
  Persona.greyWolf: (0.72, 0.20, 512 / 640),
};

/// A round portrait of a persona, zoomed onto the face, cut from card with
/// a pale edge like the figures. [grey] for players who are out.
class Portrait extends StatelessWidget {
  const Portrait({
    required this.persona,
    this.size = 40,
    this.grey = false,
    super.key,
  });

  final Persona persona;
  final double size;
  final bool grey;

  static const _greyscale = ColorFilter.matrix([
    0.30, 0.59, 0.11, 0, 0, //
    0.30, 0.59, 0.11, 0, 0, //
    0.30, 0.59, 0.11, 0, 0, //
    0, 0, 0, 1, 0,
  ]);

  /// Alignment that puts [focus] (0..1 along the child) at the centre of a
  /// parent of [parent] size holding a child of [child] size.
  static double _align(double focus, double child, double parent) {
    final value = 2 * (parent / 2 - focus * child) / (parent - child) - 1;
    return value.clamp(-1.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final (fx, fy, aspect) = _faces[persona]!;
    final height = size * 2.6;
    final width = height * aspect;
    final face = ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: ColoredBox(
          color: Palette.night500,
          child: OverflowBox(
            maxWidth: width,
            minWidth: width,
            maxHeight: height,
            minHeight: height,
            alignment: Alignment(
              _align(fx, width, size),
              _align(fy, height, size),
            ),
            child: Image.asset(personaAsset(persona), fit: BoxFit.fill),
          ),
        ),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Palette.card200, width: size / 18),
        boxShadow: const [
          BoxShadow(color: Color(0x80000000), offset: Offset(0, 2)),
        ],
      ),
      child: grey ? ColorFiltered(colorFilter: _greyscale, child: face) : face,
    );
  }
}

/// What a turned-around cutout shows.
enum CardBack {
  /// Plain grey board in the figure's outline, with grain and a stamp.
  board,

  /// Printed on both sides: the mirrored face.
  print,
}

/// A cardboard cutout that turns around its vertical axis: mid-turn its cut
/// edge shows (a few layers of brown card), then its back. [showBack] picks
/// the side; changes animate unless the system asks for reduced motion.
///
/// The back is cut to [backAsset]'s outline (default: the front's), so a
/// hidden role can stand as a persona seen from behind and turn into the
/// role's figure: at the edge-on moment nobody sees the swap.
class TurningFigure extends StatefulWidget {
  const TurningFigure({
    required this.asset,
    required this.height,
    this.showBack = false,
    this.backAsset,
    this.back = CardBack.board,
    this.stamp = 'Whowolf',
    super.key,
  });

  final String asset;
  final String? backAsset;
  final double height;
  final bool showBack;
  final CardBack back;

  /// Printed on the grey board (only for [CardBack.board]).
  final String stamp;

  @override
  State<TurningFigure> createState() => _TurningFigureState();
}

class _TurningFigureState extends State<TurningFigure>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
    value: widget.showBack ? 1 : 0,
  );

  @override
  void didUpdateWidget(TurningFigure old) {
    super.didUpdateWidget(old);
    if (old.showBack == widget.showBack) return;
    final target = widget.showBack ? 1.0 : 0.0;
    if (MediaQuery.of(context).disableAnimations) {
      _turn.value = target;
    } else {
      unawaited(
        _turn.animateTo(target, curve: const Cubic(0.45, 0, 0.2, 1)),
      );
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _turn,
    builder: (context, _) {
      final angle = _turn.value * pi;
      final facing = cos(angle) >= 0;
      // The edge is thin: a few pixels at a phone's figure size, most
      // visible edge-on.
      final thickness = widget.height * 0.014 * sin(angle).abs();
      final asset = facing ? widget.asset : (widget.backAsset ?? widget.asset);
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0011)
          ..rotateY(angle),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 3; i >= 1; i--)
              Transform.translate(
                offset: Offset((facing ? 1 : -1) * thickness * i / 3, 0),
                child: _tinted(asset, i == 2 ? _edgeDark : _edgeLight),
              ),
            if (facing)
              _image(asset)
            else if (widget.back == CardBack.print)
              _image(asset)
            else
              _Board(
                asset: asset,
                height: widget.height,
                stamp: widget.stamp,
              ),
          ],
        ),
      );
    },
  );

  static const _edgeLight = Color(0xFF7A5A3A);
  static const _edgeDark = Color(0xFF5A3F27);

  Widget _image(String asset) =>
      Image.asset(asset, height: widget.height, fit: BoxFit.contain);

  Widget _tinted(String asset, Color color) => ColorFiltered(
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    child: _image(asset),
  );
}

/// The grey back of a cutout: the outline in board grey, a soft grain and a
/// crooked stamp (counter-mirrored, as the turn mirrors everything).
class _Board extends StatelessWidget {
  const _Board({
    required this.asset,
    required this.height,
    required this.stamp,
  });

  final String asset;
  final double height;
  final String stamp;

  static const _board = Color(0xFFA7A196);

  @override
  Widget build(BuildContext context) {
    final grain = Grain.softImage;
    final outline = ColorFiltered(
      colorFilter: const ColorFilter.mode(_board, BlendMode.srcIn),
      child: Image.asset(asset, height: height, fit: BoxFit.contain),
    );
    return Stack(
      alignment: const Alignment(0, -0.05),
      children: [
        if (grain == null)
          outline
        else
          // Multiplied in (the default blend), so only the board gets grain.
          ShaderMask(
            shaderCallback: (_) => ImageShader(
              grain,
              TileMode.repeated,
              TileMode.repeated,
              Matrix4.identity().storage,
            ),
            child: outline,
          ),
        Transform.flip(
          flipX: true,
          child: Stamp(
            stamp,
            color: Palette.curtain700.withValues(alpha: 0.6),
            size: height * 0.06,
            angle: -0.14,
          ),
        ),
      ],
    );
  }
}
