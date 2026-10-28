import 'dart:async';
import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_core/game_core.dart';
import 'package:protocol/protocol.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/atmosphere.dart';
import 'package:whowolf/src/game/check_code.dart';
import 'package:whowolf/src/game/figures.dart';
import 'package:whowolf/src/game/ghost_sight.dart';
import 'package:whowolf/src/game/help.dart';
import 'package:whowolf/src/game/news.dart';
import 'package:whowolf/src/game/settings_sheet.dart';
import 'package:whowolf/src/game/table_circle.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/layout.dart';
import 'package:whowolf/src/net/game_session.dart';
import 'package:whowolf/src/stage/stage_kit.dart';
import 'package:whowolf/src/stage/stage_pages.dart';
import 'package:whowolf/src/theme.dart';

/// Shared scaffold of every phase. On a phone it is one column; a wide
/// window splits it: the [Aside] children (the table, the meadow, a big
/// figure) move into a second column on the right, the rest stays on the
/// left. Each column scrolls by itself and centres when it is short.
///
/// The [action] (the screen's one main button, task 012) stays put at the
/// foot of the screen, or of the left column, while the rest scrolls.
class PhaseBody extends StatelessWidget {
  const PhaseBody({required this.children, this.action, super.key});

  final List<Widget> children;
  final Widget? action;

