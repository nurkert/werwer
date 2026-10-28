import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:whowolf/src/stage/lights.g.dart';
import 'package:whowolf/src/stage/scene.dart';
import 'package:whowolf/src/stage/stage_clock.dart';

// ---- Sprites: soft shapes drawn once, then stamped many times. ----------

/// Where each soft shape lies on the sprite sheet.
abstract final class _Sprite {
  static const glow = Rect.fromLTWH(0, 0, 64, 64);
  static const star = Rect.fromLTWH(64, 0, 64, 64);
  static const streak = Rect.fromLTWH(128, 0, 128, 32);
  static const mist = Rect.fromLTWH(0, 64, 256, 64);
}

ui.Image? _sheet;

ui.Image get _sprites => _sheet ??= _drawSheet();

ui.Image _drawSheet() {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  void soft(Rect r, List<double> stops, List<double> alphas) {
    canvas
      ..save()
      ..clipRect(r);
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        r.center,
        r.shortestSide / 2,
        [for (final a in alphas) const Color(0xFFFFFFFF).withValues(alpha: a)],
        stops,
      );
    canvas
      ..translate(r.center.dx, r.center.dy)
      ..scale(r.width / r.shortestSide, r.height / r.shortestSide)
      ..translate(-r.center.dx, -r.center.dy)
      ..drawRect(r, paint)
      ..restore();
  }

  // A light: a bright core fading softly (most of the glow is the fall-off).
  soft(_Sprite.glow, const [0, 0.12, 0.4, 1], const [1, 0.75, 0.22, 0]);
  // A star as the sets paint them: four tapering rays, the upright one
  // longest, fine diagonal glints and a soft core.
  soft(_Sprite.star, const [0, 0.12, 0.35, 1], const [0.9, 0.55, 0.1, 0]);
  final c = _Sprite.star.center;
  final ray = Paint()
    ..shader = ui.Gradient.radial(
      c,
      30,
      const [
        Color(0xFFFFFFFF),
        Color(0x99FFFFFF),
        Color(0x00FFFFFF),
      ],
      const [0, 0.35, 1],
    );
  Path diamond(double dx, double dy, double width) {
    final n = Offset(-dy, dx) / sqrt(dx * dx + dy * dy) * width;
    return Path()
      ..moveTo(c.dx + dx, c.dy + dy)
      ..lineTo(c.dx + n.dx, c.dy + n.dy)
      ..lineTo(c.dx - dx, c.dy - dy)
      ..lineTo(c.dx - n.dx, c.dy - n.dy)
      ..close();
  }

  canvas
    ..drawPath(diamond(0, 31, 3.2), ray)
    ..drawPath(diamond(23, 0, 2.8), ray)
    ..drawPath(diamond(8, 8, 1.1), ray)
    ..drawPath(diamond(8, -8, 1.1), ray);
  // A glint on water: a flat ellipse.
  soft(_Sprite.streak, const [0, 0.35, 1], const [0.9, 0.35, 0]);
  // Mist: a very soft, wide cloud.
  soft(_Sprite.mist, const [0, 0.5, 1], const [0.9, 0.4, 0]);
  return recorder.endRecording().toImageSync(256, 128);
}

// ---- What lives in each scene. ------------------------------------------

/// Small things floating in a region of the set.
typedef _Drift = ({
  int count,
  Rect area,
  Color color,
  double size,
  // Speed across and up, in set widths per second (wraps in the area).
  double vx,
  double vy,
  double sway,
});

/// The life of a scene, all positions as fractions of its stage set.
typedef SceneLife = ({
  String? plate,
  // Lights that flicker like a flame rather than breathe like a window.
  bool flames,
  // Extra faint stars where the sky is clear, and shooting stars.
  Rect? sky,
  bool shooting,
  int fireflies,
  Rect fireflyArea,
  List<Rect> mist,
  Color mistColor,
  _Drift? drift,
  // Moths circling the brightest lights.
  int moths,
  // Mirror bulbs that now and then flicker (backstage).
  bool bulbs,
  // The water's surface: moonlight glints travel on its waves.
  Rect? water,
  Color tint,
});

const _warm = Color(0xFFFFB45A);
const _noDrift = null;

