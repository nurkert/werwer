import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:whowolf/src/theme.dart';

/// The cardboard the interface is cut from: the kraft surface, the same
/// board painted midnight blue, and the corrugated cut edge. Loaded once;
/// until they are there, plain colours stand in.
abstract final class Board {
  static ui.Image? _kraft;
  static ui.Image? _night;
  static ui.Image? _flutes;
  static Future<void>? _loading;

  /// Whether the textures are ready.
  static bool get ready => _kraft != null;

  /// Loads the textures (cheap; called when the stage first appears).
  static Future<void> load() => _loading ??= () async {
    Future<ui.Image?> image(String name) async {
      try {
        final data = await rootBundle.load('assets/ui/$name.webp');
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        return (await codec.getNextFrame()).image;
      } on Object {
        return null;
      }
    }

    _night = await image('night_card');
    _flutes = await image('flutes');
    _kraft = await image('kraft');
  }();

  static final _shaders = <(ui.Image, double), Shader>{};

  /// The texture, repeated at half its pixel size (crisp on dense screens).
  static Shader? _surface(ui.Image? image, {double scale = 0.5}) {
    if (image == null) return null;
    return _shaders[(image, scale)] ??= ImageShader(
      image,
      TileMode.repeated,
      TileMode.repeated,
      (Matrix4.identity()..scaleByDouble(scale, scale, 1, 1)).storage,
      filterQuality: FilterQuality.medium,
    );
  }
}

/// What a board's face shows.
enum BoardFace {
  /// The board painted midnight blue: cards on the night stage.
  night,

  /// Bare kraft: around a glued-on playbill, and quiet buttons.
  kraft,

  /// Painted in a colour (the lantern-orange main button).
  paint,
}

/// Paints a piece of cardboard behind its child: the face, the corrugated
/// cut edge [thickness] pixels deep below it and its shadow on the stage.
/// [press] (0 to 1) pushes the face down into the edge, like a finger on a
/// button. The child sits on the face; reserve [thickness] below it.
class BoardPainter extends CustomPainter {
  BoardPainter({
    required this.radius,
    this.face = BoardFace.night,
    this.color,
    this.thickness = 6,
    this.press = 0,
    this.rim,
    this.rimWidth = 2.5,
    this.paperInset,
  }) : _ready = Board.ready;

  final double radius;
  final BoardFace face;

  /// The paint for [BoardFace.paint], or a plain stand-in.
  final Color? color;
  final double thickness;
  final double press;

  /// A coloured line along the cut (e.g. lantern orange when chosen).
  final Color? rim;
  final double rimWidth;

  /// A cream playbill glued onto the board, this far inside its edge.
  final double? paperInset;

  /// Repaint once the textures arrive.
  final bool _ready;

  @override
  void paint(Canvas canvas, Size size) {
    final sink = thickness * press;
    final r = Radius.circular(radius);
    final whole = RRect.fromRectAndRadius(Offset.zero & size, r);
    final faceRect = Rect.fromLTWH(
      0,
      sink,
      size.width,
      size.height - thickness,
    );
    final faceShape = RRect.fromRectAndRadius(faceRect, r);

    // The shadow on the stage, then the board's edge seen from the front.
    canvas.drawRRect(
      whole.shift(const Offset(0, 4)),
      Paint()
        ..color = const Color(0x59000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 - 3 * press),
    );
    final flutes = Board._flutes;
    final edge = Paint();
    if (flutes == null) {
      edge.color = const Color(0xFF7A5634);
    } else {
      // The cut's cross-section fills exactly the board's depth.
      final scale = thickness / flutes.height;
      edge.shader = ImageShader(
        flutes,
        TileMode.repeated,
        TileMode.clamp,
        (Matrix4.identity()
              ..translateByDouble(0, size.height - thickness, 0, 1)
              ..scaleByDouble(scale, scale, 1, 1))
            .storage,
        filterQuality: FilterQuality.medium,
      );
    }
    canvas.drawRRect(whole, edge);

    // The face.
    final surface = Paint();
    switch (face) {
      case BoardFace.night:
        surface
          ..color = Palette.night800
          ..shader = Board._surface(Board._night);
        canvas.drawRRect(faceShape, surface);
      case BoardFace.kraft:
        surface
          ..color = const Color(0xFFC59A68)
          ..shader = Board._surface(Board._kraft);
        canvas.drawRRect(faceShape, surface);
      case BoardFace.paint:
        canvas.drawRRect(
          faceShape,
          Paint()..color = color ?? Palette.lantern400,
        );
        // The board's fibres show through the paint.
        final kraft = Board._surface(Board._kraft);
        if (kraft != null) {
          canvas
            ..saveLayer(
              faceRect,
              Paint()
                ..color = const Color(0x4D000000)
                ..blendMode = BlendMode.overlay,
            )
            ..drawRRect(faceShape, Paint()..shader = kraft)
            ..restore();
        }
    }

    final inset = paperInset;
    if (inset != null) {
      final paper = RRect.fromRectAndRadius(
        faceRect.deflate(inset),
        Radius.circular((radius - inset).clamp(2, radius)),
      );
      canvas
        ..drawRRect(paper, Paint()..color = Palette.paper)
        ..drawRRect(
          paper,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = const Color(0x33000000),
        );
    }

    // The cut: a lit upper edge and a dark crease where face meets edge.
    canvas.drawRRect(
      faceShape.deflate(0.75),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = ui.Gradient.linear(
          faceRect.topCenter,
          faceRect.bottomCenter,
          const [Color(0x40FFFFFF), Color(0x00FFFFFF), Color(0x40000000)],
          const [0, 0.5, 1],
        ),
    );
    final rim = this.rim;
    if (rim != null) {
      canvas.drawRRect(
        faceShape.deflate(rimWidth / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rimWidth
          ..color = rim,
      );
    }
  }

  @override
  bool shouldRepaint(BoardPainter old) =>
      old._ready != _ready ||
      old.radius != radius ||
      old.face != face ||
      old.color != color ||
      old.thickness != thickness ||
      old.press != press ||
      old.rim != rim ||
      old.rimWidth != rimWidth ||
      old.paperInset != paperInset;
}
