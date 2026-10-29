import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/figures.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/theme.dart';

/// The game in eight steps, as the rules on paper (task 016): every step a
/// little scene of the village's figures doing what it says, so a first
/// timer understands a round from the pictures alone. Each figure has its
/// own place on the stage (nobody covers anybody), thoughts sit in paper
/// bubbles above the heads, and dashed arrows show who does what to whom.
/// On the start screen's left page (it scrolls) and in the how-to sheet.
class HowSteps extends StatelessWidget {
  const HowSteps({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = <(String, String, String, _Scene)>[
      (l10n.howPhaseSetup, l10n.how1Title, l10n.how1Text, _join),
      (l10n.howPhaseSetup, l10n.how2Title, l10n.how2Text, _roles),
      (l10n.howPhaseNight, l10n.how3Title, l10n.how3Text, _wolves),
      (l10n.howPhaseNight, l10n.how4Title, l10n.how4Text, _specials),
      (l10n.howPhaseMorning, l10n.how5Title, l10n.how5Text, _morning),
      (l10n.howPhaseDay, l10n.how6Title, l10n.how6Text, _talk),
      (l10n.howPhaseDay, l10n.how7Title, l10n.how7Text, _vote),
      (l10n.howPhaseEnd, l10n.how8Title, l10n.how8Text, _end),
    ];
    return Panel(
      paper: true,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, (phase, title, text, scene)) in steps.indexed) ...[
            if (i > 0) const _Divider(),
            _Picture(scene: scene),
            const SizedBox(height: 12),
            Row(
              children: [
                _Number(i + 1),
                const SizedBox(width: 10),
                Text(
                  phase.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: displayFont,
                    fontSize: 12.5,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                    color: Palette.curtain600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontFamily: displayFont,
                fontWeight: FontWeight.w700,
                fontSize: 24,
                height: 1.15,
                color: Palette.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16.5,
                height: 1.45,
                color: Palette.inkSoft,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _pose(String name) => 'assets/figures/poses/$name.webp';
const _wolf = 'assets/figures/werwolf.webp';

// The eight scenes. Figures stand left to right, each in its own place;
// links and the victim refer to them by their order.

final _join = _Scene(
  'village',
  const Alignment(0, 0.3),
  [
    _Actor(_pose('dorfbewohner_3'), cue: _Cue.phone),
    _Actor(_pose('tueftler_3'), cue: _Cue.qr),
    _Actor(_pose('gaensehirtin_2'), mirror: true, cue: _Cue.phone),
  ],
  spotlight: 1,
  links: const [_Link(0, 1, _Kind.scan), _Link(2, 1, _Kind.scan)],
);

final _roles = _Scene(
  'theatre',
  const Alignment(0, 0.6),
  [
    _Actor(personaAsset(Persona.maid), cue: _Cue.hidden),
    _Actor(personaAsset(Persona.baker), cue: _Cue.figure, cueAsset: _wolf),
    _Actor(personaAsset(Persona.smith), mirror: true, cue: _Cue.hidden),
  ],
  spotlight: 1,
);

final _wolves = _Scene(
  'nightlake',
  const Alignment(0, 0.2),
  [
    _Actor(personaAsset(Persona.spinner), asleep: true, cue: _Cue.sleep),
    _Actor(personaRoleAsset(Persona.miller, Role.werewolf), cue: _Cue.paw),
    _Actor(
      personaRoleAsset(Persona.innkeeper, Role.werewolf),
      mirror: true,
      cue: _Cue.paw,
    ),
    _Actor(
      personaAsset(Persona.grandfather),
      asleep: true,
      mirror: true,
      cue: _Cue.sleep,
    ),
  ],
  night: true,
  victim: 3,
  links: const [_Link(2, 3, _Kind.choose)],
);

final _specials = _Scene(
  'nightlake',
  const Alignment(0, 0.2),
  [
    _Actor(personaRoleAsset(Persona.fisher, Role.seer), cue: _Cue.eye),
    _Actor(
      personaAsset(Persona.smith),
      asleep: true,
      cue: _Cue.figure,
      cueAsset: figureAsset(Role.villager),
    ),
    _Actor(personaAsset(Persona.grandfather), asleep: true, mirror: true),
    _Actor(
      personaRoleAsset(Persona.grandmother, Role.witch),
      mirror: true,
      cue: _Cue.potion,
    ),
  ],
  night: true,
  victim: 2,
  links: const [_Link(0, 1, _Kind.gaze), _Link(3, 2, _Kind.heal)],
);

final _morning = _Scene(
  'morning',
  const Alignment(0, 0.6),
  [
    _Actor(_pose('grossmutter_3'), cue: _Cue.alarm),
    _Actor(personaAsset(Persona.spinner), ghost: true),
    _Actor(_pose('magd_3'), mirror: true, cue: _Cue.alarm),
  ],
);

final _talk = _Scene(
  'dusk',
  const Alignment(0, 0.6),
  [
    _Actor(_pose('grossvater_1'), cue: _Cue.accuse),
    _Actor(_pose('spielmann_3'), mirror: true, cue: _Cue.innocent),
    _Actor(_pose('wirtin_2'), mirror: true, cue: _Cue.doubt),
  ],
  links: const [_Link(0, 1, _Kind.accuse)],
);

final _vote = _Scene(
  'finale',
  const Alignment(0, 0.6),
  [
    _Actor(_pose('schmied_2'), cue: _Cue.vote),
    _Actor(_pose('schneiderin_1'), cue: _Cue.votes),
    _Actor(_pose('fischerin_3'), mirror: true, cue: _Cue.vote),
    _Actor(_pose('dorfbewohner_1'), mirror: true, cue: _Cue.vote),
  ],
  victim: 1,
  links: const [
    _Link(0, 1, _Kind.vote),
    _Link(2, 1, _Kind.vote),
  ],
);

final _end = _Scene(
  'village',
  const Alignment(0, 0.3),
  [
    _Actor(_pose('spielmann_1'), cue: _Cue.win),
    _Actor(_pose('wirtin_1'), cue: _Cue.win),
    _Actor(_pose('blumenmaedchen_2'), mirror: true, cue: _Cue.win),
    const _Actor(_wolf, ghost: true, mirror: true),
  ],
);

/// What a figure thinks or holds, in a paper bubble above its head.
enum _Cue {
  /// Shows the room's code.
  qr,

  /// Scans it with the phone.
  phone,

  /// A role nobody else may see.
  hidden,

  /// A small figure: the role it holds or has just seen.
  figure,

  /// Eyes closed.
  sleep,

  /// A werewolf choosing.
  paw,

  /// The seer looking.
  eye,

  /// The witch's potions.
  potion,

  /// Shocked at the morning's news.
  alarm,

  /// Points at someone.
  accuse,

  /// Plays innocent.
  innocent,

  /// Not convinced.
  doubt,

  /// Votes on the phone.
  vote,

  /// Gets the most votes.
  votes,

  /// Cheers.
  win,
}

/// What an arrow between two figures means.
enum _Kind {
  /// Scans the host's code.
  scan,

  /// The pack picks its victim.
  choose,

  /// The seer looks at someone.
  gaze,

  /// The witch saves the victim.
  heal,

  /// Points at a suspect.
  accuse,

  /// A vote.
  vote,
}

/// One figure of a scene.
class _Actor {
  const _Actor(
    this.asset, {
    this.mirror = false,
    this.asleep = false,
    this.ghost = false,
    this.cue,
    this.cueAsset,
  });

  final String asset;
  final bool mirror;

  /// Eyes closed in the dark while others act.
  final bool asleep;

  /// Out of the game: pale and see-through.
  final bool ghost;
  final _Cue? cue;
  final String? cueAsset;
}

/// An arrow from one figure to another (by their order).
class _Link {
  const _Link(this.from, this.to, this.kind);

  final int from;
  final int to;
  final _Kind kind;
}

/// A step's scene: a corner of a stage set, its figures and what passes
/// between them.
class _Scene {
  const _Scene(
    this.set,
    this.focus,
    this.actors, {
    this.night = false,
    this.links = const [],
    this.victim,
    this.spotlight,
  });

  final String set;
  final Alignment focus;
  final List<_Actor> actors;

  /// Deep night: the set darkens.
  final bool night;
  final List<_Link> links;

  /// The figure the pack or the vote picked: a red ring at its feet.
  final int? victim;

  /// The figure in the light (you): a warm pool at its feet.
  final int? spotlight;
}

/// Where everything stands in a picture of size [w] × [h].
class _Layout {
  _Layout(this.scene, this.w, this.h);

  final _Scene scene;
  final double w;
  final double h;

  int get n => scene.actors.length;

  /// Room above the heads for the bubbles.
  double get headroom => h * 0.25;
  double get floor => h * 0.95;
  double get bubble => h * 0.2;

  /// Each figure's own place: equal columns with a little margin.
  Rect slot(int i) {
    final margin = w * 0.04;
    final width = (w - 2 * margin) / n;
    return Rect.fromLTRB(
      margin + i * width,
      headroom,
      margin + (i + 1) * width,
      floor,
    );
  }

  /// The figure inside its place: as tall as fits, standing on the floor.
  /// The figures are about half as wide as tall.
  Rect figure(int i) {
    final s = slot(i);
    final height = min(s.height, s.width * 0.94 / 0.6);
    final width = height * 0.6;
    return Rect.fromLTWH(
      s.center.dx - width / 2,
      floor - height,
      width,
      height,
    );
  }

  /// Beside a figure's head, on the side facing [towards]: where arrows
  /// start and end, above the crowd rather than across the bodies.
  Offset beside(int i, double towards) {
    final f = figure(i);
    final side = (towards - f.center.dx).sign;
    return Offset(f.center.dx + side * f.width * 0.3, f.top + f.height * 0.2);
  }

  /// The bubble right above a figure's head, inside the picture: every
  /// figure has its own column, so no two bubbles meet.
  Rect bubbleRect(int i) {
    final f = figure(i);
    final cx = f.center.dx.clamp(bubble / 2 + 4, w - bubble / 2 - 4);
    final cy = max(bubble / 2 + 4, f.top - bubble * 0.5);
    return Rect.fromCenter(
      center: Offset(cx, cy),
      width: bubble,
      height: bubble,
    );
  }
}

class _Picture extends StatelessWidget {
  const _Picture({required this.scene});

  final _Scene scene;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AspectRatio(
      aspectRatio: 16 / 10,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Palette.stageBrass, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LayoutBuilder(
            builder: (context, box) {
              final at = _Layout(scene, box.maxWidth, box.maxHeight);
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/stage/${scene.set}.webp',
                    fit: BoxFit.cover,
                    alignment: scene.focus,
                    cacheWidth: (at.w * 2).round(),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: scene.night
                            ? const [Color(0x99050A18), Color(0xB3050A18)]
                            : const [Color(0x22000000), Color(0x66000000)],
                      ),
                    ),
                  ),
                  // Light and rings on the floor, under the figures.
                  CustomPaint(painter: _FloorPainter(at)),
                  for (final (i, a) in scene.actors.indexed)
                    Positioned.fromRect(
                      rect: at.figure(i),
                      child: _Figure(actor: a, night: scene.night),
                    ),
                  // Arrows over the figures, under the bubbles.
                  CustomPaint(painter: _LinkPainter(at)),
                  for (final (i, a) in scene.actors.indexed)
                    if (a.cue != null)
                      Positioned.fromRect(
                        rect: at.bubbleRect(i),
                        child: _Bubble(cue: a.cue!, asset: a.cueAsset),
                      ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

/// The warm pool under the figure in the light, the red ring under the
/// victim.
class _FloorPainter extends CustomPainter {
  _FloorPainter(this.at);

  final _Layout at;

  @override
  void paint(Canvas canvas, Size size) {
    void pool(int i, Color c, {bool ring = false}) {
      final f = at.figure(i);
      final r = Rect.fromCenter(
        center: Offset(f.center.dx, at.floor - at.h * 0.015),
        width: f.width * 1.5,
        height: at.h * 0.09,
      );
      canvas.drawOval(
        r,
        Paint()
          ..shader = ui.Gradient.radial(r.center, r.width / 2, [
            c.withValues(alpha: 0.6),
            c.withValues(alpha: 0),
          ]),
      );
      if (ring) {
        canvas.drawOval(
          r.deflate(r.height * 0.18),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(2, at.h * 0.012)
            ..color = c,
        );
      }
    }

    final spot = at.scene.spotlight;
    if (spot != null) pool(spot, const Color(0xFFFFD58A));
    final victim = at.scene.victim;
    if (victim != null) pool(victim, Palette.curtain400, ring: true);
  }

  @override
  bool shouldRepaint(_FloorPainter old) => false;
}

/// Dashed arrows from one figure to another, arching over the stage.
class _LinkPainter extends CustomPainter {
  _LinkPainter(this.at);

  final _Layout at;

  @override
  void paint(Canvas canvas, Size size) {
    for (final link in at.scene.links) {
      final colour = switch (link.kind) {
        _Kind.choose || _Kind.accuse => Palette.curtain400,
        _Kind.heal => const Color(0xFF8FD28A),
        _Kind.gaze => const Color(0xFFB9C8FF),
        _Kind.scan || _Kind.vote => Palette.paper,
      };
      final a = at.beside(link.from, at.figure(link.to).center.dx);
      final b = at.beside(link.to, at.figure(link.from).center.dx);
      final lift = at.h * 0.06 + (b - a).distance * 0.18;
      final control = Offset((a.dx + b.dx) / 2, min(a.dy, b.dy) - lift);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(control.dx, control.dy, b.dx, b.dy);
      final width = max(2, at.h * 0.012).toDouble();
      // A dark edge under the dashes, so they read on any set.
      _dash(
        canvas,
        path,
        Paint()
          ..color = const Color(0x99000000)
          ..strokeWidth = width + 2.4
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
        width,
      );
      _dash(
        canvas,
        path,
        Paint()
          ..color = colour
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
        width,
      );
      // The head points along the curve's end.
      final tangent = (b - control) / (b - control).distance;
      final normal = Offset(-tangent.dy, tangent.dx);
      final head = width * 4.2;
      final tip = Path()
        ..moveTo(b.dx, b.dy)
        ..lineTo(
          b.dx - tangent.dx * head + normal.dx * head * 0.6,
          b.dy - tangent.dy * head + normal.dy * head * 0.6,
        )
        ..lineTo(
          b.dx - tangent.dx * head - normal.dx * head * 0.6,
          b.dy - tangent.dy * head - normal.dy * head * 0.6,
        )
        ..close();
      canvas
        ..drawPath(
          tip,
          Paint()
            ..color = const Color(0x99000000)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..strokeJoin = StrokeJoin.round,
        )
        ..drawPath(tip, Paint()..color = colour);
    }
  }

  void _dash(Canvas canvas, Path path, Paint paint, double width) {
    for (final metric in path.computeMetrics()) {
      final dash = width * 3.2;
      final gap = width * 2.4;
      // Leave room for the head at the end.
      final end = metric.length - width * 3;
      for (var d = 0.0; d < end; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, min(d + dash, end)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_LinkPainter old) => false;
}

/// A figure of a scene: dimmed when asleep, pale when out.
class _Figure extends StatelessWidget {
  const _Figure({required this.actor, required this.night});

  final _Actor actor;
  final bool night;

  @override
  Widget build(BuildContext context) {
    Widget figure = Image.asset(
      actor.asset,
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
    );
    if (actor.mirror) figure = Transform.flip(flipX: true, child: figure);
    if (actor.ghost) {
      return Opacity(
        opacity: 0.42,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.3, 0.5, 0.2, 0, 30, //
            0.3, 0.5, 0.2, 0, 40,
            0.3, 0.5, 0.2, 0, 70,
            0, 0, 0, 1, 0,
          ]),
          child: figure,
        ),
      );
    }
    if (actor.asleep || night) {
      // Who acts at night stands in moonlight; the sleepers in the dark.
      final dim = actor.asleep ? 0.5 : 0.92;
      figure = ColorFiltered(
        colorFilter: ColorFilter.matrix([
          dim, 0, 0, 0, 0, //
          0, dim, 0, 0, 0,
          0, 0, dim * 1.12, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: figure,
      );
    }
    return figure;
  }
}

/// A paper thought bubble, its little tail towards the head.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.cue, this.asset});

  final _Cue cue;
  final String? asset;

  @override
  Widget build(BuildContext context) {
    Widget icon(IconData i, [Color c = Palette.ink]) =>
        FittedBox(child: Icon(i, color: c));
    Widget glyph(String t, [Color c = Palette.ink]) => FittedBox(
      child: Text(
        t,
        textScaler: TextScaler.noScaling,
        style: TextStyle(
          fontFamily: displayFont,
          fontWeight: FontWeight.w700,
          fontSize: 40,
          height: 1,
          color: c,
        ),
      ),
    );
    final content = switch (cue) {
      _Cue.qr => icon(Icons.qr_code_2_rounded),
      _Cue.phone => icon(Icons.qr_code_scanner_rounded),
      _Cue.hidden => icon(Icons.lock_rounded, Palette.curtain600),
      _Cue.figure => Image.asset(asset!, fit: BoxFit.contain),
      _Cue.sleep => glyph('Zz', Palette.night500),
      _Cue.paw => icon(Icons.pets_rounded, Palette.curtain600),
      _Cue.eye => icon(Icons.visibility_rounded, Palette.night500),
      _Cue.potion => icon(Icons.science_rounded, Palette.forest700),
      _Cue.alarm => glyph('!', Palette.curtain600),
      _Cue.accuse => glyph('!', Palette.curtain600),
      _Cue.innocent => icon(Icons.favorite_rounded, Palette.curtain600),
      _Cue.doubt => glyph('?'),
      _Cue.vote => icon(Icons.how_to_vote_rounded),
      _Cue.votes => glyph('3', Palette.curtain600),
      _Cue.win => icon(Icons.star_rounded, Palette.gold500),
    };
    return CustomPaint(
      painter: const _BubblePainter(),
      child: Padding(
        padding: EdgeInsets.all(cue == _Cue.figure ? 5 : 9),
        child: ClipOval(child: Center(child: content)),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = size.center(Offset.zero);
    // The tail: a little point down to the head below.
    final tail = Path()
      ..moveTo(c.dx - r * 0.32, c.dy + r * 0.8)
      ..lineTo(c.dx + r * 0.08, c.dy + r * 1.32)
      ..lineTo(c.dx + r * 0.36, c.dy + r * 0.78)
      ..close();
    final shape = Path.combine(
      PathOperation.union,
      Path()..addOval(Rect.fromCircle(center: c, radius: r)),
      tail,
    );
    canvas
      ..drawShadow(shape, Colors.black, 3, false)
      ..drawPath(shape, Paint()..color = Palette.paper)
      ..drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = Palette.stageBrass,
      );
  }

  @override
  bool shouldRepaint(_BubblePainter old) => false;
}

/// The step's number, a brass-rimmed paper disc beside the phase.
class _Number extends StatelessWidget {
  const _Number(this.n);

  final int n;

  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Palette.curtain600,
      border: Border.all(color: Palette.stageBrass, width: 1.5),
    ),
    child: Text(
      '$n',
      textScaler: TextScaler.noScaling,
      style: const TextStyle(
        fontFamily: displayFont,
        fontWeight: FontWeight.w700,
        fontSize: 17,
        height: 1,
        color: Palette.paper,
      ),
    ),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Palette.gold500.withValues(alpha: 0.5),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Icon(
            Icons.nightlight_round,
            size: 14,
            color: Palette.gold500,
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Palette.gold500.withValues(alpha: 0.5),
          ),
        ),
      ],
    ),
  );
}
