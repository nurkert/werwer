import 'dart:async';

import 'package:flutter/material.dart';
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
    this.relayFailed = false,
    this.keepAppOpen = false,
    super.key,
  });

  final GameSession session;

  /// How others reach this room (only on the host device).
  final JoinLink? link;

  /// The QR code's text (see `HostedRoom.qrText`).
  final String? qr;
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
      backgroundColor: Palette.night800,
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
    return PhaseBody(
      action: session.isOwner
          ? PrimaryButton(
              label: l10n.startGame,
              onPressed: canStart
                  ? () => session.send(const StartGameIntent())
                  : null,
            )
          : null,
      children: [
        Headline(l10n.lobbyTitle, eyebrow: l10n.eyebrowEvening),
        for (final p in session.pending)
          _PendingPanel(session: session, join: p),
        if (session.isOwner && link != null)
          _Invite(link: link, qr: widget.qr ?? link.encode()),
        if (widget.relayFailed) Body(l10n.relayFailed, muted: true),
        if (session.isOwner && widget.keepAppOpen)
          Body(l10n.keepAppOpenHint, muted: true),
        if (session.isOwner && count < 2) const HelpLink(),
        _PersonaPicker(session: session),
        Aside(child: Headline(l10n.players(count))),
        if (count > 1) Aside(child: Body(l10n.tableHint, muted: true)),
        if (swapFrom != null)
          Aside(
            child: Panel(
              highlight: true,
              child: Body(l10n.swapHint(view.nameOf(swapFrom))),
            ),
          ),
        Aside(
          child: TableCircle(
            view: view,
            poseTick: _poseTick,
            selected: swapFrom,
            onTap: session.isOwner ? _tapSeat : null,
          ),
        ),
        // What the table will play; the host can change it.
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
              if (session.isOwner) ...[
                const SizedBox(height: 12),
                SecondaryButton(
                  label: l10n.settingsButton,
                  expand: false,
                  onPressed: () => showSettingsSheet(context, session),
                ),
              ],
            ],
          ),
        ),
        if (session.isOwner) ...[
          if (count < recommendedMinPlayers)
            Body(l10n.fewPlayersHint, muted: true),
          if (count < minPlayers)
            Body(l10n.needPlayers(minPlayers), muted: true),
        ] else
          Body(l10n.waitingForOwner, muted: true),
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
class _PersonaPicker extends StatelessWidget {
  const _PersonaPicker({required this.session});

  final GameSession session;

  Future<void> _pick(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final view = session.view!;
    final taken = {
      for (final s in view.seats)
        if (s.id != view.you) s.persona,
    };
    final allTaken = taken.length >= Persona.values.length;
    final picked = await showModalBottomSheet<Persona>(
      context: context,
      backgroundColor: Palette.night800,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            children: [
              Headline(l10n.changePersona),
              const SizedBox(height: 6),
              Body(l10n.personaHint, muted: true),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  for (final p in Persona.values)
                    _PersonaChoice(
                      persona: p,
                      selected: p == view.yourSeat.persona,
                      enabled: allTaken || !taken.contains(p),
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

class _PersonaChoice extends StatelessWidget {
  const _PersonaChoice({
    required this.persona,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final Persona persona;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: Material(
        color: selected ? Palette.night700 : Palette.night900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? Palette.lantern400 : Palette.night700,
            width: selected ? 2.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? onTap : null,
          child: SizedBox(
            width: 104,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  Figure(asset: personaAsset(persona), height: 90),
                  const SizedBox(height: 6),
                  Text(
                    l10n.persona(persona),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Palette.moon100,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Invite extends StatelessWidget {
  const _Invite({required this.link, required this.qr});

  final JoinLink link;
  final String qr;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Panel(
      paper: true,
      child: Column(
        children: [
          Headline(l10n.inviteTitle),
          const SizedBox(height: 8),
          Body(qr.startsWith('http:') ? l10n.inviteHintWeb : l10n.inviteHint),
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
