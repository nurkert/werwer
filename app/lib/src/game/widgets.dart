import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/atmosphere.dart';
import 'package:whowolf/src/game/cardboard.dart';
import 'package:whowolf/src/game/figures.dart';
import 'package:whowolf/src/game/stage.dart';
import 'package:whowolf/src/stage/moon.dart';
import 'package:whowolf/src/stage/puppet_card.dart';
import 'package:whowolf/src/stage/stage_kit.dart';
import 'package:whowolf/src/theme.dart';

extension RoleText on AppLocalizations {
  String role(Role role) => switch (role) {
    Role.villager => roleVillager,
    Role.werewolf => roleWerewolf,
    Role.seer => roleSeer,
    Role.witch => roleWitch,
    Role.hunter => roleHunter,
    Role.cupid => roleCupid,
    Role.protector => roleProtector,
  };

  String roleText(Role role) => switch (role) {
    Role.villager => roleVillagerText,
    Role.werewolf => roleWerewolfText,
    Role.seer => roleSeerText,
    Role.witch => roleWitchText,
    Role.hunter => roleHunterText,
    Role.cupid => roleCupidText,
    Role.protector => roleProtectorText,
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

/// Text standing straight on a painted set (not on a card) gets a soft
/// patch of night behind it, so it reads on every scene, the bright
/// morning and the busy village included. Inside a card, or inside another
/// backing, it adds nothing.
class StageBacking extends StatelessWidget {
  const StageBacking({required this.child, super.key});

  final Widget child;

  static const _night = Color(0x52060B14);

  @override
  Widget build(BuildContext context) {
    if (context.getInheritedWidgetOfExactType<Surface>() != null ||
        context.getInheritedWidgetOfExactType<_Backed>() != null) {
      return child;
    }
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _night,
        borderRadius: BorderRadius.all(Radius.circular(20)),
        // The same colour spread out softly: an edge you do not see.
        boxShadow: [BoxShadow(color: _night, blurRadius: 24, spreadRadius: 10)],
      ),
      child: _Backed(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: child,
        ),
      ),
    );
  }
}

class _Backed extends InheritedWidget {
  const _Backed({required super.child});

  @override
  bool updateShouldNotify(_Backed old) => false;
}

/// A big title in the book serif, warm on the night, with a soft glow;
/// [eyebrow] sets the small line above it ("— SPIELABEND —").
class Headline extends StatelessWidget {
  const Headline(
    this.text, {
    super.key,
    this.color,
    this.size = 34,
    this.eyebrow,
  });

  final String text;
  final Color? color;
  final double size;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    final paper = Surface.paper(context);
    final style = TextStyle(
      fontFamily: displayFont,
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: 1.08,
      color: color ?? (paper ? Palette.ink : Palette.stageIvory),
      shadows: paper
          ? null
          : const [
              Shadow(
                color: Color(0xCC000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
    );
    // Never break inside a word ("Dorfbewohner" at the largest text):
    // the title shrinks until its longest word fits on one line.
    final title = LayoutBuilder(
      builder: (context, box) {
        final scaler = MediaQuery.textScalerOf(context);
        var longest = 0.0;
        for (final word in text.split(RegExp(r'\s+'))) {
          final painter = TextPainter(
            text: TextSpan(text: word, style: style),
            textScaler: scaler,
            textDirection: TextDirection.ltr,
            maxLines: 1,
          )..layout();
          longest = max(longest, painter.width);
          painter.dispose();
        }
        final fit = box.maxWidth.isFinite && longest > box.maxWidth
            ? box.maxWidth / longest
            : 1.0;
        return Text(
          text,
          textAlign: TextAlign.center,
          style: fit < 1 ? style.copyWith(fontSize: size * fit * 0.98) : style,
        );
      },
    );
    final line = eyebrow;
    if (line == null) return StageBacking(child: title);
    return StageBacking(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Eyebrow(line, color: paper ? Palette.inkSoft : null),
          const SizedBox(height: 8),
          title,
        ],
      ),
    );
  }
}