SceneLife lifeOf(Scene scene) => switch (scene) {
  Scene.village => (
    plate: 'village',
    flames: false,
    sky: const Rect.fromLTRB(0.04, 0.02, 0.96, 0.3),
    shooting: true,
    fireflies: 14,
    fireflyArea: const Rect.fromLTRB(0.02, 0.6, 0.98, 0.76),
    mist: const [],
    mistColor: const Color(0xFF9FB4D8),
    drift: _noDrift,
    moths: 0,
    bulbs: false,
    water: const Rect.fromLTRB(0.2, 0.625, 0.96, 0.7),
    tint: _warm,
  ),
  Scene.theatre => (
    plate: 'theatre',
    flames: true,
    sky: const Rect.fromLTRB(0.1, 0.06, 0.9, 0.36),
    shooting: false,
    fireflies: 0,
    fireflyArea: Rect.zero,
    mist: const [],
    mistColor: const Color(0xFF9FB4D8),
    drift: (
      count: 26,
      area: const Rect.fromLTRB(0.08, 0.5, 0.92, 0.84),
      color: const Color(0xFFFFE2A8),
      size: 3,
      vx: 0.002,
      vy: -0.006,
      sway: 0.02,
    ),
    moths: 0,
    bulbs: false,
    water: null,
    tint: _warm,
  ),
  Scene.nightLake => (
    plate: 'nightlake',
    flames: true,
    sky: const Rect.fromLTRB(0.02, 0.02, 0.98, 0.3),
    shooting: true,
    fireflies: 16,
    fireflyArea: const Rect.fromLTRB(0.02, 0.62, 0.98, 0.82),
    mist: const [Rect.fromLTRB(0, 0.56, 1, 0.66)],
    mistColor: const Color(0xFF9FB4D8),
    drift: _noDrift,
    moths: 0,
    bulbs: false,
    water: const Rect.fromLTRB(0, 0.6, 1, 0.74),
    tint: _warm,
  ),
  Scene.morning => (
    plate: 'morning',
    flames: false,
    sky: null,
    shooting: false,
    fireflies: 0,
    fireflyArea: Rect.zero,
    mist: const [Rect.fromLTRB(0, 0.5, 1, 0.62), Rect.fromLTRB(0, 0.6, 1, 0.7)],
    mistColor: const Color(0xFFFFFFFF),
    drift: (
      count: 24,
      area: const Rect.fromLTRB(0, 0.2, 1, 0.9),
      color: const Color(0xFFFFF4D2),
      size: 3.4,
      vx: 0.006,
      vy: -0.002,
      sway: 0.03,
    ),
    moths: 0,
    bulbs: false,
    water: null,
    tint: _warm,
  ),
  Scene.dusk => (
    plate: 'dusk',
    flames: false,
    sky: const Rect.fromLTRB(0.05, 0.02, 0.95, 0.14),
    shooting: false,
    fireflies: 6,
    fireflyArea: const Rect.fromLTRB(0.05, 0.7, 0.95, 0.86),
    mist: const [],
    mistColor: const Color(0xFF9FB4D8),
    drift: _noDrift,
    moths: 3,
    bulbs: false,
    water: null,
    tint: _warm,
  ),
  Scene.hunt => (
    plate: 'hunt',
    flames: true,
    sky: null,
    shooting: false,
    fireflies: 22,
    fireflyArea: const Rect.fromLTRB(0.05, 0.55, 0.95, 0.9),
    mist: const [
      Rect.fromLTRB(0, 0.5, 1, 0.62),
      Rect.fromLTRB(0, 0.58, 1, 0.68),
    ],
    mistColor: const Color(0xFFA9B6D2),
    drift: _noDrift,
    moths: 0,
    bulbs: false,
    water: null,
    tint: _warm,
  ),
  Scene.finale => (
    plate: 'finale',
    flames: false,
    sky: null,
    shooting: false,
    fireflies: 10,
    fireflyArea: const Rect.fromLTRB(0.05, 0.58, 0.95, 0.76),
    mist: const [],
    mistColor: const Color(0xFFFFFFFF),
    drift: _noDrift,
    moths: 0,
    bulbs: false,
    water: null,
    tint: _warm,
  ),
  Scene.finaleWolves => (
    plate: 'dusk',
    flames: false,
    sky: null,
    shooting: false,
    fireflies: 0,
    fireflyArea: Rect.zero,
    mist: const [],
    mistColor: const Color(0xFFFFFFFF),
    drift: (
      count: 30,
      area: const Rect.fromLTRB(0, 0.3, 1, 0.95),
      color: const Color(0xFFFF7A34),
      size: 3.2,
      vx: 0.004,
      vy: -0.03,
      sway: 0.02,
    ),
    moths: 0,
    bulbs: false,
    water: null,
    tint: const Color(0xFFFF6A40),
  ),
  Scene.finaleLovers => (
    plate: 'nightlake',
    flames: true,
    sky: const Rect.fromLTRB(0.02, 0.02, 0.98, 0.3),
    shooting: true,
    fireflies: 0,
    fireflyArea: Rect.zero,
    mist: const [Rect.fromLTRB(0, 0.56, 1, 0.66)],
    mistColor: const Color(0xFFFFC8DA),
    drift: (
      count: 26,
      area: const Rect.fromLTRB(0, 0.3, 1, 0.95),
      color: const Color(0xFFFFB2CC),
      size: 3.4,
      vx: 0.008,
      vy: 0.004,
      sway: 0.04,
    ),
    moths: 0,
    bulbs: false,
    water: const Rect.fromLTRB(0, 0.6, 1, 0.74),
    tint: const Color(0xFFFFA0C0),
  ),
  Scene.backstage => (
    plate: 'backstage',
    flames: true,
    sky: null,
    shooting: false,
    fireflies: 0,
    fireflyArea: Rect.zero,
    mist: const [],
    mistColor: const Color(0xFFFFFFFF),
    drift: (
      count: 22,
      area: const Rect.fromLTRB(0.02, 0.15, 0.98, 0.8),
      color: const Color(0xFFFFE2A8),
      size: 2.6,
      vx: 0.002,
      vy: -0.004,
      sway: 0.02,
    ),
    moths: 0,
    bulbs: true,
    water: null,
    tint: _warm,
  ),
  Scene.curtain => (
    plate: 'curtain',
    flames: true,
    sky: null,
    shooting: false,
    fireflies: 0,
    fireflyArea: Rect.zero,
    mist: const [],
    mistColor: const Color(0xFFFFFFFF),
    drift: (
      count: 20,
      area: const Rect.fromLTRB(0.1, 0.1, 0.9, 0.86),
      color: const Color(0xFFFFE2A8),
      size: 2.6,
      vx: 0.001,
      vy: -0.004,
      sway: 0.02,
    ),
    moths: 0,
    bulbs: false,
    water: null,
    tint: _warm,
  ),
};

