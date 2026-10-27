import 'dart:math';

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/src/stage/moon.dart';
import 'package:whowolf/src/theme.dart';

/// The stage set behind a screen (task 012): every moment of the evening
/// has its own scene. Chosen only from public values, so every phone shows
/// the same set (at night above all).
enum Scene {
  /// The village at dusk with a crescent: start, joining, the lobby.
  village,

  /// The theatre with red curtains and a full moon: your role.
  theatre,

  /// The lake under the full moon: the night.
  nightLake,

  /// The bright morning over the village: the news.
  morning,

  /// The village square at dusk: the day and the vote.
  dusk,

  /// The forest edge at twilight: the hunter.
  hunt,

  /// The finale; [Scene.finaleWolves] under a blood moon.
  finale,
  finaleWolves,
  finaleLovers,

  /// Backstage: settings, help, privacy.
  backstage,

  /// The closed curtain: waiting, reconnecting.
  curtain,
}

/// The scene a phase plays in.
Scene sceneFor(PlayerView? view) => switch (view?.phase) {
  null || Phase.lobby => Scene.village,
  Phase.roleReveal => Scene.theatre,
  Phase.night => Scene.nightLake,
  Phase.day => Scene.morning,
  Phase.vote => Scene.dusk,
  Phase.hunterShot => Scene.hunt,
  Phase.ended => switch (view!.winner) {
    Faction.werewolves => Scene.finaleWolves,
    Faction.lovers => Scene.finaleLovers,
    Faction.village || null => Scene.finale,
  },
};

/// The colours and the light of a scene.
typedef SceneLook = ({
  List<Color> sky,
  MoonPhase? moon,
  Alignment moonAt,
  double stars,
  Color horizon,
  Color wings,
});

SceneLook lookOf(Scene scene) => switch (scene) {
  Scene.village => (
    sky: const [Color(0xFF0B1732), Color(0xFF1B3157), Color(0xFF3B4B6E)],
    moon: MoonPhase.crescent,
    moonAt: const Alignment(0.78, -0.5),
    stars: 0.8,
    horizon: const Color(0xFF0E1A2C),
    wings: const Color(0xFF07101C),
  ),
  Scene.theatre => (
    sky: const [Color(0xFF070F1E), Color(0xFF13243F), Color(0xFF243552)],
    moon: MoonPhase.full,
    moonAt: const Alignment(0, -0.2),
    stars: 0.6,
    horizon: const Color(0xFF0B1424),
    wings: const Color(0xFF4A1210),
  ),
  // The night's moon is the screen's own, with its ring (task 012).
  Scene.nightLake => (
    sky: const [Color(0xFF040A14), Color(0xFF0A1628), Color(0xFF13233A)],
    moon: null,
    moonAt: const Alignment(0, -0.05),
    stars: 1,
    horizon: const Color(0xFF060D18),
    wings: const Color(0xFF03070E),
  ),
  Scene.morning => (
    sky: const [Color(0xFF5E86B5), Color(0xFFB8C7D6), Color(0xFFF2D8B0)],
    moon: MoonPhase.sun,
    moonAt: const Alignment(-0.4, -0.7),
    stars: 0,
    horizon: const Color(0xFF3F5468),
    wings: const Color(0xFF223040),
  ),
  Scene.dusk => (
    sky: const [Color(0xFF102A52), Color(0xFF2B4772), Color(0xFFA28070)],
    moon: MoonPhase.half,
    moonAt: const Alignment(0.55, -0.82),
    stars: 0.35,
    horizon: const Color(0xFF14233C),
    wings: const Color(0xFF0A1424),
  ),
  Scene.hunt => (
    sky: const [Color(0xFF0A1424), Color(0xFF1C2C44), Color(0xFF4A4A5A)],
    moon: MoonPhase.full,
    moonAt: const Alignment(0.5, -0.7),
    stars: 0.4,
    horizon: const Color(0xFF0C1622),
    wings: const Color(0xFF060C14),
  ),
  Scene.finale => (
    sky: const [Color(0xFF2B4772), Color(0xFF9A7A78), Color(0xFFF2C890)],
    moon: MoonPhase.sun,
    moonAt: const Alignment(0, -0.6),
    stars: 0,
    horizon: const Color(0xFF2A3446),
    wings: const Color(0xFF151C2A),
  ),
  Scene.finaleWolves => (
    sky: const [Color(0xFF12070A), Color(0xFF2A0F14), Color(0xFF4A1A1E)],
    moon: MoonPhase.blood,
    moonAt: const Alignment(0, -0.55),
    stars: 0.3,
    horizon: const Color(0xFF14080A),
    wings: const Color(0xFF080305),
  ),
  Scene.finaleLovers => (
    sky: const [Color(0xFF1A1636), Color(0xFF4A2E5A), Color(0xFFB0707A)],
    moon: MoonPhase.full,
    moonAt: const Alignment(0, -0.6),
    stars: 0.6,
    horizon: const Color(0xFF221A30),
    wings: const Color(0xFF120E1E),
  ),
  Scene.backstage => (
    sky: const [Color(0xFF1A120E), Color(0xFF2A1C14), Color(0xFF3A281C)],
    moon: null,
    moonAt: Alignment.center,
    stars: 0,
    horizon: const Color(0xFF1A120E),
    wings: const Color(0xFF0E0906),
  ),
  Scene.curtain => (
    sky: const [Color(0xFF3A0C0E), Color(0xFF5E1416), Color(0xFF3A0C0E)],
    moon: null,
    moonAt: Alignment.center,
    stars: 0,
    horizon: const Color(0xFF2A0809),
    wings: const Color(0xFF1A0506),
  ),
};

