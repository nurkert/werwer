import 'dart:math';

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/src/game/figures.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/stage/mayor_mark.dart';
import 'package:whowolf/src/stage/stage_kit.dart';
import 'package:whowolf/src/stage/tappable.dart';
import 'package:whowolf/src/theme.dart';

/// A player as a card to choose (task 012): the persona's upper body on a
/// dark board, the name on a small plaque below, a brass tick when chosen.
/// The dead are grey with a stamp. Shows the persona only, never a role.
class PuppetCard extends StatelessWidget {
  const PuppetCard({
    required this.persona,
    required this.name,
    required this.width,
    super.key,
    this.subtitle = '',
    this.selected = false,
    this.alive = true,
    this.you = false,
    this.onTap,
    this.deadLabel,
    this.trailing,
    this.pose = 0,
    this.mayor,
  });

  /// Which villager pose (see `poseFor`); 0 is the figure itself.
  final int pose;

  final Persona persona;
  final String name;
  final double width;

  /// A small line under the name (you, a known role, a badge).
  final String subtitle;
  final bool selected;
  final bool alive;
  final bool you;
  final VoidCallback? onTap;

  /// The stamp on a dead player's card.
  final String? deadLabel;

  /// Something extra in the corner (e.g. a remove button).
  final Widget? trailing;

  /// Set for the living mayor: the chain of office in the corner, and
  /// this word for screen readers.
  final String? mayor;

  static const _greyscale = ColorFilter.matrix([
    0.30, 0.59, 0.11, 0, 0, //
    0.30, 0.59, 0.11, 0, 0, //
    0.30, 0.59, 0.11, 0, 0, //
    0, 0, 0, 1, 0,
  ]);

  /// Half of the turn for each card: the leaving one turns to its edge in
  /// the first half, the coming one from its edge in the second.
  static Widget _turn(Widget child, Animation<double> animation) =>
      AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) {
          final t = animation.value;
          final open = t < 0.5 ? 0.0 : (t - 0.5) * 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY((1 - open) * pi / 2),
            child: Opacity(opacity: open == 0 ? 0 : 1, child: child),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final height = width * 1.12;
    final (asset, (fx, fy, aspect)) = posed(persona, pose);
    // The figure big enough that the head and shoulders fill the card,
    // the face a little above the middle.
    final figureHeight = height * 2.05;
    final figureWidth = figureHeight * aspect;
    double align(double focus, double child, double parent, double at) =>
        (2 * (parent * at - focus * child) / (parent - child) - 1).clamp(
          -1.0,
          1.0,
        );
    Widget picture = OverflowBox(
      maxWidth: figureWidth,
      minWidth: figureWidth,
      maxHeight: figureHeight,
      minHeight: figureHeight,
      alignment: Alignment(
        align(fx, figureWidth, width, 0.5),
        align(fy, figureHeight, height, 0.36),
      ),
      child: Image.asset(asset, fit: BoxFit.fill, gaplessPlayback: true),
    );
    if (!alive) {
      picture = Opacity(
        opacity: 0.6,
        child: ColorFiltered(colorFilter: _greyscale, child: picture),
      );
    }
    final reduce = MediaQuery.of(context).disableAnimations;
    final label = [
      name,
      ?mayor,
      if (subtitle.isNotEmpty) subtitle,
    ].join(', ');
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: AnimatedSlide(
        // A chosen card lifts a little off the stage.
        offset: selected ? const Offset(0, -0.035) : Offset.zero,
        duration: reduce ? Duration.zero : const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: Tappable(
          radius: Radii.m,
          onTap: onTap,
          child: SizedBox(
            width: width,
            height: height,
            // A new figure turns in like a cardboard card: the old one
            // turns away edge-on, the new one turns towards the table.
            child: AnimatedSwitcher(
              duration: reduce
                  ? Duration.zero
                  : const Duration(milliseconds: 620),
              transitionBuilder: _turn,
              layoutBuilder: (current, previous) => Stack(
                clipBehavior: Clip.none,
                children: [...previous, ?current],
              ),
              child: Stack(
                key: ValueKey(persona),
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: PlaqueDecoration(lit: selected),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(Radii.m - 4),
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment(0, -0.4),
                                radius: 0.9,
                                colors: [Color(0xFF2B3C5A), Color(0xFF0E1726)],
                              ),
                            ),
                            child: picture,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // The name on a small plaque at the foot, a little wider
                  // than the card, so names up to the allowed length fit (on
                  // two lines if need be) instead of being cut off.
                  Positioned(
                    left: -8,
                    right: -8,
                    bottom: 6,
                    child: DecoratedBox(
                      decoration: const PlaqueDecoration(radius: 10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              name,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: displayFont,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                                fontSize: name.length > 12
                                    ? 12.5
                                    : (width < 110 ? 14 : 16),
                                color: you
                                    ? Palette.stageLanternTop
                                    : Palette.stageIvory,
                              ),
                            ),
                            if (subtitle.isNotEmpty)
                              Text(
                                subtitle,
                                maxLines: width < 110 ? 1 : 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  height: 1.2,
                                  color: Palette.stageIvorySoft,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (selected)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Palette.stagePlaque,
                          border: Border.fromBorderSide(
                            BorderSide(
                              color: Palette.stageLanternTop,
                              width: 2,
                            ),
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 17,
                          color: Palette.stageLanternTop,
                        ),
                      ),
                    ),
                  if (!alive && deadLabel != null)
                    Positioned(
                      left: 8,
                      top: height * 0.32,
                      child: Stamp(
                        deadLabel!,
                        color: Palette.curtain400,
                        angle: -0.18,
                      ),
                    ),
                  if (mayor != null)
                    Positioned(
                      left: -6,
                      top: -6,
                      child: MayorPlaque(
                        label: mayor!,
                        size: width < 90 ? 26 : 32,
                      ),
                    ),
                  if (trailing != null)
                    Positioned(left: 2, top: 2, child: trailing!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