/// Where a stage set's picture lies in [size]: exactly as the plate is
/// drawn (`BoxFit.cover`, `Alignment(pan, 0.6)`), so every light sits on
/// its painted window.
Rect plateRect(Size size, double pan, {double side = 1254}) {
  final scale = max(size.width / side, size.height / side);
  final w = side * scale;
  final h = side * scale;
  return Rect.fromLTWH(
    (size.width - w) / 2 * (1 + pan.clamp(-1.0, 1.0)),
    (size.height - h) / 2 * (1 + 0.6),
    w,
    h,
  );
}

/// A number from 0 to 1 that stays the same for the same [i] and [salt].
double _hash(int i, int salt) {
  final x = sin(i * 12.9898 + salt * 78.233) * 43758.5453;
  return x - x.floorToDouble();
}

/// Everything that lives on a stage set, drawn in one go (task 015).
class LifePainter extends CustomPainter {
  LifePainter({
    required this.scene,
    required this.time,
    this.pan,
    this.sky = false,
    this.moon,
    this.debug = false,
  }) : super(repaint: Listenable.merge([time, ?pan]));

  /// Where the moon stands on this canvas: no star in front of it.
  final Rect? moon;

  /// The sky's layer (stars, shooting stars), which lies above the dark
  /// that keeps titles readable; otherwise everything else.
  final bool sky;

  final Scene scene;
  final ValueListenable<double> time;
  final ValueListenable<double>? pan;

  /// Marks every found light (for checking the alignment by eye).
  final bool debug;

  /// Marks the lights on every stage (screenshot tests set it).
  static bool showMarks = false;

  final List<RSTransform> _xf = [];
  final List<Rect> _src = [];
  final List<Color> _col = [];