/// Paints a scene's sky, stars, moon, a far horizon and the dark wings at
/// the sides. The picture layers from the stage set (task 012, phase 2)
/// sit on top of it.
class ScenePainter extends CustomPainter {
  const ScenePainter(this.scene);

  final Scene scene;

  @override
  void paint(Canvas canvas, Size size) {
    final look = lookOf(scene);
    final area = Offset.zero & size;
    canvas.drawRect(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: look.sky,
        ).createShader(area),
    );
    if (look.stars > 0) _stars(canvas, size, look.stars);
    final moon = look.moon;
    if (moon != null) {
      final d = size.shortestSide * (moon == MoonPhase.crescent ? 0.3 : 0.46);
      final center = look.moonAt.withinRect(area);
      MoonPainter(phase: moon).paint(
        canvas
          ..save()
          ..translate(center.dx - d / 2, center.dy - d / 2),
        Size.square(d),
      );
      canvas.restore();
    }
    if (scene == Scene.curtain || scene == Scene.theatre) {
      _curtains(canvas, size);
    }
    _horizon(canvas, size, look.horizon);
    _vignette(canvas, size, look.wings);
  }

  void _stars(Canvas canvas, Size size, double amount) {
    final random = Random(scene.index + 3);
    final paint = Paint();
    final count = (size.width * size.height / 2600 * amount).round();
    for (var i = 0; i < count; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * 0.6;
      final r =
          0.4 + random.nextDouble() * (random.nextInt(12) == 0 ? 1.6 : 0.8);
      paint.color = Palette.stageMoonlight.withValues(
        alpha: 0.25 + random.nextDouble() * 0.6,
      );
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  /// A far line of hills and roofs, the village asleep on the horizon.
  void _horizon(Canvas canvas, Size size, Color color) {
    final random = Random(scene.index * 7 + 1);
    final base = size.height * 0.62;
    final path = Path()..moveTo(0, size.height);
    var x = 0.0;
    path.lineTo(0, base);
    while (x < size.width) {
      final w = 18 + random.nextDouble() * 34;
      final roof = random.nextInt(3) == 0;
      final h = roof ? 20 + random.nextDouble() * 30 : random.nextDouble() * 10;
      if (roof) {
        path
          ..lineTo(x, base - h * 0.6)
          ..lineTo(x + w / 2, base - h)
          ..lineTo(x + w, base - h * 0.6);
      } else {
        path.quadraticBezierTo(x + w / 2, base - h, x + w, base);
      }
      x += w;
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  /// Red stage curtains at both sides with soft folds.
  void _curtains(Canvas canvas, Size size) {
    final width = size.width * (scene == Scene.curtain ? 0.52 : 0.16);
    for (final left in [true, false]) {
      final rect = left
          ? Rect.fromLTWH(0, 0, width, size.height)
          : Rect.fromLTWH(size.width - width, 0, width, size.height);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            colors: [
              Color(0xFF5E1416),
              Color(0xFF9E2A24),
              Color(0xFF6E181A),
            ],
            tileMode: TileMode.repeated,
            end: Alignment(-0.6, 0),
          ).createShader(rect),
      );
    }
    if (scene == Scene.curtain) {
      // The thin gap of light where the curtains meet.
      final gap = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: 6,
        height: size.height,
      );
      canvas
        ..drawRect(
          gap.inflate(10),
          Paint()
            ..color = Palette.stageLanternTop.withValues(alpha: 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
        )
        ..drawRect(
          gap,
          Paint()..color = Palette.stageMoonlight.withValues(alpha: 0.85),
        );
    }
  }

  /// Dark wings at the sides and the bottom: the frame of the stage.
  void _vignette(Canvas canvas, Size size, Color wings) {
    final area = Offset.zero & size;
    canvas
      ..drawRect(
        area,
        Paint()
          ..shader = RadialGradient(
            radius: 0.95,
            colors: [wings.withValues(alpha: 0), wings.withValues(alpha: 0.85)],
            stops: const [0.55, 1],
          ).createShader(area),
      )
      ..drawRect(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [wings.withValues(alpha: 0), wings.withValues(alpha: 0.9)],
            stops: const [0.6, 1],
          ).createShader(area),
      );
  }

  @override
  bool shouldRepaint(ScenePainter old) => old.scene != scene;
}

