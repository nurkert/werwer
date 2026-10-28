import 'dart:async';
import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_core/game_core.dart';
import 'package:protocol/protocol.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/atmosphere.dart';
import 'package:whowolf/src/game/figures.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/net/game_session.dart';
import 'package:whowolf/src/stage/stage_kit.dart';
import 'package:whowolf/src/stage/tappable.dart';
import 'package:whowolf/src/theme.dart';

/// Your own figure in the lobby, and the sheet to pick another one.
/// The lobby's first page on a phone (task 012): your figure big on the
/// stage, and every figure as a portrait to tap. Taken ones are greyed out
/// with their player's name; a tap picks at once and your figure turns
/// round into the new one.
class LobbyFigureStage extends StatefulWidget {
  const LobbyFigureStage({required this.session, super.key});

  final GameSession session;

  @override
  State<LobbyFigureStage> createState() => _LobbyFigureStageState();
}

class _LobbyFigureStageState extends State<LobbyFigureStage>
    with TickerProviderStateMixin {
  /// The figure on the big stage. A figure picked from the cards flies up
  /// there with a turn; a change from elsewhere (the host refused, another
  /// device) turns it to its edge, swaps it there, and turns it back.
  late Persona _shown;
  Persona? _target;
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );
  final ValueNotifier<double> _angle = ValueNotifier(0);

  /// The figure on its way from its card to the stage.
  Persona? _flying;

  /// The figure that left the stage and slides back into its card.
  Persona? _returning;

  final GlobalKey _stage = GlobalKey();
  final Map<Persona, GlobalKey> _cards = {
    for (final p in Persona.values) p: GlobalKey(),
  };
  final List<(OverlayEntry, AnimationController)> _flights = [];

  static const _flight = Duration(milliseconds: 680);

  @override
  void initState() {
    super.initState();
    _shown = widget.session.view!.yourSeat.persona;
    _flip
      ..addListener(_turn)
      ..addStatusListener((status) {
        // Picked again while turning: turn once more to the latest.
        if (status == AnimationStatus.completed) _follow();
      });
  }

  void _turn() {
    final v = _flip.value;
    if (v < 0.5) {
      _angle.value = Curves.easeIn.transform(v * 2) * pi / 2;
      return;
    }
    final target = _target;
    if (target != null && target != _shown) setState(() => _shown = target);
    _angle.value = -(1 - Curves.easeOut.transform((v - 0.5) * 2)) * pi / 2;
  }

  void _follow() {
    final mine = widget.session.view?.yourSeat.persona;
    if (mine == null || mine == _shown || _flying != null || !mounted) return;
    _target = mine;
    if (MediaQuery.of(context).disableAnimations) {
      setState(() => _shown = mine);
      return;
    }
    if (!_flip.isAnimating) unawaited(_flip.forward(from: 0));
  }

  @override
  void didUpdateWidget(LobbyFigureStage old) {
    super.didUpdateWidget(old);
    _follow();
  }

  @override
  void dispose() {
    for (final (entry, controller) in _flights) {
      entry.remove();
      controller.dispose();
    }
    _flip.dispose();
    _angle.dispose();
    super.dispose();
  }

  void _pick(Persona persona) {
    if (persona == widget.session.view!.yourSeat.persona || _flying != null) {
      return;
    }
    unawaited(precacheImage(AssetImage(personaAsset(persona)), context));
    SoundScope.play(context, Sound.tap);
    widget.session.send(PersonaIntent(persona));
    _fly(persona);
  }

  static Rect? _rectOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// The picked figure grows out of its card and flies up to the stage
  /// with a turn while the page scrolls back up; the old one leaves the
  /// stage upwards and slides back into its card. Only what is on the
  /// screen moves.
  void _fly(Persona persona) {
    final from = _rectOf(_cards[persona]!);
    final stage = _rectOf(_stage);
    if (MediaQuery.of(context).disableAnimations ||
        from == null ||
        stage == null) {
      setState(() => _shown = persona);
      return;
    }
    final screen = MediaQuery.sizeOf(context);
    final scroll = Scrollable.maybeOf(context)?.position;
    final scrolled = scroll?.pixels ?? 0;
    final old = _shown;
    if (stage.bottom > 0 && stage.top < screen.height) {
      _launch(
        old,
        from: stage,
        to: stage.shift(Offset(0, -stage.bottom - 60)),
        turns: 0,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInCubic,
      );
    }
    setState(() {
      _flying = persona;
      _returning = old;
    });
    if (scroll != null && scrolled > 0) {
      unawaited(
        scroll.animateTo(0, duration: _flight, curve: Curves.easeInOutCubic),
      );
    }
    _launch(
      persona,
      from: from,
      to: stage.shift(Offset(0, scrolled)),
      turns: 1,
      duration: _flight,
      curve: Curves.easeInOutCubic,
      done: () => setState(() {
        _shown = persona;
        _flying = null;
        _target = null;
        _follow();
      }),
    );
  }

  /// One figure flying above the page, by its centre and height.
  void _launch(
    Persona persona, {
    required Rect from,
    required Rect to,
    required double turns,
    required Duration duration,
    required Curve curve,
    VoidCallback? done,
  }) {
    final controller = AnimationController(vsync: this, duration: duration);
    final angle = ValueNotifier<double>(0);
    controller.addListener(
      () => angle.value = turns * 2 * pi * curve.transform(controller.value),
    );
    final entry = OverlayEntry(
      builder: (_) => AnimatedBuilder(
        animation: controller,
        builder: (_, _) {
          final t = curve.transform(controller.value);
          final centre = Offset.lerp(from.center, to.center, t)!;
          final height = lerpDouble(from.height, to.height, t)!;
          return Positioned.fromRect(
            rect: Rect.fromCenter(
              center: centre,
              width: height * 1.4,
              height: height,
            ),
            child: IgnorePointer(
              child: Center(
                child: TurningFigure(
                  asset: personaAsset(persona),
                  height: height,
                  angle: angle,
                  shadow: false,
                ),
              ),
            ),
          );
        },
      ),
    );
    final flight = (entry, controller);
    _flights.add(flight);
    Overlay.of(context).insert(entry);
    unawaited(
      controller.forward().whenComplete(() {
        if (!_flights.remove(flight)) return;
        entry.remove();
        controller.dispose();
        angle.dispose();
        if (mounted) done?.call();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final view = widget.session.view!;
    final mine = view.yourSeat.persona;
    final taken = {
      for (final s in view.seats)
        if (s.id != view.you) s.persona: s.name,
    };
    final allTaken = taken.length >= Persona.values.length;
    final onStage = _flying ?? _shown;
    final screen = MediaQuery.sizeOf(context);
    final figureHeight = (screen.height * 0.36).clamp(180.0, 340.0);
    return Column(
      children: [
        Headline(l10n.figureTitle, eyebrow: l10n.eyebrowEvening),
        const SizedBox(height: 4),
        SizedBox(
          height: figureHeight + 10,
          child: Center(
            // Empty while a figure flies up to it.
            child: Opacity(
              opacity: _flying == null ? 1 : 0,
              child: TurningFigure(
                key: _stage,
                asset: personaAsset(_shown),
                angle: _angle,
                height: figureHeight,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // The name and what the figure means, readable on any set.
        StageBacking(
          child: Column(
            children: [
              Text(
                l10n.persona(mine),
                style: const TextStyle(
                  fontFamily: displayFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 30,
                  color: Palette.stageLanternTop,
                  shadows: [Shadow(blurRadius: 10)],
                ),
              ),
              const SizedBox(height: 2),
              Body(l10n.personaHint),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Every figure as a card big enough for a thumb: three in a row on
        // a phone, more as the window grows. The one on the stage leaves
        // its card empty.
        LayoutBuilder(
          builder: (context, box) {
            const gap = 10.0;
            final columns = max(3, (box.maxWidth / 120).floor());
            final width = (box.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final p in Persona.values)
                  _FigureCard(
                    persona: p,
                    figureKey: _cards[p]!,
                    width: width,
                    selected: p == mine,
                    empty: p == onStage,
                    returning: p == _returning,
                    takenBy: allTaken ? null : taken[p],
                    onTap: () => _pick(p),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// One figure to pick in the lobby: the whole cut-out on a plaque, its
/// name below; lit when it is yours, in shadow with its player's name when
/// someone else has it. While the figure stands on the stage its card
/// holds only a pool of lantern light; coming back, it slides up into it.
class _FigureCard extends StatelessWidget {
  const _FigureCard({
    required this.persona,
    required this.figureKey,
    required this.width,
    required this.selected,
    required this.empty,
    required this.returning,
    required this.onTap,
    this.takenBy,
  });

  final Persona persona;
  final GlobalKey figureKey;
  final double width;
  final bool selected;
  final bool empty;
  final bool returning;
  final String? takenBy;
  final VoidCallback onTap;

  static const _shadow = ColorFilter.matrix([
    0.18, 0, 0, 0, 8, //
    0, 0.18, 0, 0, 12, //
    0, 0, 0.22, 0, 24, //
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final free = takenBy == null;
    final height = width * 1.05;
    Widget figure = Image.asset(
      personaAsset(persona),
      key: figureKey,
      height: height,
      fit: BoxFit.contain,
    );
    if (!free) figure = ColorFiltered(colorFilter: _shadow, child: figure);
    if (returning && !empty) {
      figure = TweenAnimationBuilder<double>(
        tween: Tween(begin: 1, end: 0),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutBack,
        child: figure,
        builder: (context, v, child) => Transform.translate(
          offset: Offset(0, v * height),
          child: Opacity(opacity: (1 - v).clamp(0.0, 1.0), child: child),
        ),
      );
    }
    final slot = SizedBox(
      height: height,
      child: ClipRect(
        child: empty
            ? DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, 0.8),
                    radius: 0.7,
                    colors: [
                      Palette.stageLanternTop.withValues(alpha: 0.28),
                      Palette.stageLanternTop.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: const SizedBox.expand(),
              )
            : Center(child: figure),
      ),
    );
    return Semantics(
      button: free,
      selected: selected,
      label: [l10n.persona(persona), ?takenBy].join(', '),
      excludeSemantics: true,
      child: Tappable(
        radius: Radii.m,
        onTap: free
            ? () {
                unawaited(HapticFeedback.selectionClick());
                onTap();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: width,
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
          decoration: PlaqueDecoration(lit: selected),
          child: Column(
            children: [
              slot,
              const SizedBox(height: 6),
              Text(
                l10n.persona(persona),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: displayFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: selected
                      ? Palette.stageLanternTop
                      : free
                      ? Palette.stageIvory
                      : Palette.stageIvorySoft.withValues(alpha: 0.6),
                ),
              ),
              if (!free)
                Text(
                  takenBy!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Palette.stageBrassLight,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