  void _stamp(Rect sprite, Offset at, double width, Color color) {
    final scale = width / sprite.width;
    _xf.add(
      RSTransform.fromComponents(
        rotation: 0,
        scale: scale,
        anchorX: sprite.width / 2,
        anchorY: sprite.height / 2,
        translateX: at.dx,
        translateY: at.dy,
      ),
    );
    _src.add(sprite);
    _col.add(color);
  }

  /// A sparkling star: it breathes at its own pace and now and then
  /// flares, its rays stretching and turning a little.
  void _star(Offset p, int i, double size, double brightness, double t) {
    final breathe = 0.55 + 0.45 * sin(t * (0.4 + 1.1 * _hash(i, 71)) + i * 1.3);
    // A flare: a short bright moment every few seconds, at its own time.
    final period = 5 + 7 * _hash(i, 72);
    final f = ((t + period * _hash(i, 73)) % period) / 0.9;
    final flare = f < 1 ? sin(pi * f) : 0.0;
    final scale = size * (0.85 + 0.15 * breathe + 0.5 * flare);
    _xf.add(
      RSTransform.fromComponents(
        rotation: 0.25 * flare * (_hash(i, 74) < 0.5 ? -1 : 1),
        scale: scale / _Sprite.star.width,
        anchorX: _Sprite.star.width / 2,
        anchorY: _Sprite.star.height / 2,
        translateX: p.dx,
        translateY: p.dy,
      ),
    );
    _src.add(_Sprite.star);
    _col.add(
      _starColour(i).withValues(
        alpha: (brightness * (0.55 + 0.35 * breathe) + 0.4 * flare).clamp(0, 1),
      ),
    );
  }

  /// The stars' colours, from cream to the sets' gold.
  static Color _starColour(int i) => Color.lerp(
    const Color(0xFFFFF1CF),
    const Color(0xFFFFC870),
    _hash(i, 75),
  )!;

