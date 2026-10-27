import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:whowolf/src/stage/scene.dart';
import 'package:whowolf/src/stage/scenery.g.dart';
import 'package:whowolf/src/stage/tilt.dart';

/// Where a piece of scenery stands.
enum Edge {
  /// On the floor at the left or right side.
  left,
  right,

  /// Hanging in from the upper left or right corner.
  topLeft,
  topRight,

  /// Along the whole top edge.
  top,

  /// Hanging from the top at the left or right side, as tall as the
  /// window (curtains).
  hangLeft,
  hangRight,
}

/// One cardboard cut-out of a scene (task 012): which piece, where, how big
/// and how deep it stands, and from which window width on it shows.
typedef Piece = ({
  String name,
  Edge edge,

  /// Height as a part of the window's height (top: as a part of its width).
  double size,

  /// How much of the piece reaches into the window (0 to 1).
  double reach,

  /// How far it moves when the phone tilts: the front most.
  double depth,

  /// Pushed further into the window, as a part of its width (back pieces).
  double inset,

  /// Raised from the floor, as a part of the window's height.
  double lift,

  /// Shown only from this window width on: wide windows get more.
  double from,

  /// Drawn mirrored, for the other side.
  bool mirror,
});

Piece _p(
  String name,
  Edge edge, {
  required double size,
  double reach = 0.55,
  double depth = 16,
  double inset = 0,
  double lift = 0,
  double from = 0,
  bool mirror = false,
}) => (
  name: name,
  edge: edge,
  size: size,
  reach: reach,
  depth: depth,
  inset: inset,
  lift: lift,
  from: from,
  mirror: mirror,
);

/// The scenery of each scene, back to front.
List<Piece> sceneryOf(Scene scene) => switch (scene) {
  Scene.village => [
    _p(
      'stall',
      Edge.right,
      size: 0.42,
      reach: 0.9,
      inset: 0.13,
      depth: 7,
      from: 1000,
    ),
    _p(
      'lamppost',
      Edge.left,
      size: 0.5,
      reach: 0.9,
      inset: 0.12,
      depth: 9,
      from: 700,
    ),
    _p(
      'fence',
      Edge.right,
      size: 0.2,
      reach: 0.95,
      inset: 0.08,
      depth: 11,
      from: 600,
    ),
    _p('oak', Edge.left, size: 0.78, reach: 0.48),
    _p('house', Edge.right, size: 0.8, reach: 0.45),
  ],
  Scene.dusk || Scene.finale => [
    _p('garland', Edge.top, size: 1, reach: 0.6, depth: 6),
    _p(
      'lamppost',
      Edge.right,
      size: 0.5,
      reach: 0.9,
      inset: 0.12,
      depth: 9,
      from: 800,
    ),
    _p(
      'fence',
      Edge.left,
      size: 0.2,
      reach: 0.95,
      inset: 0.08,
      depth: 11,
      from: 700,
      mirror: true,
    ),
    _p('house', Edge.left, size: 0.8, reach: 0.45, mirror: true),
    _p('stall', Edge.right, size: 0.58),
  ],
  Scene.morning => [
    _p(
      'branch',
      Edge.topRight,
      size: 0.5,
      reach: 0.85,
      depth: 10,
      from: 900,
      mirror: true,
    ),
    _p(
      'fence',
      Edge.left,
      size: 0.2,
      reach: 0.95,
      inset: 0.1,
      depth: 11,
      from: 1000,
      mirror: true,
    ),
    _p('apple', Edge.left, size: 0.7, reach: 0.5),
    _p('hay', Edge.right, size: 0.26, reach: 0.75),
  ],
  Scene.nightLake || Scene.finaleWolves => [
    _p('pinebranch', Edge.topLeft, size: 0.48, reach: 0.85, depth: 10),
    _p(
      'birch',
      Edge.left,
      size: 0.55,
      reach: 0.9,
      inset: 0.12,
      depth: 8,
      from: 900,
    ),
    _p(
      'reeds',
      Edge.right,
      size: 0.22,
      reach: 0.9,
      inset: 0.1,
      depth: 11,
      from: 600,
    ),
    _p('pines', Edge.left, size: 0.82, reach: 0.45),
    _p('owl', Edge.right, size: 0.8, reach: 0.45),
  ],
  Scene.hunt => [
    _p(
      'pinebranch',
      Edge.topRight,
      size: 0.48,
      reach: 0.85,
      depth: 10,
      mirror: true,
    ),
    _p(
      'birch',
      Edge.right,
      size: 0.55,
      reach: 0.9,
      inset: 0.12,
      depth: 8,
      from: 900,
      mirror: true,
    ),
    _p('owl', Edge.left, size: 0.8, reach: 0.45, mirror: true),
    _p('pines', Edge.right, size: 0.82, reach: 0.45, mirror: true),
  ],
  Scene.finaleLovers => [
    _p('garland', Edge.top, size: 1, reach: 0.6, depth: 6),
    _p('apple', Edge.left, size: 0.7, reach: 0.5),
    _p('birch', Edge.right, size: 0.62, mirror: true),
  ],
  Scene.theatre => [
    _p('valance', Edge.top, size: 1, reach: 0.7, depth: 5),
    _p('curtain', Edge.hangLeft, size: 1.04, reach: 0.5, depth: 12),
    _p(
      'curtain',
      Edge.hangRight,
      size: 1.04,
      reach: 0.5,
      depth: 12,
      mirror: true,
    ),
  ],
  Scene.backstage || Scene.curtain => const [],
};

