import 'dart:async';

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/theme.dart';

/// A short full-screen card when the phase changes, like a scene change on
/// the puppet stage: the moon rises for the night, the sun for the day.
/// Skipped when the system asks for less motion.
class StageMoment extends StatefulWidget {
  const StageMoment({required this.view, required this.child, super.key});

  final PlayerView? view;
  final Widget child;

  @override
  State<StageMoment> createState() => _StageMomentState();
}

class _StageMomentState extends State<StageMoment> {
  (Phase, int)? _shown;
  (Phase, int)? _card;
  Timer? _hide;

  @override
  void didUpdateWidget(StageMoment oldWidget) {
    super.didUpdateWidget(oldWidget);
    final view = widget.view;
    if (view == null) return;
    final key = (view.phase, view.round);
    if (key == _shown) return;
    final first = _shown == null;
    _shown = key;
    if (first || view.phase == Phase.lobby) return;
    if (MediaQuery.of(context).disableAnimations) return;
    setState(() => _card = key);
    _hide?.cancel();
    _hide = Timer(const Duration(milliseconds: 1700), () {
      if (mounted) setState(() => _card = null);
    });
  }

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final card = _card;
    final (icon, title) = switch (card?.$1) {
      Phase.roleReveal => (Icons.style_rounded, l10n.revealTitle),
      Phase.night => (Icons.nightlight_round, l10n.nightTitle(card!.$2)),
      Phase.day => (Icons.wb_sunny_rounded, l10n.dayTitle(card!.$2)),
      Phase.vote => (Icons.how_to_vote_rounded, l10n.voteTitle),
      Phase.ended => (
        Icons.emoji_events_rounded,
        widget.view?.winner == Faction.village
            ? l10n.villageWins
            : l10n.werewolvesWin,
      ),
      _ => (Icons.circle, ''),
    };
    return Stack(
      children: [
        widget.child,
        IgnorePointer(
          ignoring: card == null,
          child: GestureDetector(
            onTap: () => setState(() => _card = null),
            child: AnimatedOpacity(
              opacity: card == null ? 0 : 1,
              duration: const Duration(milliseconds: 350),
              child: ColoredBox(
                color: Palette.night950.withValues(alpha: 0.94),
                child: Center(
                  child: AnimatedScale(
                    scale: card == null ? 0.9 : 1,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutBack,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 96, color: Palette.lantern400),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: displayFont,
                            fontSize: 44,
                            color: Palette.moon100,
                          ),
                        ),
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