  @override
  void paint(Canvas canvas, Size size) {
    final life = lifeOf(scene);
    final name = life.plate;
    if (name == null) return;
    final data = paintedLights[name];
    final t = time.value;
    final r = plateRect(size, pan?.value ?? 0);
    Offset at(double x, double y) =>
        Offset(r.left + x * r.width, r.top + y * r.height);
    final w = r.width;
    _xf.clear();
    _src.clear();
    _col.clear();

    // Mist first, far behind everything else.
    for (final (b, band) in sky ? const <Rect>[].indexed : life.mist.indexed) {
      for (var i = 0; i < 3; i++) {
        final speed = 0.008 + 0.004 * _hash(i, b + 40);
        final x = ((t * speed + i / 3 + _hash(i, b)) % 1.6) - 0.3;
        final y = band.top + band.height * (0.3 + 0.4 * _hash(i, b + 7));
        final a = 0.07 + 0.04 * sin(t * 0.2 + i * 2.1 + b);
        _stamp(
          _Sprite.mist,
          at(x, y),
          w * 0.8,
          life.mistColor.withValues(alpha: a),
        );
      }
    }

    if (data != null && !sky) {
      // Water: the reflections of the lights break into swaying strips.
      for (final (i, l) in data.ripples.indexed) {
        final (x, y, rad, s) = l;
        for (var k = 0; k < 3; k++) {
          final ky = y + (k - 1) * rad * 0.9;
          final dx = sin(t * (1.1 + 0.3 * k) + ky * 140 + i) * rad * 1.1;
          final a = s * (0.22 + 0.2 * sin(t * 2.3 + x * 50 + i * 1.7 + k * 2));
          _stamp(
            _Sprite.streak,
            at(x + dx, ky),
            max(10, rad * w * (7 + 3 * sin(t * 1.7 + k + i))),
            life.tint.withValues(alpha: a.clamp(0, 1)),
          );
        }
      }
      // The painted lights: windows breathe slowly, flames flicker.
      final lights = data.lights;
      final blink = life.bulbs
          ? ((t / 6).floor() * 7) % max(1, lights.length)
          : -1;
      for (final (i, l) in lights.indexed) {
        final (x, y, rad, s) = l;
        final ph = _hash(i, 11) * 6.28;
        final lantern = rad >= 0.02;
        double a;
        if (life.flames || lantern) {
          a =
              0.78 +
              0.1 * sin(t * 7.3 + ph) +
              0.07 * sin(t * 11.1 + ph * 1.7) +
              0.05 * sin(t * 17.3 + ph * 3);
        } else {
          // A window: it breathes slowly and wavers a little, like a
          // candle or a fire inside.
          a =
              0.66 +
              0.18 * sin(t * 0.7 + ph) +
              0.08 * sin(t * 1.9 + ph * 2.1) +
              0.06 * sin(t * 5.1 + ph * 3.3) +
              0.04 * sin(t * 8.3 + ph * 1.3);
        }
        if (i == blink && (t / 6) % 1 < 0.05) a *= 0.15;
        final strength = 0.5 + 0.5 * s;
        final core = max(18, rad * w * 8) * (0.92 + 0.12 * a);
        // A warm core on the window, a halo that sways a little in the
        // night air and a wide, faint bloom that breathes.
        final p = at(x, y);
        final sway = Offset(
          sin(t * 1.3 + ph) * core * 0.07,
          sin(t * 0.9 + ph * 1.7) * core * 0.05,
        );
        _stamp(
          _Sprite.glow,
          p,
          core,
          life.tint.withValues(alpha: (0.85 * a * strength).clamp(0, 1)),
        );
        _stamp(
          _Sprite.glow,
          p + sway,
          core * 1.9,
          life.tint.withValues(alpha: (0.34 * a * strength).clamp(0, 1)),
        );
        _stamp(
          _Sprite.glow,
          p + sway * 2,
          core * (3.3 + 0.4 * sin(t * 0.9 + ph)),
          life.tint.withValues(alpha: (0.24 * a * strength).clamp(0, 1)),
        );
        if (lantern) {
          // A pool of light around a lantern.
          _stamp(
            _Sprite.glow,
            at(x, y),
            rad * w * 16,
            life.tint.withValues(alpha: 0.16 * a),
          );
        }
      }

      // Moths around the brightest lights.
      for (var m = 0; m < life.moths && m < lights.length; m++) {
        final (x, y, rad, _) = lights[m];
        final ang = t * (2.4 + m) + m * 2;
        final rr = 14 + 6 * sin(t * 1.7 + m);
        final p = at(x, y) + Offset(cos(ang) * rr, sin(ang * 1.3) * rr * 0.6);
        _stamp(
          _Sprite.glow,
          p,
          7,
          const Color(0xFFFFF0D0).withValues(alpha: 0.8),
        );
      }
    }

    // Painted stars twinkle, each at its own pace.
    if (data != null && sky) {
      for (final (i, l) in data.stars.indexed) {
        final (x, y, rad, s) = l;
        _star(at(x, y), i, max(13, rad * w * 9), 0.5 + 0.5 * s, t);
      }
    }

    // Moonlight glints come and go on the waves, drifting with them.
    final water = sky ? null : life.water;
    if (water != null) {
      for (var i = 0; i < 46; i++) {
        final depth = pow(_hash(i, 61), 0.8).toDouble();
        final y = water.top + water.height * depth;
        final x =
            water.left +
            water.width * ((_hash(i, 62) + t * (0.004 + 0.006 * depth)) % 1);
        final on = pow(0.5 + 0.5 * sin(t * (0.8 + _hash(i, 63)) + i * 2.3), 6);
        _stamp(
          _Sprite.streak,
          at(x, y),
          6 + 22 * depth,
          const Color(0xFFCFE0FF).withValues(alpha: (0.5 * on).clamp(0, 1)),
        );
      }
    }

    // Stars of our own, placed by the tool on clear sky only (evenly
    // spread, thinning towards the horizon); none over the moon.
    if (sky && data != null) {
      final moon = this.moon;
      for (final (i, l) in data.sky.indexed) {
        final (x, y, m, seed) = l;
        final p = at(x, y);
        if (moon != null && (p - moon.center).distance < moon.width * 0.62) {
          continue;
        }
        final swell = 0.7 + 0.3 * sin(t * 0.3 + x * 6 + y * 4);
        final id = i + (seed * 1000).round();
        if (m > 0.55) {
          _star(p, id, 6 + 13 * m, (0.6 + 0.4 * m) * swell, t);
        } else {
          final tw = 0.5 + 0.5 * sin(t * (0.5 + 1.6 * seed) + i);
          _stamp(
            _Sprite.glow,
            p,
            2.5 + 7 * m + 1.5 * tw,
            _starColour(id).withValues(
              alpha: ((0.3 + 1.2 * m) * (0.55 + 0.45 * tw) * swell).clamp(0, 1),
            ),
          );
        }
      }
    }

    // Fireflies wander and blink.
    for (var i = 0; i < (sky ? 0 : life.fireflies); i++) {
      final a0 = life.fireflyArea;
      final sp = 0.6 + 0.8 * _hash(i, 31);
      final ph = _hash(i, 32) * 6.28;
      final x =
          a0.left +
          a0.width * _hash(i, 33) +
          sin(t * 0.23 * sp + ph) * 0.05 +
          sin(t * 0.61 + ph * 2) * 0.012;
      final y =
          a0.top + a0.height * _hash(i, 34) + cos(t * 0.19 * sp + ph) * 0.03;
      final on = ((sin(t * 0.9 * sp + ph) - 0.15) / 0.85).clamp(0.0, 1.0);
      final glow = pow(on, 1.5).toDouble();
      if (glow < 0.02) continue;
      _stamp(
        _Sprite.glow,
        at(x, y),
        26,
        const Color(0xFFD8F07A).withValues(alpha: 0.35 * glow),
      );
      _stamp(
        _Sprite.glow,
        at(x, y),
        7,
        const Color(0xFFF6FFC8).withValues(alpha: 0.95 * glow),
      );
    }

    // Dust, pollen, embers or petals drifting through the light.
    final drift = sky ? null : life.drift;
    if (drift != null) {
      final area = drift.area;
      for (var i = 0; i < drift.count; i++) {
        final ph = _hash(i, 41) * 6.28;
        final fx = (_hash(i, 42) + t * drift.vx / area.width) % 1;
        final fy = (_hash(i, 43) + t * drift.vy / area.height) % 1;
        final x = area.left + area.width * fx + sin(t * 0.7 + ph) * drift.sway;
        final y = area.top + area.height * fy;
        // Fade in and out at the edges of the area.
        final edge = sin(pi * fy).clamp(0.0, 1.0);
        final tw = 0.55 + 0.45 * sin(t * 1.9 + ph);
        _stamp(
          _Sprite.glow,
          at(x, y),
          drift.size * 3.2,
          drift.color.withValues(alpha: 0.7 * edge * tw),
        );
      }
    }

    if (_xf.isNotEmpty) {
      canvas.drawAtlas(
        _sprites,
        _xf,
        _src,
        _col,
        BlendMode.modulate,
        null,
        Paint()
          ..blendMode = BlendMode.plus
          ..filterQuality = FilterQuality.low,
      );
    }

    if (sky && life.sky != null) _clouds(canvas, r, t, life.sky!);
    if (sky && life.shooting) _shootingStar(canvas, size, r, t);

    if ((debug || showMarks) && data != null && !sky) {
      final mark = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      for (final (x, y, rad, _) in data.lights) {
        canvas.drawCircle(
          at(x, y),
          max(4, rad * w * 1.6),
          mark..color = const Color(0xFFFF00FF),
        );
      }
      for (final (x, y, rad, _) in data.ripples) {
        canvas.drawCircle(
          at(x, y),
          max(4, rad * w * 1.6),
          mark..color = const Color(0xFF00FF00),
        );
      }
      for (final (x, y, rad, _) in data.stars) {
        canvas.drawCircle(
          at(x, y),
          max(3, rad * w * 1.6),
          mark..color = const Color(0xFF00FFFF),
        );
      }
    }
  }

