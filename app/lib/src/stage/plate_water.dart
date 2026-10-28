import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:whowolf/src/stage/living.dart';
import 'package:whowolf/src/stage/pan.dart';
import 'package:whowolf/src/stage/stage_clock.dart';

/// Where the water lies in a stage set, as fractions of its picture.
Rect? waterOf(String plate) => switch (plate) {
  'village' => const Rect.fromLTRB(0.2, 0.622, 0.97, 0.705),
  'nightlake' => const Rect.fromLTRB(0, 0.598, 1, 0.75),
  _ => null,
};

/// Waves on a stage set's painted water (task 015), on the plate's own
/// frame: a shader shifts the set's pixels row by row (shaders/water.frag).
class PlateWater extends StatefulWidget {
  const PlateWater({required this.plate, required this.asset, super.key});

  /// The set's name (`village`) and its picture.
  final String plate;
  final String asset;

  @override
  State<PlateWater> createState() => _PlateWaterState();
}

class _PlateWaterState extends State<PlateWater> {
  static Future<ui.FragmentProgram>? _program;
  static final Map<String, Future<ui.Image>> _images = {};

  ui.FragmentShader? _shader;
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final program = await (_program ??= ui.FragmentProgram.fromAsset(
        'shaders/water.frag',
      ));
      final image = await (_images[widget.asset] ??= _decode(widget.asset));
      if (!mounted) return;
      setState(() {
        _shader = program.fragmentShader();
        _image = image;
      });
    } on Object catch (error) {
      // No shader on this device: the water stays as painted.
      debugPrint('Water shader unavailable: $error');
    }
  }

  static Future<ui.Image> _decode(String asset) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    return (await codec.getNextFrame()).image;
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shader = _shader;
    final image = _image;
    final water = waterOf(widget.plate);
    if (shader == null || image == null || water == null) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: CustomPaint(
        painter: _WaterPainter(
          shader: shader,
          image: image,
          water: water,
          time: StageClock.of(context),
          pan: StagePan.of(context),
        ),
      ),
    );
  }
}

class _WaterPainter extends CustomPainter {
  _WaterPainter({
    required this.shader,
    required this.image,
    required this.water,
    required this.time,
    this.pan,
  }) : super(repaint: Listenable.merge([time, ?pan]));

  final ui.FragmentShader shader;
  final ui.Image image;
  final Rect water;
  final ValueListenable<double> time;
  final ValueListenable<double>? pan;

  @override
  void paint(Canvas canvas, Size size) {
    final r = plateRect(size, pan?.value ?? 0, side: image.width.toDouble());
    shader
      ..setFloat(0, r.left)
      ..setFloat(1, r.top)
      ..setFloat(2, r.width)
      ..setFloat(3, r.height)
      ..setFloat(4, water.left)
      ..setFloat(5, water.top)
      ..setFloat(6, water.right)
      ..setFloat(7, water.bottom)
      ..setFloat(8, time.value)
      ..setImageSampler(0, image);
    canvas.drawRect(
      Rect.fromLTRB(
        r.left + water.left * r.width,
        r.top + water.top * r.height,
        r.left + water.right * r.width,
        r.top + water.bottom * r.height,
      ),
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(_WaterPainter old) =>
      old.shader != shader || old.image != image || old.water != water;
}