/// Which part of a panorama a [Scenery] stands in (see [Scenery.side]).
enum ScenerySide {
  /// The whole set, in the middle.
  whole,

  /// The page left of the middle one.
  before,

  /// The page right of the middle one.
  after,
}

/// The scenery standing in a scene, as many pieces as the window's width
/// has room for, each a cardboard cut-out shifting at its own depth when
/// the phone tilts.
class Scenery extends StatelessWidget {
  const Scenery({
    required this.scene,
    super.key,
    this.tint,
    this.side = ScenerySide.whole,
    this.span = 1,
  });

  final Scene scene;

  /// The pages beside the middle one, when swiping pans across the set:
  /// the middle set's pieces reach over into them, so they only get the
  /// pieces of their far edge, other pieces than the middle set has on
  /// that side (the ones of its other side).
  final ScenerySide side;

  /// How many window widths the pieces along the top run across, centred
  /// on this one (the middle set of a panorama hangs them for all pages).
  final int span;

  static bool _isLeft(Edge e) =>
      e == Edge.left || e == Edge.topLeft || e == Edge.hangLeft;

  static Edge _across(Edge e) => switch (e) {
    Edge.left => Edge.right,
    Edge.right => Edge.left,
    Edge.topLeft => Edge.topRight,
    Edge.topRight => Edge.topLeft,
    Edge.hangLeft => Edge.hangRight,
    Edge.hangRight => Edge.hangLeft,
    Edge.top => Edge.top,
  };

