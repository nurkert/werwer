import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:protocol/protocol.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:whowolf/l10n/app_localizations.dart';
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

class LobbyPhase extends StatelessWidget {
  const LobbyPhase({
    required this.session,
    this.link,
    this.relayFailed = false,
    super.key,
  });

  final GameSession session;

  /// How others reach this room (only on the host device).
  final JoinLink? link;
  final bool relayFailed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final view = session.view!;
    final count = view.seats.length;
    final canStart = count >= minPlayers && count <= maxPlayers;
    String rolesLine() {
      final roles = suggestRoles(count);
      final tally = <Role, int>{};
      for (final r in roles) {
        tally[r] = (tally[r] ?? 0) + 1;
      }
      return l10n.rolesInGame(
        tally.entries.map((e) => '${e.value}× ${l10n.role(e.key)}').join(', '),
      );
    }

    return PhaseBody(
      children: [
        if (session.isOwner && link != null) _Invite(link: link!),
        if (relayFailed) Body(l10n.relayFailed, muted: true),
        Headline(l10n.players(count)),
        SeatGrid(
          view: view,
          trailing: session.isOwner
              ? (seat) => seat.id == view.you
                    ? null
                    : IconButton(
                        tooltip: l10n.kick,
                        icon: const Icon(Icons.close, size: 18),
                        color: Palette.moon200,
                        onPressed: () => session.send(KickIntent(seat.id)),
                      )
              : null,
        ),
        if (session.isOwner) ...[
          if (canStart) Body(rolesLine()),
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

class _Invite extends StatelessWidget {
  const _Invite({required this.link});

  final JoinLink link;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Panel(
      highlight: true,
      child: Column(
        children: [
          Body(l10n.lobbyJoinHint),
          const SizedBox(height: 12),
          Wrap(
            spacing: 28,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _BigLabel(l10n.roomCode, link.room),
              if (link.lan != null)
                _BigLabel(l10n.hostAddress, link.lan.toString()),
              if (link.relayRoom != null)
                _BigLabel(l10n.onlineCode, link.relayRoom!),
            ],
          ),
          const SizedBox(height: 14),
          Body(l10n.scanHint, muted: true),
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: QrImageView(
                data: link.encode(),
                size: 200,
                semanticsLabel: l10n.scanHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BigLabel extends StatelessWidget {
  const _BigLabel(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, style: const TextStyle(color: Palette.moon200, fontSize: 13)),
      SelectableText(
        value,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: displayFont,
          fontSize: 32,
          letterSpacing: 1.5,
          color: Palette.lantern400,
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
    final mates = [
      for (final s in view.seats)
        if (s.id != view.you && s.role == Role.werewolf) s.name,
    ];
    return PhaseBody(
      children: [
        Headline(l10n.revealTitle),
        GestureDetector(
          onTap: () => setState(() => _shown = !_shown),
          child: Panel(
            highlight: _shown,
            child: SizedBox(
              width: double.infinity,
              height: 220,
              child: Center(
                child: _shown
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Headline(
                            l10n.role(role),
                            color: role.faction == Faction.werewolves
                                ? Palette.curtain400
                                : Palette.lantern400,
                          ),
                          const SizedBox(height: 10),
                          Body(l10n.roleText(role)),
                          if (mates.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Body(l10n.pack(mates.join(', '))),
                          ],
                        ],
                      )
                    : Body(l10n.revealTap),
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

/// What happened since the last screen (night victim or vote result).
class LastNews extends StatelessWidget {
  const LastNews({required this.view, super.key});

  final PlayerView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final night = view.phase == Phase.day;
    final death = view.deaths.where((d) {
      return night
          ? d.cause == DeathCause.night && d.round == view.round
          : d.cause == DeathCause.vote && d.round == view.round - 1;
    }).firstOrNull;
    if (!night && view.round <= 1) return const SizedBox.shrink();
    final String text;
    if (death == null) {
      text = night ? l10n.nobodyDied : l10n.nobodyEliminated;
    } else {
      final name = view.nameOf(death.player);
      text = night ? l10n.killedAtNight(name) : l10n.eliminated(name);
    }
    final role = death?.role;
    return Panel(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Body(text),
            if (role != null) Body(l10n.roleWas(l10n.role(role)), muted: true),
          ],
        ),
      ),
    );
  }
}

class NightPhase extends StatelessWidget {
  const NightPhase({required this.session, super.key});

  final GameSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final view = session.view!;
    final role = view.yourRole!;
    final alive = view.yourSeat.isAlive;
    final prompt = switch (role.nightAbility) {
      NightAbility.hunt => l10n.nightHunt,
      NightAbility.inspect => l10n.nightInspect,
      NightAbility.decoy => l10n.nightDecoy,
    };
    final seen = view.seerResults.where((r) => r.round == view.round);
    final choice = view.yourNightChoice;
    final inspected =
        role.nightAbility == NightAbility.inspect && choice != null;
    return PhaseBody(
      children: [
        Headline(l10n.nightTitle(view.round)),
        LastNews(view: view),
        if (!alive)
          Body(l10n.youAreDead)
        else ...[
          Body(prompt),
          Countdown(endsAt: session.phaseEndsAt),
          SeatGrid(
            view: view,
            selected: choice,
            enabled: (seat) =>
                seat.isAlive &&
                seat.id != view.you &&
                !inspected &&
                !(role == Role.werewolf && seat.role == Role.werewolf),
            badges: {
              for (final MapEntry(:key, :value) in view.packChoices.entries)
                if (key != view.you) value: l10n.packPick(view.nameOf(key)),
            },
            onTap: (seat) => session.send(NightIntent(seat.id)),
          ),
          if (choice != null) Body(l10n.picked(view.nameOf(choice))),
          for (final r in seen)
            Panel(
              highlight: true,
              child: Body(
                l10n.seerSaw(
                  view.nameOf(r.target),
                  r.role != null ? l10n.role(r.role!) : l10n.faction(r.faction),
                ),
              ),
            ),
          Body(l10n.nightHint, muted: true),
        ],
      ],
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
    return PhaseBody(
      children: [
        Headline(l10n.dayTitle(view.round)),
        LastNews(view: view),
        if (!view.yourSeat.isAlive) Body(l10n.youAreDead),
        Body(l10n.discuss),
        Countdown(endsAt: session.phaseEndsAt),
        SeatGrid(view: view),
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
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Palette.moon100,
              side: BorderSide(
                color: view.youVoted && vote == null
                    ? Palette.lantern400
                    : Palette.night700,
                width: 2,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            ),
            onPressed: () => session.send(const VoteIntent(null)),
            child: Text(l10n.abstain),
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
    final villageWon = view.winner == Faction.village;
    return PhaseBody(
      children: [
        Headline(
          villageWon ? l10n.villageWins : l10n.werewolvesWin,
          color: villageWon ? Palette.lantern400 : Palette.curtain400,
        ),
        Body(l10n.everyRole),
        SeatGrid(view: view),
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