  /// Thin veils of cloud drifting slowly across the sky, now hiding a few
  /// stars, now letting them through; moonlit at their upper edge.
  void _clouds(Canvas canvas, Rect r, double t, Rect sky) {
    final xf = <RSTransform>[];
    final src = <Rect>[];
    final col = <Color>[];
    for (var i = 0; i < 4; i++) {
      final speed = 0.004 + 0.003 * _hash(i, 81);
      final x = ((_hash(i, 82) + t * speed) % 1.5) - 0.25;
      final y = sky.top + sky.height * (0.25 + 0.6 * _hash(i, 83));
      final width = r.width * (0.35 + 0.3 * _hash(i, 84));
      for (final (dy, colour) in [
        (0.0, const Color(0x5A1C2748)),
        (-0.012, const Color(0x1E9FB4D8)),
      ]) {
        xf.add(
          RSTransform.fromComponents(
            rotation: 0,
            scale: width / _Sprite.mist.width,
            anchorX: _Sprite.mist.width / 2,
            anchorY: _Sprite.mist.height / 2,
            translateX: r.left + x * r.width,
            translateY: r.top + (y + dy) * r.height,
          ),
        );
        src.add(_Sprite.mist);
        col.add(colour);
      }
    }
    canvas.drawAtlas(
      _sprites,
      xf,
      src,
      col,
      BlendMode.modulate,
      null,
      Paint(),
    );
  }

