import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/cardboard.dart';
import 'package:whowolf/src/game/figures.dart';
import 'package:whowolf/src/game/stage.dart';
import 'package:whowolf/src/theme.dart';

extension RoleText on AppLocalizations {
  String role(Role role) => switch (role) {
    Role.villager => roleVillager,
    Role.werewolf => roleWerewolf,
    Role.seer => roleSeer,
    Role.witch => roleWitch,
    Role.hunter => roleHunter,
    Role.cupid => roleCupid,
  };

  String roleText(Role role) => switch (role) {
    Role.villager => roleVillagerText,
    Role.werewolf => roleWerewolfText,
    Role.seer => roleSeerText,
    Role.witch => roleWitchText,
    Role.hunter => roleHunterText,
    Role.cupid => roleCupidText,
  };

  String persona(Persona persona) => switch (persona) {
    Persona.maid => persona_maid,
    Persona.farmer => persona_farmer,
    Persona.baker => persona_baker,
    Persona.smith => persona_smith,
    Persona.fisher => persona_fisher,
    Persona.miller => persona_miller,
    Persona.seamstress => persona_seamstress,
    Persona.minstrel => persona_minstrel,
    Persona.gooseGirl => persona_gooseGirl,
    Persona.beekeeper => persona_beekeeper,
    Persona.innkeeper => persona_innkeeper,
    Persona.shepherd => persona_shepherd,
    Persona.washerwoman => persona_washerwoman,
    Persona.carpenter => persona_carpenter,
    Persona.spinner => persona_spinner,
    Persona.cobbler => persona_cobbler,
    Persona.flowerGirl => persona_flowerGirl,
    Persona.mayor => persona_mayor,
    Persona.grandmother => persona_grandmother,
    Persona.grandfather => persona_grandfather,
  };

  String faction(Faction faction) => switch (faction) {
    Faction.village => factionVillage,
    Faction.werewolves => factionWerewolves,
    Faction.lovers => factionLovers,
  };
}

extension SeatLookup on PlayerView {
  String nameOf(PlayerId id) =>
      seats.where((s) => s.id == id).map((s) => s.name).firstOrNull ?? '?';
}

/// Whether the widgets below sit on a cream paper card (dark ink) or on the
/// night stage (moonlit text). Text widgets pick their colours from it.
class Surface extends InheritedWidget {
  const Surface({required this.onPaper, required super.child, super.key});

  final bool onPaper;

  static bool paper(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Surface>()?.onPaper ?? false;

  @override
  bool updateShouldNotify(Surface old) => old.onPaper != onPaper;
}

/// A big title in the display font.
class Headline extends StatelessWidget {
  const Headline(this.text, {super.key, this.color, this.size = 34});

  final String text;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: TextStyle(
      fontFamily: displayFont,
      fontSize: size,
      height: 1.1,
      color: color ?? (Surface.paper(context) ? Palette.ink : Palette.moon100),
    ),
  );
}

/// Body text, cream on the night, ink on paper.
class Body extends StatelessWidget {
  const Body(this.text, {super.key, this.muted = false});

  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final paper = Surface.paper(context);
    final color = paper ? Palette.inkSoft : Palette.moon200;
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16,
        height: 1.45,
        color: muted ? color.withValues(alpha: paper ? 0.8 : 0.72) : color,
      ),
    );
  }
}

/// A piece of cardboard. On the night it is dark card with a pale cut edge
/// and a little thickness below; [paper] makes it a cream playbill card with
/// the gold double rule, for news and the big moments. [highlight] lights
/// its edge in lantern orange.
class Panel extends StatelessWidget {
  const Panel({
    required this.child,
    super.key,
    this.highlight = false,
    this.paper = false,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final bool highlight;
  final bool paper;
  final EdgeInsets padding;

  /// How deep the board is: its corrugated edge shows below the face.
  static const double thickness = 6;

  /// How much kraft shows around a glued-on playbill.
  static const double _paperInset = 6;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: BoardPainter(
      radius: Radii.m,
      face: paper ? BoardFace.kraft : BoardFace.night,
      rim: highlight ? Palette.lantern400 : null,
      paperInset: paper ? _paperInset : null,
    ),
    child: Padding(
      padding: const EdgeInsets.only(bottom: thickness),
      child: paper
          ? Padding(
              padding: const EdgeInsets.all(_paperInset),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Radii.m - _paperInset),
                child: CustomPaint(
                  foregroundPainter: GrainPainter(
                    opacity: 0.16,
                    blend: BlendMode.multiply,
                  ),
                  child: _GoldRule(
                    child: Surface(
                      onPaper: true,
                      child: Padding(padding: padding, child: child),
                    ),
                  ),
                ),
              ),
            )
          : Surface(
              onPaper: false,
              child: Padding(padding: padding, child: child),
            ),
    ),
  );
}

