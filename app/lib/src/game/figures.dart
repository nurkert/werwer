import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

/// The cardboard figure of a role.
String figureAsset(Role role) => switch (role) {
  Role.villager => 'assets/figures/dorfbewohner.webp',
  Role.werewolf => 'assets/figures/werwolf.webp',
  Role.seer => 'assets/figures/seherin.webp',
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

/// A round portrait: the figure's head, or the emblem when the role is secret.
class Portrait extends StatelessWidget {
  const Portrait({required this.role, this.size = 40, super.key});

  final Role? role;
  final double size;

  @override
  Widget build(BuildContext context) {
    final role = this.role;
    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: ColoredBox(
          color: const Color(0xFF2B3A6E),
          child: role == null
              ? Padding(
                  padding: EdgeInsets.all(size * 0.12),
                  child: Opacity(
                    opacity: 0.55,
                    child: Image.asset('assets/brand/emblem.png'),
                  ),
                )
              : OverflowBox(
                  maxHeight: size * 3.2,
                  alignment: Alignment.topCenter,
                  child: Image.asset(
                    figureAsset(role),
                    height: size * 3.2,
                    fit: BoxFit.fitHeight,
                  ),
                ),
        ),
      ),
    );
  }
}
