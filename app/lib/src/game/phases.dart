import 'dart:async';

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:protocol/protocol.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/check_code.dart';
import 'package:whowolf/src/game/figures.dart';
import 'package:whowolf/src/game/help.dart';
import 'package:whowolf/src/game/news.dart';
import 'package:whowolf/src/game/settings_sheet.dart';
import 'package:whowolf/src/game/table_circle.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/net/game_session.dart';
import 'package:whowolf/src/theme.dart';

/// Shared scaffold of every phase: scrollable column, max width.
class PhaseBody extends StatelessWidget {
  const PhaseBody({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          children: [
            for (final child in children) ...[
              child,
              const SizedBox(height: 18),
            ],
          ],
        ),
      ),
    ),
  );
}

class LobbyPhase extends StatefulWidget {
  const LobbyPhase({
    required this.session,
    this.link,
    this.relayFailed = false,
    this.keepAppOpen = false,
    super.key,
  });

  final GameSession session;

  /// How others reach this room (only on the host device).
  final JoinLink? link;
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
      children: [
        for (final p in session.pending)
          _PendingPanel(session: session, join: p),
        if (session.isOwner && link != null) _Invite(link: link),
        if (widget.relayFailed) Body(l10n.relayFailed, muted: true),
        if (session.isOwner && widget.keepAppOpen)
          Body(l10n.keepAppOpenHint, muted: true),
        if (session.isOwner && count < 2) const HelpLink(),
        _PersonaPicker(session: session),
        Headline(l10n.players(count)),
        if (count > 1) Body(l10n.tableHint, muted: true),
        if (swapFrom != null)
          Panel(
            highlight: true,
            child: Body(l10n.swapHint(view.nameOf(swapFrom))),
          ),
        TableCircle(
          view: view,
          selected: swapFrom,
          onTap: session.isOwner ? _tapSeat : null,
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
          PrimaryButton(
            label: l10n.startGame,
            onPressed: canStart
                ? () => session.send(const StartGameIntent())
                : null,
          ),
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
          Figure(asset: personaAsset(persona), height: 96),
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
                if (session.view!.settings.personaChoice) ...[
                  const SizedBox(height: 6),
                  SecondaryButton(
                    label: l10n.changePersona,
                    expand: false,
                    onPressed: () => _pick(context),
                  ),
                ],
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
  const _Invite({required this.link});

  final JoinLink link;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Panel(
      paper: true,
      child: Column(
        children: [
          Headline(l10n.inviteTitle),
          const SizedBox(height: 8),
          Body(l10n.inviteHint),
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
                data: link.encode(),
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
  const RevealPhase({required this.session, super.key});

  final GameSession session;

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
    final wolf = role.faction == Faction.werewolves;
    final mates = [
      for (final s in view.seats)
        if (s.id != view.you && s.role == Role.werewolf) s.name,
    ];
    return PhaseBody(
      children: [
        Headline(l10n.revealTitle),
        // Your persona stands with its back to the table (grey board, so
        // onlookers learn nothing); a tap turns it into your role.
        Semantics(
          button: true,
          label: _shown ? l10n.role(role) : l10n.revealTap,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _shown = !_shown),
            child: Panel(
              paper: true,
              highlight: _shown,
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    TurningFigure(
                      asset: figureAsset(role),
                      backAsset: personaAsset(view.yourSeat.persona),
                      showBack: !_shown,
                      height: 240,
                    ),
                    const SizedBox(height: 14),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _shown
                          ? Column(
                              key: const ValueKey('shown'),
                              children: [
                                Headline(
                                  l10n.role(role),
                                  color: wolf
                                      ? Palette.curtain600
                                      : Palette.forest700,
                                ),
                                const SizedBox(height: 6),
                                Stamp(
                                  l10n.faction(role.faction),
                                  color: wolf
                                      ? Palette.curtain600
                                      : Palette.forest700,
                                ),
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (!view.youConfirmed)
          PrimaryButton(
            label: l10n.confirmRole,
            onPressed: _shown
                ? () => widget.session.send(const ConfirmRoleIntent())
                : null,
          )
        else
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
    final sheep = view.settings.sheepCounting && view.lastNightSheep.isNotEmpty;
    return PhaseBody(
      children: [
        Headline(l10n.dayTitle(view.round)),
        LastNews(view: view),
        CoupleNote(view: view),
        if (!view.yourSeat.isAlive) Body(l10n.youAreDead),
        Body(l10n.discuss),
        Countdown(endsAt: session.phaseEndsAt),
        if (sheep) Headline(l10n.sleepTitle, size: 28),
        TableCircle(
          view: view,
          badges: {
            if (sheep)
              for (final MapEntry(:key, :value) in view.lastNightSheep.entries)
                key: l10n.sheepCount(value),
          },
        ),
        if (session.isOwner)
          PrimaryButton(
            label: l10n.startVote,
            onPressed: () => session.send(const EndDiscussionIntent()),
          )
        else
          Body(l10n.ownerStartsVote, muted: true),
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
      children: [
        const TurningFigure(asset: 'assets/figures/jaeger.webp', height: 180),
        Headline(l10n.roleHunter),
        LastNews(view: view),
        Body(
          yours
              ? l10n.hunterYou
              : l10n.hunterWait(shooter == null ? '?' : view.nameOf(shooter)),
        ),
        Countdown(endsAt: session.phaseEndsAt),
        if (yours) ...[
          SeatGrid(
            view: view,
            onTap: (seat) => session.send(ShootIntent(seat.id)),
          ),
          SecondaryButton(
            label: l10n.hunterSpare,
            expand: false,
            onPressed: () => session.send(const ShootIntent(null)),
          ),
        ],
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
    return PhaseBody(
      children: [
        Headline(l10n.voteTitle),
        CoupleNote(view: view),
        if (!view.yourSeat.isAlive)
          Body(l10n.youAreDead)
        else ...[
          Body(l10n.votePrompt),
          Countdown(endsAt: session.phaseEndsAt),
          SeatGrid(
            view: view,
            selected: vote,
            onTap: (seat) => session.send(VoteIntent(seat.id)),
          ),
          SecondaryButton(
            label: l10n.abstain,
            expand: false,
            selected: view.youVoted && vote == null,
            onPressed: () => session.send(const VoteIntent(null)),
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
      children: [
        RoleFigure(role: figure, height: 200),
        Headline(l10n.winner(view.winner), color: color),
        LastNews(view: view),
        if (_bestDreamer(view) case (final name, final points))
          Panel(paper: true, child: Body(l10n.bestDreamer(name, points))),
        Body(l10n.everyRole),
        SeatGrid(
          view: view,
          badges: {
            for (final MapEntry(:key, :value) in view.dreams.entries)
              if (view.settings.sheepCounting) key: l10n.dreamPoints(value),
          },
        ),
        if (session.isOwner)
          PrimaryButton(
            label: l10n.playAgain,
            onPressed: () => session.send(const RematchIntent()),
          ),
        TextButton(onPressed: onLeave, child: Text(l10n.leave)),
      ],
    );
  }
}

/// The player with the most dream points, if anyone counted at all.
(String, int)? _bestDreamer(PlayerView view) {
  if (!view.settings.sheepCounting) return null;
  final best = view.dreams.entries
      .where((e) => e.value > 0)
      .fold<MapEntry<PlayerId, int>?>(
        null,
        (top, e) => top == null || e.value > top.value ? e : top,
      );
  return best == null ? null : (view.nameOf(best.key), best.value);
}
