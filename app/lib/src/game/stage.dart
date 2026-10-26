import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:whowolf/src/theme.dart';

/// The stock everything is printed on: a small tile of noise, made once and
/// repeated. The website lays the same grain over its pages.
abstract final class Grain {
  static const _size = 128;
  static ui.Image? _image;
  static ui.Image? _soft;
  static Future<void>? _loading;

  /// The tile, or `null` until it is ready (the first frame goes without).
  static ui.Image? get image => _image;

  /// A light variant (values near white) to multiply into a surface.
  static ui.Image? get softImage => _soft;

  /// Makes the tiles; cheap, deterministic, called once at start.
  static Future<void> load() => _loading ??= () async {
    _image = await _make(0, 256);
    _soft = await _make(200, 56);
  }();

  static Future<ui.Image> _make(int base, int spread) {
    final random = Random(7);
    final pixels = Uint8List(_size * _size * 4);
    for (var i = 0; i < pixels.length; i += 4) {
      final v = base + random.nextInt(spread);
      pixels
        ..[i] = v
        ..[i + 1] = v
        ..[i + 2] = v
        ..[i + 3] = 255;
    }
    final done = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      _size,
      _size,
      ui.PixelFormat.rgba8888,
      done.complete,
    );
    return done.future;
  }
}

/// Paints the grain tile over its area, blended into what lies below.
class GrainPainter extends CustomPainter {
  GrainPainter({this.opacity = 0.07, this.blend = BlendMode.overlay})
    : image = Grain.image;

  final double opacity;
  final BlendMode blend;

  /// Captured when built, so the painter repaints once the tile is ready.
  final ui.Image? image;

  @override
  void paint(Canvas canvas, Size size) {
    final image = this.image;
    if (image == null) return;
    final area = Offset.zero & size;
    // Drawn into a layer that is then blended down at [opacity]: a shader
    // paint itself ignores its colour's alpha.
    canvas
      ..saveLayer(
        area,
        Paint()
          ..color = Color.fromRGBO(0, 0, 0, opacity)
          ..blendMode = blend,
      )
      ..drawRect(
        area,
        Paint()
          ..shader = ImageShader(
            image,
            TileMode.repeated,
            TileMode.repeated,
            Matrix4.identity().storage,
            filterQuality: FilterQuality.none,
          ),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(GrainPainter old) =>
      old.image != image || old.opacity != opacity || old.blend != blend;
}

/// The stage every screen plays on: night cardstock with moonlight from
/// above, a little grain, and the curtain's valance along the top edge.
class StageBackground extends StatefulWidget {
  const StageBackground({required this.child, super.key});

  final Widget child;

  @override
  State<StageBackground> createState() => _StageBackgroundState();
}

class _StageBackgroundState extends State<StageBackground> {
  @override
  void initState() {
    super.initState();
    if (Grain.image == null) {
      unawaited(
        Grain.load().then((_) {
          if (mounted) setState(() {});
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    // Opaque cardstock first: a gradient alone would replace the colour.
    return ColoredBox(
      color: Palette.night900,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -1.1),
            radius: 1.1,
            colors: [Color(0x593A4677), Color(0x003A4677)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // The board's grain lies under the content, never over text.
            IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(painter: GrainPainter()),
              ),
            ),
            widget.child,
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: top + Valance.drop,
              child: const IgnorePointer(child: Valance()),
            ),
          ],
        ),
      ),
    );
  }
}

/// The scalloped curtain at the top of the stage. It fills the status bar
/// area and hangs [drop] pixels into the screen.
class Valance extends StatelessWidget {
  const Valance({super.key});

  /// How far the scallops hang below the safe area.
  static const double drop = 10;

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(painter: _ValancePainter(), size: Size.infinite);
}

class _ValancePainter extends CustomPainter {
  const _ValancePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const scallop = 34.0;
    final hem = size.height - Valance.drop;
    final count = (size.width / scallop).ceil();
    final width = size.width / count;
    final cloth = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, hem);
    for (var i = count; i > 0; i--) {
      final right = i * width;
      final left = right - width;
      cloth.quadraticBezierTo(
        (left + right) / 2,
        hem + Valance.drop * 1.6,
        left,
        hem,
      );
    }
    cloth.close();
    canvas
      ..drawShadow(cloth, Colors.black, 4, false)
      ..drawPath(
        cloth,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Palette.curtain700, Palette.curtain600],
          ).createShader(Offset.zero & size),
      );
    // Folds: a darker crease in the middle of every scallop.
    final crease = Paint()
      ..color = Palette.curtain700.withValues(alpha: 0.7)
      ..strokeWidth = 1.5;
    for (var i = 0; i < count; i++) {
      final x = i * width + width / 2;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, hem + Valance.drop * 0.6),
        crease,
      );
    }
    // The gold braid along the hem.
    final braid = Path();
    for (var i = 0; i < count; i++) {
      final left = i * width;
      braid
        ..moveTo(left, hem - 2)
        ..quadraticBezierTo(
          left + width / 2,
          hem + Valance.drop * 1.6 - 3,
          left + width,
          hem - 2,
        );
    }
    canvas.drawPath(
      braid,
      Paint()
        ..color = Palette.gold500
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_ValancePainter old) => false;
}

/// A screen on the stage: a [Scaffold] over the [StageBackground]. Pages
/// stay opaque, so route transitions never show two screens at once.
class StageScaffold extends StatelessWidget {
  const StageScaffold({
    required this.body,
    this.appBar,
    this.floatingAppBar = false,
    super.key,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;

  /// The body reaches up behind the app bar (its height arrives as top
  /// padding), so content can scroll underneath instead of being cut off.
  final bool floatingAppBar;

  @override
  Widget build(BuildContext context) => StageBackground(
    child: Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: floatingAppBar,
      appBar: appBar,
      body: body,
    ),
  );
}

/// A body with a [header] floating above it (the narrator's line). The
/// header's height is added to the top padding the body sees, so a
/// stage scroll starts below it and scrolls beneath it.
class FloatingHeader extends StatefulWidget {
  const FloatingHeader({required this.child, this.header, super.key});

  final Widget? header;
  final Widget child;

  @override
  State<FloatingHeader> createState() => _FloatingHeaderState();
}

class _FloatingHeaderState extends State<FloatingHeader> {
  double _height = 0;

  void _measured(Size size) {
    if (size.height != _height && mounted) {
      setState(() => _height = size.height);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final header = widget.header;
    final extra = header == null ? 0.0 : _height;
    return Stack(
      children: [
        Positioned.fill(
          child: MediaQuery(
            data: media.copyWith(
              padding: media.padding.copyWith(top: media.padding.top + extra),
            ),
            child: widget.child,
          ),
        ),
        if (header != null)
          Positioned(
            top: media.padding.top,
            left: media.padding.left,
            right: media.padding.right,
            child: _SizeReporter(onSize: _measured, child: header),
          ),
      ],
    );
  }
}

/// Tells its parent its size after every layout that changes it.
class _SizeReporter extends SingleChildRenderObjectWidget {
  const _SizeReporter({required this.onSize, super.child});

  final ValueChanged<Size> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReporter(onSize);

  @override
  void updateRenderObject(BuildContext context, _RenderSizeReporter render) {
    render.onSize = onSize;
  }
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onSize);

  ValueChanged<Size> onSize;
  Size? _last;

  @override
  void performLayout() {
    super.performLayout();
    if (size != _last) {
      _last = size;
      final reported = size;
      WidgetsBinding.instance.addPostFrameCallback((_) => onSize(reported));
    }
  }
}
