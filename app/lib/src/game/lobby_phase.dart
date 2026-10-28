import 'dart:async';

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:protocol/protocol.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/check_code.dart';
import 'package:whowolf/src/game/figures.dart';
import 'package:whowolf/src/game/help.dart';
import 'package:whowolf/src/game/lobby_figures.dart';
import 'package:whowolf/src/game/lobby_invite.dart';
import 'package:whowolf/src/game/settings_sheet.dart';
import 'package:whowolf/src/game/table_circle.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/layout.dart';
import 'package:whowolf/src/net/game_session.dart';
import 'package:whowolf/src/stage/motion.dart';
import 'package:whowolf/src/stage/stage_pages.dart';
import 'package:whowolf/src/theme.dart';

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
      if (mounted && StageMotionScope.idles(context)) {
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
    final fitted = settings.fittedFor(count);
    final roles = count >= minPlayers ? fitted.rolesFor(count) : null;
    final dropped = count >= minPlayers
        ? settings.droppedFor(count)
        : const <Role>{};
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
        LobbyInvite(
          link: link,
          qr: widget.qr ?? link.encode(),
          browserCanJoin: widget.browserCanJoin,
          onShowCode: widget.onShowCode,
          onLocalCode: widget.onLocalCode,
          // The door code only beside the server's QR code (not for the
          // Wi-Fi code of a game without internet).
          doorPage: session.hosted?.localOnly ?? true
              ? null
              : session.hosted?.doorPage,
          doorCode: session.hosted?.doorCode,
          doorCodes: session.hosted?.doorCodes,
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
            if (roles != null) ...[
              Body(rolesLine(roles)),
              // The host asked for more than this table holds: said, not
              // refused (the roles come back when more people sit down).
              if (dropped.isNotEmpty ||
                  fitted.werewolves != settings.werewolves)
                Body(
                  l10n.rolesFitted(
                    count,
                    [for (final r in dropped) l10n.role(r)].join(', '),
                  ),
                  muted: true,
                ),
            ] else if (count >= minPlayers)
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
              child: page([...pending, LobbyFigureStage(session: session)]),
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
    // On a computer: the same pages, wide, turned with arrows or the keys
    // (no long column to scroll). The table page holds the invitation and
    // what will be played next to the table itself.
    Widget column(List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, child) in children.indexed) ...[
          if (i > 0) const SizedBox(height: 16),
          child,
        ],
      ],
    );
    return StagePages(
      action: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: action ?? const SizedBox.shrink(),
        ),
      ),
      arrows: true,
      maxWidth: 1040,
      initialPage: 1,
      pages: [
        (
          label: l10n.pageFigure,
          child: ScrollingPage(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: column([...pending, LobbyFigureStage(session: session)]),
              ),
            ),
          ),
        ),
        (
          label: l10n.pageTable,
          child: ScrollingPage(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: column([title, ...pending, ...invite, ...game]),
                ),
                const SizedBox(width: 32),
                Expanded(flex: 5, child: column(table)),
              ],
            ),
          ),
        ),
        if (session.isOwner)
          (
            label: l10n.pageSettings,
            child: ScrollingPage(
              child: column([
                Headline(l10n.settingsTitle, eyebrow: l10n.eyebrowEvening),
                GameSettingsPanel(session: session),
              ]),
            ),
          ),
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