/// Which scene the screens below play in.
class SceneScope extends InheritedWidget {
  const SceneScope({required this.scene, required super.child, super.key});

  final Scene scene;

  static Scene of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SceneScope>()?.scene ??
      Scene.village;

  @override
  bool updateShouldNotify(SceneScope old) => old.scene != scene;
}

/// The painted stage set of a scene (task 012), where one exists; the
/// others are painted by [ScenePainter] alone.
String? plateOf(Scene scene) => switch (scene) {
  Scene.village => 'assets/stage/village.webp',
  Scene.theatre => 'assets/stage/theatre.webp',
  Scene.nightLake => 'assets/stage/nightlake.webp',
  Scene.morning => 'assets/stage/morning.webp',
  _ => null,
};

/// Paints what goes over a plate: the moon in its sky and the dark at the
/// top and the foot that keeps titles and buttons readable.
class _PlateLight extends CustomPainter {
  const _PlateLight(this.scene);

  final Scene scene;

  @override
  void paint(Canvas canvas, Size size) {
    final look = lookOf(scene);
    final area = Offset.zero & size;
    final moon = look.moon;
    if (moon != null) {
      final d = size.shortestSide * (moon == MoonPhase.crescent ? 0.3 : 0.4);
      final center = look.moonAt.withinRect(area);
      canvas
        ..save()
        ..translate(center.dx - d / 2, center.dy - d / 2);
      MoonPainter(phase: moon).paint(canvas, Size.square(d));
      canvas.restore();
    }
    canvas.drawRect(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            look.wings.withValues(alpha: 0.7),
            look.wings.withValues(alpha: 0),
            look.wings.withValues(alpha: 0),
            look.wings.withValues(alpha: 0.85),
          ],
          stops: const [0, 0.22, 0.62, 1],
        ).createShader(area),
    );
  }

  @override
  bool shouldRepaint(_PlateLight old) => old.scene != scene;
}

/// The scene, filling its area, crossfading when it changes.
class StageSet extends StatelessWidget {
  const StageSet({required this.scene, super.key});

  final Scene scene;

  @override
  Widget build(BuildContext context) {
    final plate = plateOf(scene);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: RepaintBoundary(
        key: ValueKey(scene),
        child: plate == null
            ? CustomPaint(painter: ScenePainter(scene), size: Size.infinite)
            : Stack(
                fit: StackFit.expand,
                children: [
                  // Behind the plate, in case it is not decoded yet.
                  CustomPaint(painter: ScenePainter(scene)),
                  Image.asset(
                    plate,
                    fit: BoxFit.cover,
                    // The ground the puppets stand on stays in view.
                    alignment: const Alignment(0, 0.6),
                    gaplessPlayback: true,
                  ),
                  CustomPaint(painter: _PlateLight(scene)),
                ],
              ),
      ),
    );
  }
}
