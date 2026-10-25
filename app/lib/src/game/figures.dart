import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

/// The cardboard figure of a role.
String figureAsset(Role role) => switch (role) {
  Role.villager => 'assets/figures/dorfbewohner.webp',
  Role.werewolf => 'assets/figures/werwolf.webp',
  Role.seer => 'assets/figures/seherin.webp',
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
  Persona.greyWolf: (0.72, 0.20, 512 / 640),
};

/// A round portrait of a persona, zoomed onto the face.
class Portrait extends StatelessWidget {
  const Portrait({required this.persona, this.size = 40, super.key});

  final Persona persona;
  final double size;

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
    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: ColoredBox(
          color: const Color(0xFF2B3A6E),
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
  }
}