/// The double gold rule just inside a paper card, as on the playbill.
class _GoldRule extends StatelessWidget {
  const _GoldRule({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(5),
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(Radii.m - 5),
      border: Border.all(color: Palette.gold500, width: 1.5),
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.m - 8),
        border: Border.all(
          color: Palette.gold500.withValues(alpha: 0.55),
          width: 0.8,
        ),
      ),
      child: child,
    ),
  );
}

/// A rubber stamp, slightly crooked, as printed on the website's playbill.
class Stamp extends StatelessWidget {
  const Stamp(
    this.label, {
    super.key,
    this.color = Palette.lantern300,
    this.size = 15,
    this.angle = -0.05,
  });

  final String label;
  final Color color;
  final double size;
  final double angle;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: color, width: size / 6),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(size * 0.5, size * 0.12, size * 0.5, 0),
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            fontFamily: displayFont,
            fontSize: size,
            height: 1.25,
            color: color,
          ),
        ),
      ),
    ),
  );
}

/// The seats as tappable cards.
class SeatGrid extends StatelessWidget {
  const SeatGrid({
    required this.view,
    super.key,
    this.selected,
    this.chosen = const {},
    this.onTap,
    this.enabled,
    this.badges = const {},
    this.trailing,
  });

  final PlayerView view;
  final PlayerId? selected;

  /// More than one picked seat (cupid's pair).
  final Set<PlayerId> chosen;
  final void Function(SeatView seat)? onTap;

  /// Which seats can be tapped; all living others by default.
  final bool Function(SeatView seat)? enabled;

  /// Small extra text under a name (e.g. a werewolf's pick).
  final Map<PlayerId, String> badges;

  /// Optional widget per seat (e.g. a remove button).
  final Widget? Function(SeatView seat)? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Two cards a row on a phone, more on wider screens.
    return LayoutBuilder(
      builder: (context, box) {
        const gap = 10.0;
        final columns = max(2, ((box.maxWidth + gap) / 190).floor());
        final width = min<double>(
          220,
          (box.maxWidth - gap * (columns - 1)) / columns,
        );
        return Wrap(
          spacing: gap,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            for (final seat in view.seats)
              _SeatTile(
                width: width,
                seat: seat,
                isYou: seat.id == view.you,
                selected: seat.id == selected || chosen.contains(seat.id),
                enabled:
                    onTap != null &&
                    (enabled?.call(seat) ??
                        (seat.isAlive && seat.id != view.you)),
                onTap: () => onTap?.call(seat),
                subtitle: [
                  if (seat.id == view.you) l10n.you,
                  if (seat.role != null) l10n.role(seat.role!),
                  ?badges[seat.id],
                ].where((part) => part.isNotEmpty).join(' · '),
                deadLabel: l10n.dead,
                trailing: trailing?.call(seat),
              ),
          ],
        );
      },
    );
  }
}

class _SeatTile extends StatelessWidget {
  const _SeatTile({
    required this.width,
    required this.seat,
    required this.isYou,
    required this.selected,
    required this.enabled,
    required this.onTap,
    required this.subtitle,
    required this.deadLabel,
    this.trailing,
  });