  /// The column with the action pinned below it.
  Widget _withAction(BuildContext context, Widget scroll, double side) {
    final action = this.action;
    if (action == null) return scroll;
    final insets = MediaQuery.paddingOf(context);
    return Column(
      children: [
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: scroll,
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            side + insets.left,
            8,
            side + insets.right,
            insets.bottom + 14,
          ),
          child: action,
        ),
      ],
    );
  }

  static const double _gap = 18;

  static Widget _stack(List<Widget> children) => Column(
    children: [
      for (final (i, child) in children.indexed) ...[
        if (i > 0) const SizedBox(height: _gap),
        child,
      ],
    ],
  );

  @override
  Widget build(BuildContext context) {
    final layout = StageLayout.of(context);
    final aside = children.whereType<Aside>().toList();
    if (!layout.twoColumns || aside.isEmpty) {
      return _withAction(
        context,
        StageScroll(maxWidth: layout.columnWidth, child: _stack(children)),
        layout.size.width > layout.columnWidth + 40
            ? (layout.size.width - layout.columnWidth) / 2
            : 20,
      );
    }
    final main = [
      for (final child in children)
        if (child is! Aside) child,
    ];
    final width = layout.size.width;
    final insets = MediaQuery.paddingOf(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Padding(
          padding: EdgeInsets.only(left: insets.left, right: insets.right),
          child: MediaQuery.removePadding(
            context: context,
            removeLeft: true,
            removeRight: true,
            child: Row(
              children: [
                SizedBox(
                  width: (width * 0.4).clamp(340, 500),
                  child: _withAction(
                    context,
                    StageScroll(horizontal: 24, child: _stack(main)),
                    24,
                  ),
                ),
                Expanded(
                  child: StageScroll(
                    maxWidth: 720,
                    horizontal: 24,
                    child: _stack(aside),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A part of a phase that moves into the second column on wide windows
/// (see [PhaseBody]); on a phone it stays where it is.
class Aside extends StatelessWidget {
  const Aside({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class LobbyPhase extends StatefulWidget {
  const LobbyPhase({
    required this.session,
    this.link,
    this.qr,
    this.browserCanJoin = false,
    this.onShowCode,
    this.onLocalCode,
    this.relayFailed = false,
    this.keepAppOpen = false,
    super.key,
  });

  final GameSession session;

  /// How others reach this room (only on the host device).
  final JoinLink? link;

  /// The QR code's text (see `HostedRoom.qrText`).
  final String? qr;

  /// A phone without the app can join with the QR code (in the browser).
  final bool browserCanJoin;

  /// Shows the QR code, opening the room on the server first; `null` once
  /// the code is shown. Until then players on the same Wi-Fi find the room
  /// without it, and the server learns nothing.
  final Future<void> Function()? onShowCode;

  /// Switches to the Wi-Fi code only (a game without internet).
  final VoidCallback? onLocalCode;
  final bool relayFailed;

  /// This device hosts and the system may suspend the room in the
  /// background: ask the host to keep the app open.
  final bool keepAppOpen;

  @override
  State<LobbyPhase> createState() => _LobbyPhaseState();
}

class _LobbyPhaseState extends State<LobbyPhase> {
  /// The player whose seat is being swapped, waiting for the second tap.
  PlayerId? _swapFrom;

  /// Now and then everyone at the table strikes a new pose (task 012).
  int _poseTick = 0;
  Timer? _poses;

  @override
  void initState() {
    super.initState();
    _poses = Timer.periodic(const Duration(seconds: 25), (_) {
      if (mounted && !MediaQuery.of(context).disableAnimations) {
        setState(() => _poseTick++);
      }
    });
  }

  @override
  void dispose() {
    _poses?.cancel();
    super.dispose();
  }

  GameSession get session => widget.session;

  Future<void> _tapSeat(SeatView seat) async {
    final from = _swapFrom;
    if (from != null) {
      if (from != seat.id) session.send(SwapSeatsIntent(from, seat.id));
      setState(() => _swapFrom = null);
      return;
    }
    final l10n = AppLocalizations.of(context);
    final view = session.view!;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Portrait(persona: seat.persona),
              title: Text(
                seat.name,
                style: const TextStyle(
                  color: Palette.moon100,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: Palette.lantern400),
              title: Text(
                l10n.swapSeat,
                style: const TextStyle(color: Palette.moon100),
              ),
              onTap: () => Navigator.pop(context, 'swap'),
            ),
            if (seat.id != view.you)
              ListTile(
                leading: const Icon(Icons.close, color: Palette.curtain400),
                title: Text(
                  l10n.kick,
                  style: const TextStyle(color: Palette.moon100),
                ),
                onTap: () => Navigator.pop(context, 'kick'),
              ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'swap':
        setState(() => _swapFrom = seat.id);
      case 'kick':
        session.send(KickIntent(seat.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final view = session.view!;
    final count = view.seats.length;
    final settings = view.settings;
    final roles = count >= minPlayers ? settings.rolesFor(count) : null;
    final canStart = roles != null && count <= maxPlayers;
    String rolesLine(List<Role> roles) {
      final tally = <Role, int>{};
      for (final r in roles) {
        tally[r] = (tally[r] ?? 0) + 1;
      }
      return l10n.rolesInGame(
        tally.entries.map((e) => '${e.value}× ${l10n.role(e.key)}').join(', '),
      );
    }

    final link = widget.link;
    final swapFrom = _swapFrom;
    final action = session.isOwner
        ? PrimaryButton(
            label: l10n.startGame,
            onPressed: canStart
                ? () => session.send(const StartGameIntent())
                : null,
          )
        : null;
    final title = Headline(l10n.lobbyTitle, eyebrow: l10n.eyebrowEvening);
    final pending = [
      for (final p in session.pending) _PendingPanel(session: session, join: p),
    ];
    final invite = [
      if (session.isOwner && link != null)
        _Invite(
          link: link,
          qr: widget.qr ?? link.encode(),
          browserCanJoin: widget.browserCanJoin,
          onShowCode: widget.onShowCode,
          onLocalCode: widget.onLocalCode,
        ),
      if (widget.relayFailed) Body(l10n.relayFailed, muted: true),
      if (session.isOwner && widget.keepAppOpen)
        Body(l10n.keepAppOpenHint, muted: true),
      if (session.isOwner && count < 2) const HelpLink(),
    ];
    final table = [
      Headline(l10n.players(count)),
      if (count > 1) Body(l10n.tableHint, muted: true),
      if (swapFrom != null)
        Panel(
          highlight: true,
          child: Body(l10n.swapHint(view.nameOf(swapFrom))),
        ),
      TableCircle(
        view: view,
        poseTick: _poseTick,
        // Only here in the lobby: who plays without the app (it says
        // nothing about the game, and is never shown at night).
        badges: {for (final id in session.inBrowser) id: l10n.inBrowser},
        selected: swapFrom,
        onTap: session.isOwner ? _tapSeat : null,
      ),
    ];
    // What the table will play; the host can change it.
    final game = [
      Panel(
        child: Column(
          children: [
            Stamp(l10n.settingsName(settings), size: 17),
            const SizedBox(height: 10),
            if (roles != null)
              Body(rolesLine(roles))
            else if (count >= minPlayers)
              Body(l10n.tooManyRoles(count), muted: true),
            // Everyone sees live what the host sets up.
            const SizedBox(height: 8),
            Body(
              settings.nightMode == NightMode.called
                  ? l10n.lobbyNightCalled
                  : l10n.lobbyNightTogether,
              muted: true,
            ),
            if ([
                  if (settings.narratorVoice) l10n.extraVoice,
                  if (settings.sheepInPlay) l10n.extraSheep,
                  if (settings.doorSignsInPlay) l10n.extraDoorSigns,
                  if (settings.atmosphere) l10n.extraAtmosphere,
                  if (settings.ghosts != GhostSight.off) l10n.extraGhosts,
                  if (settings.tieRule == TieRule.runoff) l10n.extraRunoff,
                ]
                case final extras when extras.isNotEmpty)
              Body(l10n.lobbyExtras(extras.join(', ')), muted: true),
          ],
        ),
      ),
      if (session.isOwner) ...[
        if (count < recommendedMinPlayers)
          Body(l10n.fewPlayersHint, muted: true),
        if (count < minPlayers) Body(l10n.needPlayers(minPlayers), muted: true),
      ] else
        Body(l10n.waitingForOwner, muted: true),
    ];
    if (!StageLayout.of(context).twoColumns) {
      // Pages to swipe instead of one long scroll (task 012).
      Widget page(List<Widget> children) => Column(
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) const SizedBox(height: 14),
            child,
          ],
        ],
      );
      return StagePages(
        action: action,
        // The host opens on the table with the invitation; a guest on
        // their figure.
        initialPage: session.isOwner ? 1 : 0,
        pages: [
          (
            label: l10n.pageFigure,
            // The figures need room to be tapped: this page scrolls.
            child: ScrollingPage(
              child: page([...pending, _FigureStage(session: session)]),
            ),
          ),
          // The invitation first (the host's QR code), then the table, who
          // is there and what will be played, on one page that scrolls.
          (
            label: l10n.pageTable,
            child: ScrollingPage(
              child: page([title, ...pending, ...invite, ...table, ...game]),
            ),
          ),
          // The host sets up the game right here, no sheet to open.
          if (session.isOwner)
            (
              label: l10n.pageSettings,
              child: ScrollingPage(
                child: page([
                  Headline(l10n.settingsTitle, eyebrow: l10n.eyebrowEvening),
                  GameSettingsPanel(session: session),
                ]),
              ),
            ),
        ],
      );
    }
    return PhaseBody(
      action: action,
      children: [
        title,
        ...pending,
        ...invite,
        _PersonaPicker(session: session),
        for (final child in table) Aside(child: child),
        ...game,
        if (session.isOwner) ...[
          Headline(l10n.settingsTitle),
          GameSettingsPanel(session: session),
        ],
      ],
    );
  }
}

/// Someone joined without the QR code: compare the symbols, then decide.
class _PendingPanel extends StatelessWidget {
  const _PendingPanel({required this.session, required this.join});

  final GameSession session;
  final PendingJoin join;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Panel(
      highlight: true,
      child: Column(
        children: [
          Headline(l10n.wantsToJoin(join.name)),
          const SizedBox(height: 8),
          Body(l10n.compareSymbols),
          const SizedBox(height: 12),
          CheckCode(code: join.checkCode, size: 32),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: l10n.refuse,
                  onPressed: () =>
                      session.send(AdmitIntent(join.id, admit: false)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: l10n.letIn,
                  onPressed: () =>
                      session.send(AdmitIntent(join.id, admit: true)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Your own figure in the lobby, and the sheet to pick another one.
/// The lobby's first page on a phone (task 012): your figure big on the
/// stage, and every figure as a portrait to tap. Taken ones are greyed out
/// with their player's name; a tap picks at once and your figure turns
/// round into the new one.
class _FigureStage extends StatefulWidget {
  const _FigureStage({required this.session});

  final GameSession session;

  @override
  State<_FigureStage> createState() => _FigureStageState();
}

class _FigureStageState extends State<_FigureStage>
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
  void didUpdateWidget(_FigureStage old) {
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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
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

class _PersonaPicker extends StatelessWidget {
  const _PersonaPicker({required this.session});

  final GameSession session;

  Future<void> _pick(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final view = session.view!;
    // Who stands as which figure already.
    final taken = {
      for (final s in view.seats)
        if (s.id != view.you) s.persona: s.name,
    };
    final allTaken = taken.length >= Persona.values.length;
    final picked = await showModalBottomSheet<Persona>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            children: [
              Headline(l10n.changePersona, eyebrow: l10n.eyebrowEvening),
              const SizedBox(height: 6),
              Body(l10n.personaHint, muted: true),
              const SizedBox(height: 16),
              // The shelf of figures (task 012).
              Wrap(
                spacing: 6,
                runSpacing: 18,
                alignment: WrapAlignment.center,
                children: [
                  for (final p in Persona.values)
                    _PersonaChoice(
                      persona: p,
                      selected: p == view.yourSeat.persona,
                      takenBy: allTaken ? null : taken[p],
                      onTap: () => Navigator.pop(context, p),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) session.send(PersonaIntent(picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final persona = session.view!.yourSeat.persona;
    return Panel(
      child: Row(
        children: [
          TurningFigure(asset: personaAsset(persona), height: 96),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.youAppearAs,
                  style: const TextStyle(color: Palette.moon200),
                ),
                Text(
                  l10n.persona(persona),
                  style: const TextStyle(
                    fontFamily: displayFont,
                    fontSize: 26,
                    color: Palette.moon100,
                  ),
                ),
                const SizedBox(height: 6),
                SecondaryButton(
                  label: l10n.changePersona,
                  expand: false,
                  onPressed: () => _pick(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One figure on the shelf, standing on its little wooden stand: lit when
/// it is yours, in shadow with its player's name when someone else has it.
class _PersonaChoice extends StatelessWidget {
  const _PersonaChoice({
    required this.persona,
    required this.selected,
    required this.onTap,
    this.takenBy,
  });

  final Persona persona;
  final bool selected;
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
    Widget figure = Figure(asset: personaAsset(persona), height: 104);
    if (!free) figure = ColorFiltered(colorFilter: _shadow, child: figure);
    return Semantics(
      button: free,
      selected: selected,
      label: [l10n.persona(persona), ?takenBy].join(', '),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: free ? onTap : null,
        child: SizedBox(
          width: 100,
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  if (selected)
                    // The spotlight on your own figure.
                    Positioned(
                      bottom: -6,
                      child: Container(
                        width: 120,
                        height: 130,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0, 0.4),
                            colors: [
                              Palette.stageLanternTop.withValues(alpha: 0.5),
                              Palette.stageLanternTop.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: figure,
                  ),
                  // The wooden stand.
                  Container(
                    width: 70,
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(
                        Radius.elliptical(35, 6),
                      ),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF8A5A34), Color(0xFF4A2E18)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    const Positioned(
                      right: 6,
                      top: 0,
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Palette.stageLanternTop,
                        size: 24,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                l10n.persona(persona),
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontFamily: displayFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: free ? Palette.stageIvory : Palette.stageIvorySoft,
                ),
              ),
              if (takenBy case final name?)
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
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

class _Invite extends StatefulWidget {
  const _Invite({
    required this.link,
    required this.qr,
    this.browserCanJoin = false,
    this.onShowCode,
    this.onLocalCode,
  });

  final JoinLink link;
  final String qr;
  final bool browserCanJoin;
  final Future<void> Function()? onShowCode;
  final VoidCallback? onLocalCode;

  @override
  State<_Invite> createState() => _InviteState();
}

class _InviteState extends State<_Invite> {
  bool _opening = false;

  Future<void> _show() async {
    setState(() => _opening = true);
    try {
      await widget.onShowCode!();
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final link = widget.link;
    final qr = widget.qr;
    final local = widget.onLocalCode;
    final localButton = local == null
        ? null
        : TextButton(
            onPressed: local,
            child: Text(
              l10n.inviteLocalCode,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Palette.inkSoft, fontSize: 13),
            ),
          );
    if (widget.onShowCode != null) {
      // Players on the same Wi-Fi find the room by themselves; the code
      // (and with it the server) only when someone needs it.
      return Panel(
        paper: true,
        child: Column(
          children: [
            Headline(l10n.inviteTitle),
            const SizedBox(height: 8),
            Body(l10n.inviteWifiFirst),
            const SizedBox(height: 14),
            SecondaryButton(
              label: l10n.inviteShowCode,
              onPressed: _opening ? null : _show,
            ),
            ?localButton,
          ],
        ),
      );
    }
    return Panel(
      paper: true,
      child: Column(
        children: [
          Headline(l10n.inviteTitle),
          const SizedBox(height: 8),
          Body(widget.browserCanJoin ? l10n.inviteHintWeb : l10n.inviteHint),
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(Radii.s),
              border: Border.all(color: Palette.inkSoft, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: QrImageView(
                data: qr,
                size: 210,
                semanticsLabel: l10n.inviteHint,
              ),
            ),
          ),
          // The technical bits only for those who want them.
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: Material(
              type: MaterialType.transparency,
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                iconColor: Palette.inkSoft,
                collapsedIconColor: Palette.inkSoft,
                title: Text(
                  l10n.connectionDetails,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Palette.inkSoft, fontSize: 13),
                ),
                children: [
                  Wrap(
                    spacing: 24,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      _SmallLabel(l10n.roomCode, link.room),
                      if (link.lan != null)
                        _SmallLabel(l10n.hostAddress, link.lan.toString()),
                      if (link.relayRoom != null)
                        _SmallLabel(l10n.onlineCode, link.relayRoom!),
                    ],
                  ),
                  if (!qr.startsWith('http:')) ?localButton,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallLabel extends StatelessWidget {
  const _SmallLabel(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, style: const TextStyle(color: Palette.inkSoft, fontSize: 12)),
      SelectableText(
        value,
        style: const TextStyle(
          color: Palette.ink,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class RevealPhase extends StatefulWidget {
  const RevealPhase({
    required this.session,
    this.listening = false,
    this.onSkip,
    super.key,
  });

  final GameSession session;

  /// The narrator is telling the intro: the roles wait until it ends.
  final bool listening;

  /// For the room owner: cut the intro short.
  final VoidCallback? onSkip;

  @override
  State<RevealPhase> createState() => _RevealPhaseState();
}

class _RevealPhaseState extends State<RevealPhase> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final view = widget.session.view!;
    final role = view.yourRole!;
    final listening = widget.listening;
    if (listening) _shown = false;
    final wolf = role.faction == Faction.werewolves;
    final mates = [
      for (final s in view.seats)
        if (s.id != view.you && s.role == Role.werewolf) s.name,
    ];
    final color = wolf ? Palette.curtain400 : Palette.stageLanternTop;
    final wide = StageLayout.of(context).twoColumns;
    void turn() {
      SoundScope.play(context, Sound.turn);
      setState(() => _shown = !_shown);
    }

    final figure = TurningFigure(
      asset: personaRoleAsset(view.yourSeat.persona, role),
      backAsset: personaAsset(view.yourSeat.persona),
      showBack: !_shown,
      height: figureHeight(context, phone: 240, share: 0.36, wideShare: 0.7),
    );
    final text = AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: listening
          ? Padding(
              key: const ValueKey('intro'),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Body(l10n.introListening),
            )
          : _shown
          ? Column(
              key: const ValueKey('shown'),
              children: [
                Headline(l10n.role(role), color: color),
                const SizedBox(height: 6),
                Stamp(l10n.faction(role.faction), color: color),
                const SizedBox(height: 12),
                Body(l10n.roleText(role)),
                if (mates.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Body(l10n.pack(mates.join(', '))),
                ],
              ],
            )
          : Padding(
              key: const ValueKey('hidden'),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Body(l10n.revealTap),
            ),
    );
    // Your persona stands with its back to the table (grey board, so
    // onlookers learn nothing); a tap turns it around in your role's
    // costume. Wide windows give the figure a column of its own.
    Widget tappable(Widget child) => listening
        ? child
        : Semantics(
            button: true,
            label: _shown ? l10n.role(role) : l10n.revealTap,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: turn,
              child: child,
            ),
          );
    // The figure stands on the theatre's stage (task 012); what it is
    // shows on a plaque below it.
    final plaque = Panel(
      highlight: _shown,
      child: SizedBox(width: double.infinity, child: text),
    );
    return PhaseBody(
      action: listening
          ? (widget.onSkip == null
                ? null
                : SecondaryButton(
                    label: l10n.introSkip,
                    icon: Icons.skip_next_rounded,
                    onPressed: widget.onSkip,
                  ))
          : !view.youConfirmed
          ? PrimaryButton(
              label: l10n.confirmRole,
              icon: Icons.check_rounded,
              onPressed: _shown
                  ? () => widget.session.send(const ConfirmRoleIntent())
                  : null,
            )
          : null,
      children: [
        if (listening)
          Headline(l10n.introTitle, eyebrow: l10n.eyebrowNarrator)
        else
          Headline(l10n.revealTitle, eyebrow: l10n.eyebrowYourRole),
        if (wide) ...[
          plaque,
          Aside(child: tappable(Center(child: figure))),
        ] else ...[
          tappable(Center(child: figure)),
          plaque,
        ],
        if (!listening && view.youConfirmed)
          Body(l10n.waitingFor(view.waitingFor), muted: true),
      ],
    );
  }
}

/// What happened since the last screen: every death with its cause and,
/// if roles are revealed, the role. Read out on paper in the morning; at
/// night the stage stays dark.
class LastNews extends StatelessWidget {
  const LastNews({required this.view, super.key});

  final PlayerView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final phase = view.phase;
    if (phase == Phase.night && view.round <= 1) return const SizedBox.shrink();
    final deaths = freshDeaths(view);
    final nobody = switch (phase) {
      Phase.day => l10n.nobodyDied,
      Phase.night => l10n.nobodyEliminated,
      _ => null,
    };
    if (deaths.isEmpty && nobody == null) return const SizedBox.shrink();
    return Panel(
      paper: phase == Phase.day,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            if (deaths.isEmpty) Body(nobody!),
            for (final (i, d) in deaths.indexed) ...[
              if (i > 0) const SizedBox(height: 8),
              Body(l10n.death(view, d)),
              if (d.role != null)
                Body(l10n.roleWas(l10n.role(d.role!)), muted: true),
            ],
          ],
        ),
      ),
    );
  }
}

/// For the lovers (and cupid): who belongs to whom. Nobody else sees it.
class CoupleNote extends StatelessWidget {
  const CoupleNote({required this.view, super.key});

  final PlayerView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final partner = view.partner;
    final couple = view.couple;
    final String text;
    if (partner != null) {
      text = l10n.inLove(view.nameOf(partner));
    } else if (couple.length == 2 && view.yourRole == Role.cupid) {
      text = l10n.yourCouple(view.nameOf(couple[0]), view.nameOf(couple[1]));
    } else {
      return const SizedBox.shrink();
    }
    return Panel(
      child: Row(
        children: [
          const Icon(Icons.favorite_rounded, color: Palette.curtain400),
          const SizedBox(width: 12),
          Expanded(child: Body(text)),
        ],
      ),
    );
  }
}

class DayPhase extends StatelessWidget {
  const DayPhase({required this.session, super.key});

  final GameSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final view = session.view!;
    final sheep = view.settings.sheepInPlay && view.lastNightSheep.isNotEmpty;
    return PhaseBody(
      action: session.isOwner
          ? PrimaryButton(
              label: l10n.startVote,
              onPressed: () => session.send(const EndDiscussionIntent()),
            )
          : null,
      children: [
        Headline(
          l10n.dayTalkTitle,
          eyebrow: l10n.eyebrowDay('${view.round}'),
        ),
        LastNews(view: view),
        CoupleNote(view: view),
        if (!view.yourSeat.isAlive) GhostPanel(view: view),
        Body(l10n.discuss),
        Countdown(endsAt: session.phaseEndsAt),
        if (sheep) Aside(child: Headline(l10n.sleepTitle, size: 28)),
        Aside(
          child: TableCircle(
            view: view,
            badges: {
              if (sheep)
                for (final MapEntry(:key, :value)
                    in view.lastNightSheep.entries)
                  key: l10n.sheepCount(value),
            },
          ),
        ),
        if (!session.isOwner) Body(l10n.ownerStartsVote, muted: true),
      ],
    );
  }
}

/// The hunter has fallen: he picks whom to take along, everyone else
/// waits for the shot.
class HunterPhase extends StatelessWidget {
  const HunterPhase({required this.session, super.key});

  final GameSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final view = session.view!;
    final shooter = view.shooter;
    final yours = shooter == view.you;
    return PhaseBody(
      action: yours
          ? SecondaryButton(
              label: l10n.hunterSpare,
              icon: Icons.front_hand_rounded,
              onPressed: () => session.send(const ShootIntent(null)),
            )
          : null,
      children: [
        Aside(
          child: TurningFigure(
            asset: shooter == null
                ? figureAsset(Role.hunter)
                : personaRoleAsset(
                    view.seats.firstWhere((s) => s.id == shooter).persona,
                    Role.hunter,
                  ),
            height: figureHeight(context, phone: 180),
          ),
        ),
        Headline(
          yours ? l10n.hunterQuestion : l10n.roleHunter,
          eyebrow: l10n.eyebrowLastShot,
        ),
        LastNews(view: view),
        Body(
          yours
              ? l10n.hunterYou
              : l10n.hunterWait(shooter == null ? '?' : view.nameOf(shooter)),
        ),
        Countdown(endsAt: session.phaseEndsAt),
        if (yours)
          SeatGrid(
            view: view,
            onTap: (seat) => session.send(ShootIntent(seat.id)),
          ),
      ],
    );
  }
}

class VotePhase extends StatelessWidget {
  const VotePhase({required this.session, super.key});

  final GameSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final view = session.view!;
    final vote = view.yourVote;
    final runoff = view.runoff.isNotEmpty;
    return PhaseBody(
      action: view.yourSeat.isAlive
          ? SecondaryButton(
              label: l10n.abstain,
              selected: view.youVoted && vote == null,
              onPressed: () => session.send(const VoteIntent(null)),
            )
          : null,
      children: [
        if (runoff)
          Headline(l10n.runoffTitle, eyebrow: l10n.eyebrowTie)
        else
          Headline(l10n.voteQuestion, eyebrow: l10n.eyebrowVote),
        CoupleNote(view: view),
        if (!view.yourSeat.isAlive)
          GhostPanel(view: view)
        else ...[
          Body(
            runoff
                ? l10n.runoffPrompt(view.runoff.map(view.nameOf).join(', '))
                : l10n.votePrompt,
          ),
          Countdown(endsAt: session.phaseEndsAt),
          Aside(
            child: SeatGrid(
              view: view,
              selected: vote,
              // In a runoff only the tied can be chosen.
              enabled: runoff
                  ? (seat) =>
                        view.runoff.contains(seat.id) && seat.id != view.you
                  : null,
              onTap: (seat) {
                SoundScope.play(context, Sound.ballot);
                session.send(VoteIntent(seat.id));
              },
            ),
          ),
          if (view.youVoted)
            Body(
              vote == null ? l10n.abstained : l10n.votedFor(view.nameOf(vote)),
            ),
        ],
        Body(l10n.waitingFor(view.waitingFor), muted: true),
      ],
    );
  }
}

class EndedPhase extends StatelessWidget {
  const EndedPhase({required this.session, required this.onLeave, super.key});

  final GameSession session;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final view = session.view!;
    final (figure, color) = switch (view.winner) {
      Faction.werewolves => (Role.werewolf, Palette.curtain400),
      Faction.lovers => (Role.cupid, Palette.curtain400),
      Faction.village || null => (Role.villager, Palette.lantern400),
    };
    return PhaseBody(
      action: session.isOwner
          ? PrimaryButton(
              label: l10n.playAgain,
              icon: Icons.replay_rounded,
              onPressed: () => session.send(const RematchIntent()),
            )
          : null,
      children: [
        Headline(
          l10n.winner(view.winner),
          color: color,
          eyebrow: l10n.eyebrowEnd,
        ),
        RoleFigure(
          role: figure,
          height: figureHeight(context, phone: 200, wideShare: 0.36),
        ),
        LastNews(view: view),
        if (_bestDreamer(view) case (final name, final points))
          Panel(paper: true, child: Body(l10n.bestDreamer(name, points))),
        Aside(child: Body(l10n.everyRole)),
        // The curtain call (task 012): everyone in their role's costume.
        Aside(
          child: _CurtainCall(
            view: view,
            badges: {
              for (final MapEntry(:key, :value) in view.dreams.entries)
                if (view.settings.sheepInPlay) key: l10n.dreamPoints(value),
            },
          ),
        ),
        TextButton(onPressed: onLeave, child: Text(l10n.leave)),
      ],
    );
  }
}

/// Everyone takes a bow in the costume of the role they played, the name
/// and the role on a small plaque at their feet.
class _CurtainCall extends StatelessWidget {
  const _CurtainCall({required this.view, this.badges = const {}});

  final PlayerView view;
  final Map<PlayerId, String> badges;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final height = StageLayout.of(context).roomy ? 170.0 : 128.0;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 14,
      children: [
        for (final seat in view.seats)
          SizedBox(
            width: height * 0.72,
            child: Column(
              children: [
                SizedBox(
                  height: height,
                  child: Image.asset(
                    seat.role == null
                        ? personaAsset(seat.persona)
                        : personaRoleAsset(seat.persona, seat.role!),
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
                const SizedBox(height: 4),
                DecoratedBox(
                  decoration: const PlaqueDecoration(radius: 10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    child: Column(
                      children: [
                        Text(
                          seat.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: displayFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: seat.id == view.you
                                ? Palette.stageLanternTop
                                : Palette.stageIvory,
                          ),
                        ),
                        Text(
                          [
                            if (seat.role case final role?) l10n.role(role),
                            ?badges[seat.id],
                          ].join(' · '),
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10.5,
                            height: 1.2,
                            color: Palette.stageIvorySoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The player with the most dream points, if anyone counted at all.
(String, int)? _bestDreamer(PlayerView view) {
  if (!view.settings.sheepInPlay) return null;
  final best = view.dreams.entries
      .where((e) => e.value > 0)
      .fold<MapEntry<PlayerId, int>?>(
        null,
        (top, e) => top == null || e.value > top.value ? e : top,
      );
  return best == null ? null : (view.nameOf(best.key), best.value);
}
