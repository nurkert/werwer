import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/src/game/poses.g.dart';
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

/// The file name of each persona's figure (`assets/figures/<name>.webp`).
const _personaFiles = <Persona, String>{
  Persona.maid: 'magd',
  Persona.farmer: 'dorfbewohner',
  Persona.baker: 'baeckerin',
  Persona.smith: 'schmied',
  Persona.fisher: 'fischerin',
  Persona.miller: 'mueller',
  Persona.seamstress: 'schneiderin',
  Persona.minstrel: 'spielmann',
  Persona.gooseGirl: 'gaensehirtin',
  Persona.beekeeper: 'imker',
  Persona.innkeeper: 'wirtin',
  Persona.shepherd: 'schaefer',
  Persona.washerwoman: 'waescherin',
  Persona.carpenter: 'zimmermann',
  Persona.spinner: 'spinnerin',
  Persona.cobbler: 'schuster',
  Persona.flowerGirl: 'blumenmaedchen',
  Persona.mayor: 'buergermeister',
  Persona.grandmother: 'grossmutter',
  Persona.grandfather: 'grossvater',
};

/// A persona's villager poses at work (task 012), besides its figure:
/// how many there are.
int poseCount(Persona persona) => [
  for (var n = 1; n <= 3; n++)
    if (poseFaces.containsKey('${_personaFiles[persona]}_$n')) n,
].length;

/// Which pose (0 = the figure itself, 1.. a pose at work) a persona strikes
/// for [salt]: the same on every phone for the same public values.
int poseFor(Persona persona, String salt) =>
    stableHash('$salt/${persona.name}') % (poseCount(persona) + 1);

/// The image and the face of [persona] in [pose] (see [poseFor]).
(String, (double, double, double)) posed(Persona persona, int pose) {
  final name = '${_personaFiles[persona]}_$pose';
  final face = poseFaces[name];
  return pose == 0 || face == null
      ? (personaAsset(persona), faceOf(persona))
      : ('assets/figures/poses/$name.webp', face);
}

/// The cardboard figure of a persona, as the villager they look like.
String personaAsset(Persona persona) =>
    'assets/figures/${_personaFiles[persona]}.webp';

/// The persona in the costume of [role]: the baker as a werewolf, the smith
/// as the seer. Villagers wear their everyday clothes.
String personaRoleAsset(Persona persona, Role role) => role == Role.villager
    ? personaAsset(persona)
    : 'assets/figures/roles/${_personaFiles[persona]}_${role.name}.webp';

/// Figures for decoration (start screen), all facing right.
const castAssets = [
  'assets/figures/magd.webp',
  'assets/figures/seherin.webp',
  'assets/figures/werwolf.webp',
  'assets/figures/dorfbewohner.webp',
  'assets/figures/jaeger.webp',
];

/// A role's figure, standing on its corrugated board and rocking a little.
class RoleFigure extends StatelessWidget {
  const RoleFigure({required this.role, required this.height, super.key});

  final Role role;
  final double height;

  @override
  Widget build(BuildContext context) =>
      TurningFigure(asset: figureAsset(role), height: height);
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
  Persona.maid: (0.50, 0.09, 313 / 640),
  Persona.farmer: (0.45, 0.10, 355 / 640),
  Persona.baker: (0.55, 0.08, 404 / 640),
  Persona.smith: (0.52, 0.09, 394 / 640),
  Persona.fisher: (0.55, 0.08, 367 / 640),
  Persona.miller: (0.55, 0.11, 410 / 640),
  Persona.seamstress: (0.55, 0.07, 289 / 640),
  Persona.minstrel: (0.60, 0.13, 379 / 640),
  Persona.gooseGirl: (0.55, 0.08, 385 / 640),
  Persona.beekeeper: (0.70, 0.17, 424 / 640),
  Persona.innkeeper: (0.55, 0.09, 415 / 640),
  Persona.shepherd: (0.50, 0.08, 329 / 640),
  Persona.washerwoman: (0.55, 0.08, 331 / 640),
  Persona.carpenter: (0.55, 0.09, 364 / 640),
  Persona.spinner: (0.55, 0.07, 298 / 640),
  Persona.cobbler: (0.62, 0.12, 312 / 640),
  Persona.flowerGirl: (0.58, 0.08, 298 / 640),
  Persona.mayor: (0.55, 0.13, 364 / 640),
  Persona.grandmother: (0.50, 0.13, 374 / 640),
  Persona.grandfather: (0.62, 0.13, 324 / 640),
};

/// Where [persona]'s face is in its figure: (x, y) as fractions of the
/// image, and the image's aspect ratio (width / height).
(double, double, double) faceOf(Persona persona) => _faces[persona]!;

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
  /// Plain kraft board in the figure's outline, with grain and a stamp.
  board,

  /// Printed on both sides: the mirrored face.
  print,
}

/// A cardboard cutout glued on corrugated board that turns around its
/// vertical axis: mid-turn its cut edge shows (liner, fluted middle, liner),
/// then its plain kraft back. [showBack] picks the side; changes animate
/// unless the system asks for reduced motion. With [sway] it rocks a little
/// on its own, so the board's thickness shows even while it stands still.
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
    this.sway = true,
    super.key,
  });

  final String asset;
  final String? backAsset;
  final double height;
  final bool showBack;
  final CardBack back;

  /// Printed on the kraft back (only for [CardBack.board]).
  final String stamp;

  /// Rock gently around the upright (off with reduced motion).
  final bool sway;

  @override
  State<TurningFigure> createState() => _TurningFigureState();
}