  final double width;
  final SeatView seat;
  final bool isYou;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final String subtitle;
  final String deadLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final edge = selected
        ? Palette.lantern400
        : isYou
        ? Palette.moon200.withValues(alpha: 0.55)
        : Palette.card200.withValues(alpha: 0.22);
    final radius = BorderRadius.circular(Radii.m);
    final reduce = MediaQuery.of(context).disableAnimations;
    return AnimatedSlide(
      // A picked card lifts a little off the stage.
      offset: selected ? const Offset(0, -0.04) : Offset.zero,
      duration: reduce ? Duration.zero : const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Opacity(
            opacity: seat.isAlive ? 1 : 0.5,
            child: Material(
              color: selected ? Palette.night700 : Palette.night800,
              shape: RoundedRectangleBorder(
                borderRadius: radius,
                side: BorderSide(color: edge, width: selected ? 2.5 : 1.5),
              ),
              shadowColor: Colors.black,
              elevation: selected ? 8 : 2,
              child: InkWell(
                borderRadius: radius,
                onTap: enabled ? onTap : null,
                child: SizedBox(
                  width: width,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Portrait(persona: seat.persona, grey: !seat.isAlive),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                seat.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Palette.moon100,
                                ),
                              ),
                              if (subtitle.isNotEmpty)
                                Text(
                                  subtitle,
                                  maxLines: 3,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    height: 1.3,
                                    color: Palette.moon200,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        ?trailing,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (!seat.isAlive)
            Positioned(
              right: 8,
              top: -6,
              child: Stamp(deadLabel, color: Palette.curtain400, size: 13),
            ),
        ],
      ),
    );
  }
}

/// Seconds until [endsAt], ticking, as a small hourglass label.
class Countdown extends StatefulWidget {
  const Countdown({required this.endsAt, super.key});

  final DateTime? endsAt;

  @override
  State<Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<Countdown> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final endsAt = widget.endsAt;
    if (endsAt == null) return const SizedBox.shrink();
    final seconds = endsAt.difference(DateTime.now()).inSeconds.clamp(0, 9999);
    final urgent = seconds <= 10;
    final color = urgent ? Palette.curtain400 : Palette.lantern300;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.hourglass_bottom_rounded, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          AppLocalizations.of(context).timeLeft(seconds),
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// The main action: a lantern-orange board whose cut edge gives under a
/// finger.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: _BoardButton(
      face: BoardFace.paint,
      paint: Palette.lantern400,
      foreground: Palette.ink,
      onPressed: onPressed,
      label: label,
    ),
  );
}

/// A quieter action next to the primary one: a plain board (midnight on
/// the stage, kraft on paper) with a rim.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.selected = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Lit like a chosen card (e.g. "abstain" after abstaining).
  final bool selected;

  /// Takes the full width; otherwise as wide as its label.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final paper = Surface.paper(context);
    final button = _BoardButton(
      face: paper ? BoardFace.kraft : BoardFace.night,
      foreground: paper ? Palette.ink : Palette.moon100,
      rim: selected
          ? Palette.lantern400
          : paper
          ? Palette.wood700
          : Palette.night500,
      onPressed: onPressed,
      label: label,
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// A button cut from board: the face sinks into the corrugated edge while
/// pressed and springs back.
class _BoardButton extends StatefulWidget {
  const _BoardButton({
    required this.face,
    required this.foreground,
    required this.onPressed,
    required this.label,
    this.paint,
    this.rim,
  });

  final BoardFace face;
  final Color? paint;
  final Color foreground;
  final Color? rim;
  final VoidCallback? onPressed;
  final String label;

  @override
  State<_BoardButton> createState() => _BoardButtonState();
}

class _BoardButtonState extends State<_BoardButton> {
  static const double _thickness = 6;
  bool _down = false;

  void _set(bool down) {
    if (widget.onPressed != null && down != _down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: _down ? 0.7 : 0),
        duration: Duration(milliseconds: _down ? 60 : 160),
        curve: _down ? Curves.easeOut : Curves.easeOutBack,
        builder: (context, press, child) => CustomPaint(
          painter: BoardPainter(
            radius: 999,
            face: enabled ? widget.face : BoardFace.paint,
            color: enabled ? widget.paint : Palette.night700,
            rim: enabled ? widget.rim : Palette.night500,
            press: press,
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: _thickness),
            child: Transform.translate(
              offset: Offset(0, _thickness * press),
              child: child,
            ),
          ),
        ),
        child: TextButton(
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? Palette.moon200.withValues(alpha: 0.45)
                  : widget.foreground,
            ),
            overlayColor: WidgetStatePropertyAll(
              widget.foreground.withValues(alpha: 0.08),
            ),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 26, vertical: 15),
            ),
            minimumSize: const WidgetStatePropertyAll(Size(48, 52)),
            textStyle: const WidgetStatePropertyAll(
              TextStyle(
                fontFamily: textFont,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            shape: const WidgetStatePropertyAll(StadiumBorder()),
          ),
          onPressed: widget.onPressed,
          child: Text(widget.label, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