  /// Now and then a shooting star crosses the clear sky.
  void _shootingStar(Canvas canvas, Size size, Rect r, double t) {
    const period = 9.0;
    final cycle = (t / period).floor();
    final phase = (t / period - cycle) * period;
    const run = 0.9;
    if (phase > run || _hash(cycle, 51) < 0.35) return;
    final sky = lifeOf(scene).sky ?? const Rect.fromLTRB(0, 0, 1, 0.3);
    final start = Offset(
      r.left + r.width * (sky.left + sky.width * _hash(cycle, 52)),
      r.top + r.height * (sky.top + sky.height * 0.6 * _hash(cycle, 53)),
    );
    final dir = Offset(_hash(cycle, 54) < 0.5 ? -1 : 1, 0.45);
    final p = phase / run;
    final travel = r.width * 0.28;
    final head = start + dir * (travel * p);
    final tail = head - dir * (travel * 0.35);
    final fade = sin(pi * p);
    canvas
      ..drawLine(
        tail,
        head,
        Paint()
          ..shader = ui.Gradient.linear(tail, head, [
            const Color(0x00FFF4D6),
            const Color(0xFFFFF4D6).withValues(alpha: 0.9 * fade),
          ])
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round,
      )
      ..drawCircle(
        head,
        2.2,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: fade),
      );
  }

  @override
  bool shouldRepaint(LifePainter old) =>
      old.scene != scene ||
      old.time != time ||
      old.pan != pan ||
      old.sky != sky;
}

/// The lanterns of a scenery piece, glowing on the same clock.
class PieceLights extends StatelessWidget {
  const PieceLights({
    required this.name,
    this.mirror = false,
    this.tint,
    super.key,
  });

  final String name;
  final bool mirror;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final lights = paintedLights['scenery/$name']?.lights;
    if (lights == null || lights.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        painter: _PiecePainter(
          lights: lights,
          time: StageClock.of(context),
          mirror: mirror,
          tint: tint,
        ),
      ),
    );
  }
}

class _PiecePainter extends CustomPainter {
  _PiecePainter({
    required this.lights,
    required this.time,
    required this.mirror,
    this.tint,
  }) : super(repaint: time);

  final List<PaintedLight> lights;
  final ValueListenable<double> time;
  final bool mirror;
  final Color? tint;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final xf = <RSTransform>[];
    final src = <Rect>[];
    final col = <Color>[];
    final colour = Color.lerp(_warm, tint, tint == null ? 0 : 0.5)!;
    for (final (i, l) in lights.indexed) {
      final (x0, y, rad, s) = l;
      final x = mirror ? 1 - x0 : x0;
      final ph = i * 1.9 + x0 * 10;
      final a =
          0.78 +
          0.1 * sin(t * 7.1 + ph) +
          0.07 * sin(t * 10.7 + ph * 1.7) +
          0.05 * sin(t * 16.9 + ph * 3);
      for (final (k, alpha) in [(2.6, 0.5), (7.0, 0.16)]) {
        final width = rad * size.width * k * 2;
        xf.add(
          RSTransform.fromComponents(
            rotation: 0,
            scale: width / _Sprite.glow.width,
            anchorX: 32,
            anchorY: 32,
            translateX: x * size.width,
            translateY: y * size.height,
          ),
        );
        src.add(_Sprite.glow);
        col.add(colour.withValues(alpha: (alpha * a * s).clamp(0, 1)));
      }
    }
    canvas.drawAtlas(
      _sprites,
      xf,
      src,
      col,
      BlendMode.modulate,
      null,
      Paint()..blendMode = BlendMode.plus,
    );
  }

  @override
  bool shouldRepaint(_PiecePainter old) =>
      old.lights != lights || old.mirror != mirror || old.time != time;
}