  /// A colour multiplied into every piece (a finale borrowing a set).
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        final children = <Widget>[];
        for (final piece in sceneryOf(scene)) {
          final aspect = sceneryAspects[piece.name];
          if (aspect == null || w < piece.from) continue;
          var edge = piece.edge;
          var mirror = piece.mirror;
          if (side != ScenerySide.whole) {
            if (edge == Edge.top) continue;
            // The middle set's pieces of the side facing this page, moved
            // to its far edge and turned to face in.
            if (_isLeft(edge) != (side == ScenerySide.after)) continue;
            edge = _across(edge);
            mirror = !mirror;
          }
          if (edge == Edge.top) {
            // Along the top in as many lengths as the width needs, each no
            // taller than a fifth of the window: wide screens get more.
            final segment = min(w * piece.size, h * 0.2 * aspect);
            final run = w * span;
            final count = (run / segment).ceil();
            final height = segment / aspect;
            final start = (w - count * segment) / 2;
            for (var i = 0; i < count; i++) {
              children.add(
                Positioned(
                  left: start + i * segment,
                  top: -height * (1 - piece.reach),
                  width: segment,
                  height: height,
                  child: TiltShift(
                    depth: piece.depth,
                    child: CardboardPiece(
                      asset: 'assets/stage/scenery/${piece.name}.webp',
                      mirror: i.isOdd && piece.mirror,
                      tint: tint,
                    ),
                  ),
                ),
              );
            }
            continue;
          }
          late final double width;
          late final double height;
          late final double left;
          late final double top;
          switch (edge) {
            case Edge.top:
              continue;
            case Edge.topLeft || Edge.topRight:
              width = min(w * piece.size, h * 0.42 * aspect);
              height = width / aspect;
              final inside = width * piece.reach;
              left = edge == Edge.topLeft ? inside - width : w - inside;
              top = -height * 0.04;
            case Edge.hangLeft || Edge.hangRight:
              height = h * piece.size;
              width = height * aspect;
              final inside = min(width * piece.reach, w * 0.22);
              left = edge == Edge.hangLeft ? inside - width : w - inside;
              top = -h * 0.02;
            case Edge.left || Edge.right:
              // Never taller than the window allows for its width: on a
              // phone the pieces stay a frame, never a wall.
              // Never wider than most of a phone either: what reaches
              // past the edge passes over into the next page when swiping.
              height = min(
                min(h * piece.size, w * 1.7),
                w < 600 ? w * 0.8 / aspect : double.infinity,
              );
              width = height * aspect;
              // On a phone a narrower strip, so text stays clear.
              final inside = min(
                width * piece.reach,
                w * (w < 600 ? 0.24 : 0.34),
              );
              final inset = w * piece.inset;
              left = edge == Edge.left
                  ? inside - width + inset
                  : w - inside - inset;
              top = h - height - h * piece.lift + h * 0.015;
          }
          children.add(
            Positioned(
              left: left,
              top: top,
              width: width,
              height: height,
              child: TiltShift(
                depth: piece.depth,
                child: CardboardPiece(
                  asset: 'assets/stage/scenery/${piece.name}.webp',
                  mirror: mirror,
                  tint: tint,
                ),
              ),
            ),
          );
        }
        return Stack(clipBehavior: Clip.none, children: children);
      },
    );
  }
}

/// A piece of scenery as cardboard: the print, its board edge showing a
/// little to the lower right (the light comes from the upper left) and a
/// soft shadow on the set behind it.
class CardboardPiece extends StatelessWidget {
  const CardboardPiece({
    required this.asset,
    super.key,
    this.mirror = false,
    this.tint,
  });

  final String asset;
  final bool mirror;
  final Color? tint;

  static const _kraft = ColorFilter.matrix([
    0, 0, 0, 0, 0x6E, //
    0, 0, 0, 0, 0x4E, //
    0, 0, 0, 0, 0x2E, //
    0, 0, 0, 1, 0,
  ]);

  static const _shade = ColorFilter.matrix([
    0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, //
    0, 0, 0, 0.45, 0,
  ]);

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: LayoutBuilder(
      builder: (context, box) {
        final edge = max(2, box.maxHeight * 0.006).toDouble();
        Widget print = Image.asset(
          asset,
          fit: BoxFit.fill,
          gaplessPlayback: true,
        );
        if (tint != null) {
          print = ColorFiltered(
            colorFilter: ColorFilter.mode(tint!, BlendMode.modulate),
            child: print,
          );
        }
        if (mirror) {
          print = Transform.flip(flipX: true, child: print);
        }
        return Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            // The shadow on the set.
            Transform.translate(
              offset: Offset(edge * 3, edge * 4),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: edge * 2,
                  sigmaY: edge * 2,
                ),
                child: ColorFiltered(colorFilter: _shade, child: print),
              ),
            ),
            // The board's cut edge.
            Transform.translate(
              offset: Offset(edge, edge * 0.8),
              child: ColorFiltered(colorFilter: _kraft, child: print),
            ),
            print,
          ],
        );
      },
    ),
  );
}