/// Body text, cream on the night, ink on paper.
class Body extends StatelessWidget {
  const Body(this.text, {super.key, this.muted = false});

  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final paper = Surface.paper(context);
    final color = paper ? Palette.inkSoft : Palette.stageIvorySoft;
    return StageBacking(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          height: 1.45,
          color: muted ? color.withValues(alpha: paper ? 0.8 : 0.92) : color,
          // Readable on any painted scene, also the bright morning.
          shadows: paper
              ? null
              : const [
                  Shadow(color: Color(0xE6000000), blurRadius: 6),
                  Shadow(color: Color(0x99000000), blurRadius: 14),
                ],
        ),
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
  Widget build(BuildContext context) {
    if (!paper) {
      return DecoratedBox(
        decoration: PlaqueDecoration(lit: highlight),
        child: Surface(
          onPaper: false,
          child: Padding(padding: padding, child: child),
        ),
      );
    }
    return CustomPaint(
      painter: BoardPainter(
        radius: Radii.m,
        face: BoardFace.kraft,
        rim: highlight ? Palette.lantern400 : null,
        paperInset: _paperInset,
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: thickness),
        child: Padding(
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
        ),
      ),
    );
  }
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
/// The role to print on [seat]'s card for everyone to see. A ghost knows
/// every role, but shows openly only its own and those revealed at death:
/// the rest stays behind the held ghost sight, away from the neighbours.
String? openRole(PlayerView view, SeatView seat, AppLocalizations l10n) {
  final role = seat.role;
  if (role == null) return null;
  if (view.yourGhostSight == GhostSight.off || seat.id == view.you) {
    return l10n.role(role);
  }
  final revealed = view.deaths.any(
    (d) => d.player == seat.id && d.role != null,
  );
  return revealed ? l10n.role(role) : null;
}

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
    // Puppet cards (task 012) in even rows. In a choice (onTap) only who
    // can be chosen is shown: not yourself unless you may pick yourself,
    // not the dead; so a few cards fit in one row without scrolling.
    bool can(SeatView seat) =>
        onTap != null &&
        (enabled?.call(seat) ?? (seat.isAlive && seat.id != view.you));
    final seats = [
      for (final seat in view.seats)
        if (onTap == null || can(seat) || (seat.isAlive && seat.id != view.you))
          seat,
    ];
    return LayoutBuilder(
      builder: (context, box) {
        const gap = 12.0;
        final most = max(3, ((box.maxWidth + gap) / (112 + gap)).floor());
        final rows = (seats.length / most).ceil().clamp(1, 99);
        final columns = (seats.length / rows).ceil().clamp(1, most);
        // Never so big that two rows leave the screen of a short window.
        final double tallest = max(
          96,
          MediaQuery.sizeOf(context).height * 0.15,
        );
        final width = min<double>(
          min(170, tallest),
          (box.maxWidth - gap * (columns - 1)) / columns,
        );
        // As wide as the planned columns, so the rows stay even (3 + 2,
        // never 4 + 1) however small the cards are.
        return Center(
          child: SizedBox(
            width: columns * width + gap * (columns - 1) + 0.5,
            child: Wrap(
              spacing: gap,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                for (final seat in seats)
                  () {
                    final tappable = can(seat);
                    final card = PuppetCard(
                      // A villager pose at work, but plain figures at night.
                      pose: view.phase == Phase.night
                          ? 0
                          : poseFor(
                              seat.persona,
                              '${view.round}/${view.phase.name}/${seat.id.value}',
                            ),
                      persona: seat.persona,
                      name: seat.name,
                      width: width,
                      you: seat.id == view.you,
                      alive: seat.isAlive,
                      selected: seat.id == selected || chosen.contains(seat.id),
                      onTap: tappable ? () => onTap?.call(seat) : null,
                      subtitle: [
                        if (seat.id == view.you) l10n.you,
                        // Never your own role at night: a glance across the
                        // table would read it.
                        if (!(seat.id == view.you && view.phase == Phase.night))
                          ?openRole(view, seat, l10n),
                        ?badges[seat.id],
                      ].where((part) => part.isNotEmpty).join(' · '),
                      deadLabel: l10n.dead,
                      trailing: trailing?.call(seat),
                    );
                    // Alive but out of this choice (outside a runoff): dimmed.
                    // A small lock says why it cannot be tapped.
                    return onTap != null && !tappable && seat.isAlive
                        ? Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Opacity(opacity: 0.45, child: card),
                              Positioned(
                                right: -6,
                                top: -6,
                                child: Semantics(
                                  label: l10n.notChoosable,
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Palette.stagePlaque,
                                      border: Border.fromBorderSide(
                                        BorderSide(
                                          color: Palette.stageBrass,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.lock_rounded,
                                      size: 15,
                                      color: Palette.stageIvorySoft,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : card;
                  }(),
              ],
            ),
          ),
        );
      },
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
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
      // The last seconds tick (never at night, see SoundScope).
      final endsAt = widget.endsAt;
      if (endsAt == null) return;
      final left = endsAt.difference(DateTime.now()).inSeconds;
      if (left > 0 && left <= 5) SoundScope.play(context, Sound.tick);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  /// The time the phase had when this clock first saw its end: the ring
  /// runs from there.
  DateTime? _seenEnd;
  int _total = 1;

  @override
  Widget build(BuildContext context) {
    final endsAt = widget.endsAt;
    if (endsAt == null) return const SizedBox.shrink();
    final now = DateTime.now();
    if (endsAt != _seenEnd) {
      _seenEnd = endsAt;
      _total = endsAt.difference(now).inMilliseconds.clamp(1, 1 << 30);
    }
    final leftMs = endsAt.difference(now).inMilliseconds.clamp(0, _total);
    final seconds = (leftMs / 1000).ceil();
    final urgent = seconds <= 10;
    final label = seconds >= 60
        ? '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}'
        : '0:${seconds.toString().padLeft(2, '0')}';
    // The moon clock (task 012): the ring runs as the time goes.
    return Semantics(
      label: AppLocalizations.of(context).timeLeft(seconds),
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: 92,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Moon(
              size: 92,
              progress: 1 - leftMs / _total,
              glow: false,
            ),
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Palette.stagePlaque.withValues(alpha: 0.78),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: displayFont,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: urgent ? Palette.curtain400 : Palette.stageIvory,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The main action: a wide lantern-orange button with an icon on the
/// right, its label in the book serif. One per screen.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon = Icons.arrow_forward_rounded,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Shown after the label; `null` for none.
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: _StageButton(
      lantern: true,
      onPressed: onPressed,
      label: label,
      trailing: icon,
    ),
  );
}

/// A quieter action next to the primary one: dark board with a brass edge
/// (lit when [selected]), or on paper a kraft board.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.selected = false,
    this.expand = true,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Lit like a chosen card (e.g. "abstain" after abstaining).
  final bool selected;

  /// Takes the full width; otherwise as wide as its label.
  final bool expand;

  /// Shown before the label.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final button = _StageButton(
      lantern: false,
      selected: selected,
      onPressed: onPressed,
      label: label,
      leading: icon,
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// A button that gives a little under the finger and springs back.
class _StageButton extends StatefulWidget {
  const _StageButton({
    required this.lantern,
    required this.onPressed,
    required this.label,
    this.selected = false,
    this.leading,
    this.trailing,
  });

  final bool lantern;
  final bool selected;
  final VoidCallback? onPressed;
  final String label;
  final IconData? leading;
  final IconData? trailing;

  @override
  State<_StageButton> createState() => _StageButtonState();
}

class _StageButtonState extends State<_StageButton> {
  bool _down = false;

  void _set(bool down) {
    if (widget.onPressed != null && down != _down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final paper = Surface.paper(context);
    final foreground = !enabled
        ? Palette.stageIvorySoft.withValues(alpha: 0.45)
        : widget.lantern
        ? Palette.stageLanternInk
        : paper
        ? Palette.ink
        : Palette.stageIvory;
    final big = widget.lantern;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: _down ? 1 : 0),
        duration: Duration(milliseconds: _down ? 60 : 180),
        curve: _down ? Curves.easeOut : Curves.easeOutBack,
        builder: (context, press, child) => Transform.translate(
          offset: Offset(0, 2 * press),
          child: Transform.scale(
            scale: 1 - 0.015 * press,
            child: DecoratedBox(
              decoration: widget.lantern
                  ? LanternDecoration(press: press, enabled: enabled)
                  : PlaqueDecoration(lit: widget.selected),
              child: child,
            ),
          ),
        ),
        child: TextButton(
          style: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(foreground),
            overlayColor: WidgetStatePropertyAll(
              foreground.withValues(alpha: 0.06),
            ),
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 22, vertical: big ? 15 : 11),
            ),
            minimumSize: WidgetStatePropertyAll(Size(48, big ? 58 : 48)),
            shape: const WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(Radii.m)),
              ),
            ),
          ),
          onPressed: widget.onPressed == null
              ? null
              : () {
                  SoundScope.play(context, Sound.tap);
                  widget.onPressed!();
                },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.leading case final icon?) ...[
                Icon(icon, size: 20, color: foreground),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: displayFont,
                    fontSize: big ? 21 : 17,
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
              ),
              if (widget.trailing case final icon?) ...[
                const SizedBox(width: 12),
                Icon(icon, size: 22, color: foreground),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
