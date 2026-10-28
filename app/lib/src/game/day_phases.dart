import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:protocol/protocol.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/atmosphere.dart';
import 'package:whowolf/src/game/chronicle.dart';
import 'package:whowolf/src/game/figures.dart';
import 'package:whowolf/src/game/ghost_sight.dart';
import 'package:whowolf/src/game/phase_body.dart';
import 'package:whowolf/src/game/reveal_phase.dart';
import 'package:whowolf/src/game/table_circle.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/layout.dart';
import 'package:whowolf/src/net/game_session.dart';
import 'package:whowolf/src/theme.dart';

class DayPhase extends StatelessWidget {
  const DayPhase({required this.session, super.key});

  final GameSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final view = session.view!;
    final sheep = view.settings.sheepInPlay && view.lastNightSheep.isNotEmpty;
    final yesterday = view.settings.openVotes
        ? votesOf(view, view.round - 1)
        : const <PlayerId, PlayerId?>{};
    final ready = session.ready;
    final alive = view.seats.where((s) => s.isAlive).length;
    final imReady = ready.contains(view.you);
    final voteSoon = ready.length * 2 > alive;
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
        if (session.paused) const PausedNote(),
        if (voteSoon)
          Panel(highlight: true, child: Body(l10n.voteSoon))
        else if (ready.isNotEmpty)
          Body(l10n.readyCount(ready.length, alive), muted: true),
        if (!view.yourSeat.isAlive) GhostPanel(view: view),
        Body(l10n.discuss),
        Countdown(endsAt: session.phaseEndsAt),
        if (view.yourSeat.isAlive && !voteSoon)
          SecondaryButton(
            label: imReady ? l10n.readyUndo : l10n.readyToVote,
            icon: imReady ? Icons.undo_rounded : Icons.how_to_vote_rounded,
            selected: imReady,
            onPressed: () => session.send(ReadyIntent(ready: !imReady)),
          )
        // During the warning, whoever was ready can still ask to talk on;
        // without a majority the discussion goes on with its time.
        else if (view.yourSeat.isAlive && imReady)
          SecondaryButton(
            label: l10n.readyTalkOn,
            icon: Icons.record_voice_over_rounded,
            onPressed: () => session.send(const ReadyIntent(ready: false)),
          ),
        if (session.isOwner) LeaderBar(session: session, canEnd: false),
        if (sheep) Aside(child: Headline(l10n.sleepTitle, size: 28)),
        Aside(
          child: TableCircle(
            view: view,
            badges: {
              if (sheep)
                for (final MapEntry(:key, :value)
                    in view.lastNightSheep.entries)
                  key: l10n.sheepCount(value),
              // Missing right now (shown by day only).
              for (final id in session.offline) id: l10n.offlineBadge,
            },
          ),
        ),
        // With open voting: how yesterday's vote went, to talk about.
        if (yesterday.isNotEmpty)
          Aside(
            child: VotesPanel(
              view: view,
              votes: yesterday,
              title: l10n.votesYesterday,
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
        if (session.paused) const PausedNote(),
        if (session.isOwner)
          LeaderBar(session: session, canEnd: false, canExtend: false),
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
        if (session.paused) const PausedNote(),
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
              badges: {for (final id in session.offline) id: l10n.offlineBadge},
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
        // Open voting: everyone sees the votes as they come in.
        if (view.openVotes.isNotEmpty)
          Aside(
            child: VotesPanel(
              view: view,
              votes: view.openVotes,
              title: l10n.votesLive,
            ),
          ),
        Body(l10n.waitingFor(view.waitingFor), muted: true),
        if (session.isOwner) LeaderBar(session: session, canEnd: true),
      ],
    );
  }
}

/// The clock stands still: the game leader paused it.
/// "The game leader paused", the same on every screen.
class PausedNote extends StatelessWidget {
  const PausedNote({super.key});

  @override
  Widget build(BuildContext context) => Panel(
    highlight: true,
    child: Row(
      children: [
        const Icon(Icons.pause_circle_rounded, color: Palette.lantern400),
        const SizedBox(width: 10),
        Expanded(child: Body(AppLocalizations.of(context).pausedByLeader)),
      ],
    ),
  );
}

/// The game leader's clock: pause or go on, thirty seconds more, and in
/// the vote end it now.
class LeaderBar extends StatelessWidget {
  const LeaderBar({
    required this.session,
    required this.canEnd,
    this.canExtend = true,
    super.key,
  });

  final GameSession session;
  final bool canEnd;

  /// Thirty seconds more: only for the talk (a night's or a shot's length
  /// must tell nobody anything).
  final bool canExtend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paused = session.paused;
    void send(LeaderAction action) => session.send(LeaderIntent(action));
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 4,
        children: [
          TextButton.icon(
            onPressed: () =>
                send(paused ? LeaderAction.resume : LeaderAction.pause),
            icon: Icon(
              paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            ),
            label: Text(paused ? l10n.leaderResume : l10n.leaderPause),
          ),
          if (canExtend)
            TextButton.icon(
              onPressed: paused ? null : () => send(LeaderAction.extend),
              icon: const Icon(Icons.more_time_rounded),
              label: Text(l10n.leaderExtend),
            ),
          if (canEnd)
            TextButton.icon(
              onPressed: () async {
                // One stray tap must not end everyone's vote.
                final sure = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.leaderEndAsk),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l10n.cancel),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(l10n.leaderEnd),
                      ),
                    ],
                  ),
                );
                if (sure ?? false) send(LeaderAction.end);
              },
              icon: const Icon(Icons.stop_circle_outlined),
              label: Text(l10n.leaderEnd),
            ),
        ],
      ),
    );
  }
}
