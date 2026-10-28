import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:protocol/protocol.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/atmosphere.dart';
import 'package:whowolf/src/game/figures.dart';
import 'package:whowolf/src/game/news.dart';
import 'package:whowolf/src/game/phase_body.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/layout.dart';
import 'package:whowolf/src/net/game_session.dart';
import 'package:whowolf/src/stage/tappable.dart';
import 'package:whowolf/src/theme.dart';

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
    final mates = [
      for (final s in view.seats)
        if (s.id != view.you && s.role == Role.werewolf) s.name,
    ];
    // The same colour for every role: red for the werewolves would show
    // across the table at a glance.
    const color = Palette.stageLanternTop;
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
            child: Tappable(
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