class _TurningFigureState extends State<TurningFigure>
    with TickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
    value: widget.showBack ? 1 : 0,
  );
  late final AnimationController _sway = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  );
  static final _random = Random();
  Timer? _nextRock;

  /// The next move: a rock to both sides, or a lean to one side that
  /// shows the board's edge (negative leans to the left).
  bool _lean = false;
  double _amount = 0.3;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final calm = MediaQuery.of(context).disableAnimations;
    if (widget.sway && !calm && _nextRock == null && !_sway.isAnimating) {
      _scheduleRock(first: true);
    } else if (calm) {
      _nextRock?.cancel();
      _nextRock = null;
      _sway
        ..stop()
        ..value = 0;
    }
  }

  /// Now and then the figure rocks once, so the board's thickness shows;
  /// in between it stands still facing front and costs nothing to draw.
  void _scheduleRock({bool first = false}) {
    final wait = first
        ? 600 + _random.nextInt(4000)
        : 9000 + _random.nextInt(9000);
    _nextRock = Timer(Duration(milliseconds: wait), () async {
      if (!mounted) return;
      _lean = _random.nextBool();
      _amount = _lean
          ? (0.45 + _random.nextDouble() * 0.25) * (_random.nextBool() ? 1 : -1)
          : 0.3;
      await _sway.forward(from: 0).orCancel.catchError((Object _) {});
      if (mounted) _scheduleRock();
    });
  }

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
    _nextRock?.cancel();
    _turn.dispose();
    _sway.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([_turn, _sway]),
    builder: (context, _) {
      // A rock (about ±15°) or a half lean to one side (25–40°), both
      // easing in and out of the upright.
      final v = _sway.value;
      final rock = _lean
          ? pow(sin(v * pi), 2) * _amount
          : sin(v * 2 * pi) * sin(v * pi) * _amount;
      final angle = _turn.value * pi + rock;
      final facing = cos(angle) >= 0;
      final asset = facing ? widget.asset : (widget.backAsset ?? widget.asset);
      // Facing (nearly) straight on, the edge is under a pixel wide: one
      // flat picture instead of a dozen layers.
      if ((_depth * sin(angle)).abs() < 0.6) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0011)
            ..rotateY(angle),
          child: facing || widget.back == CardBack.print
              ? _image(asset)
              : _Board(
                  asset: asset,
                  height: widget.height,
                  stamp: widget.stamp,
                ),
        );
      }
      // Every layer stands at its own depth and turns with the figure, so
      // the board is real 3D: drawn from the farthest layer to the nearest.
      final layers = [
        ..._board(asset),
        if (facing)
          (z: _depth / 2 + 0.2, child: _image(asset))
        else
          (
            z: -_depth / 2 - 0.2,
            child: widget.back == CardBack.print
                ? _image(asset)
                : _Board(
                    asset: asset,
                    height: widget.height,
                    stamp: widget.stamp,
                  ),
          ),
      ]..sort((a, b) => (a.z * cos(angle)).compareTo(b.z * cos(angle)));
      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          for (final layer in layers)
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0011)
                ..rotateY(angle)
                ..translateByDouble(0, 0, layer.z, 1),
              child: layer.child,
            ),
        ],
      );
    },
  );

  static const _liner = Color(0xFFC9A26B);
  static const _flute = Color(0xFFB0844E);
  static const _core = Color(0xFF4E3620);
  static const _flutes = 8;

  /// How thick the board is: about a 30th of the figure's height.
  double get _depth => widget.height * 0.034;

  /// The corrugated board behind the print, as layers of the outline in
  /// depth: two liners, the dark core and flutes in bands whose phase moves
  /// from layer to layer, so edge-on they make the zigzag of the board.
  List<({double z, Widget child})> _board(String asset) {
    final d = _depth;
    final flute = widget.height / 70;
    return [
      (z: d / 2, child: _tinted(asset, _liner)),
      (z: -d / 2, child: _tinted(asset, _liner)),
      (z: 0, child: _tinted(asset, _core)),
      for (var i = 0; i < _flutes; i++)
        (
          z: d * ((i + 0.5) / _flutes - 0.5) * 0.92,
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (_) => ui.Gradient.linear(
              Offset(0, flute * i / _flutes),
              Offset(0, flute * (1 + i / _flutes)),
              const [Colors.white, Colors.white, Colors.transparent],
              const [0, 0.32, 0.33],
              TileMode.repeated,
            ),
            child: _tinted(asset, _flute),
          ),
        ),
    ];
  }

  Widget _image(String asset) =>
      Image.asset(asset, height: widget.height, fit: BoxFit.contain);

  Widget _tinted(String asset, Color color) => ColorFiltered(
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    child: _image(asset),
  );
}

/// The kraft back of a cutout: the outline in board brown, a soft grain and
/// a crooked stamp (counter-mirrored, as the turn mirrors everything).
class _Board extends StatelessWidget {
  const _Board({
    required this.asset,
    required this.height,
    required this.stamp,
  });

  final String asset;
  final double height;
  final String stamp;

  static const _board = Color(0xFFB48A57);

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
