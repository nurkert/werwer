import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/theme.dart';

/// What a ghost sees, only while a finger holds the button: whoever sits
/// next to a dead player does not read the roles by accident.
///
/// Shown to the dead only once they have nothing left to do and the table
/// let ghosts watch (`PlayerView.yourGhostSight`); otherwise just the old
/// "you are dead" line.
class GhostPanel extends StatefulWidget {
  const GhostPanel({required this.view, super.key});

  final PlayerView view;

  @override
  State<GhostPanel> createState() => _GhostPanelState();
}

class _GhostPanelState extends State<GhostPanel> {
  bool _holding = false;

  void _hold(bool on) {
    if (on != _holding) setState(() => _holding = on);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final view = widget.view;
    if (view.yourGhostSight == GhostSight.off) return Body(l10n.youAreDead);
    return Column(
      children: [
        Body(l10n.ghostHint),
        const SizedBox(height: 12),
        Semantics(
          button: true,
          label: l10n.ghostHold,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _hold(true),
            onTapUp: (_) => _hold(false),
            onTapCancel: () => _hold(false),
            onLongPressStart: (_) => _hold(true),
            onLongPressEnd: (_) => _hold(false),
            onLongPressCancel: () => _hold(false),
            child: Panel(
              highlight: _holding,
              child: SizedBox(
                width: double.infinity,
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  child: _holding
                      ? _Knowledge(view: view)
                      : Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.visibility_outlined,
                                color: Palette.moon100,
                              ),
                              const SizedBox(width: 10),
                              Flexible(child: Body(l10n.ghostHold)),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Knowledge extends StatelessWidget {
  const _Knowledge({required this.view});

  final PlayerView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ghost = view.ghost;
    final couple = view.couple;
    String names(List<PlayerId> ids) => ids.map(view.nameOf).join(', ');
    final tonight = [
      if (ghost != null) ...[
        for (final MapEntry(:key, :value) in ghost.night.entries)
          if (value.isNotEmpty) l10n.ghostPick(view.nameOf(key), names(value)),
        if (ghost.victim case final victim?)
          l10n.ghostVictim(view.nameOf(victim)),
        for (final seen in ghost.seen.where((s) => s.round == view.round))
          l10n.ghostSeen(
            view.nameOf(seen.target),
            seen.role != null
                ? l10n.role(seen.role!)
                : l10n.faction(seen.faction),
          ),
        if (ghost.potionsUsed.isNotEmpty)
          l10n.ghostPotions(
            [
              for (final p in ghost.potionsUsed)
                p == Potion.heal ? l10n.potionHeal : l10n.potionPoison,
            ].join(', '),
          ),
      ],
    ];
    final votes = [
      if (ghost != null)
        for (final MapEntry(:key, :value) in ghost.votes.entries)
          l10n.ghostPick(
            view.nameOf(key),
            value == null ? l10n.abstain : view.nameOf(value),
          ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Headline(l10n.ghostRoles, size: 20),
        const SizedBox(height: 6),
        for (final seat in view.seats)
          if (seat.role != null)
            Body(
              '${seat.name}: ${l10n.role(seat.role!)}'
              '${seat.isAlive ? '' : ' (${l10n.dead})'}',
            ),
        if (couple.length == 2) ...[
          const SizedBox(height: 6),
          Body(
            l10n.ghostLovers(view.nameOf(couple[0]), view.nameOf(couple[1])),
          ),
        ],
        if (ghost != null && view.phase == Phase.night) ...[
          const SizedBox(height: 14),
          Headline(l10n.ghostTonight, size: 20),
          const SizedBox(height: 6),
          if (tonight.isEmpty)
            Body(l10n.ghostNothingYet, muted: true)
          else
            for (final line in tonight) Body(line),
        ],
        if (ghost != null && view.phase == Phase.vote) ...[
          const SizedBox(height: 14),
          Headline(l10n.ghostVotes, size: 20),
          const SizedBox(height: 6),
          if (votes.isEmpty)
            Body(l10n.ghostNothingYet, muted: true)
          else
            for (final line in votes) Body(line),
        ],
      ],
    );
  }
}
