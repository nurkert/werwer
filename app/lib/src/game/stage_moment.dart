import 'dart:async';

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/news.dart';
import 'package:whowolf/src/stage/moon.dart';
import 'package:whowolf/src/theme.dart';

/// The curtain between two phases (task 012): the painted curtain closes
/// from both sides, the new scene's name shows with its moon, the curtain
/// opens again. A tap skips it; skipped altogether when the system asks
/// for less motion. The night's roles change without it, so nothing shows
/// when someone is called.
class StageMoment extends StatefulWidget {
  const StageMoment({required this.view, required this.child, super.key});

  final PlayerView? view;
  final Widget child;

  @override
  State<StageMoment> createState() => _StageMomentState();
}

class _StageMomentState extends State<StageMoment>
    with SingleTickerProviderStateMixin {
  (Phase, int)? _shown;
  (Phase, int)? _card;
  late final AnimationController _curtain =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2100),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _card = null);
        }
      });

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
    unawaited(_curtain.forward(from: 0));
  }

  @override
  void dispose() {
    _curtain.dispose();
    super.dispose();
  }

  void _skip() {
    // Straight to the opening.
    if (_curtain.value < 0.7) unawaited(_curtain.forward(from: 0.7));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final card = _card;
    final (moon, title) = switch (card?.$1) {
      Phase.roleReveal => (MoonPhase.full, l10n.revealTitle),
      Phase.night => (MoonPhase.full, l10n.nightTitle(card!.$2)),
      Phase.day => (MoonPhase.sun, l10n.dayTitle(card!.$2)),
      Phase.vote => (MoonPhase.half, l10n.voteTitle),
      Phase.hunterShot => (MoonPhase.full, l10n.roleHunter),
      Phase.ended => (
        widget.view?.winner == Faction.werewolves
            ? MoonPhase.blood
            : MoonPhase.sun,
        l10n.winner(widget.view?.winner),
      ),
      _ => (MoonPhase.full, ''),
    };
    return Stack(
      children: [
        widget.child,
        if (card != null)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _skip,
              child: AnimatedBuilder(
                animation: _curtain,
                builder: (context, _) {
                  final t = _curtain.value;
                  // Closed from 0.25 to 0.7 of the way.
                  final closed = t < 0.25
                      ? Curves.easeInOutCubic.transform(t / 0.25)
                      : t < 0.7
                      ? 1.0
                      : 1 - Curves.easeInOutCubic.transform((t - 0.7) / 0.3);
                  final label = t < 0.3
                      ? 0.0
                      : t < 0.4
                      ? (t - 0.3) / 0.1
                      : t < 0.62
                      ? 1.0
                      : t < 0.7
                      ? 1 - (t - 0.62) / 0.08
                      : 0.0;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      _Half(left: true, closed: closed),
                      _Half(left: false, closed: closed),
                      Opacity(
                        opacity: label,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Moon(size: 120, phase: moon),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: displayFont,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 42,
                                    color: Palette.stageIvory,
                                    shadows: [
                                      Shadow(blurRadius: 16),
                                      Shadow(blurRadius: 4),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

/// One half of the painted curtain, sliding in from its side.
class _Half extends StatelessWidget {
  const _Half({required this.left, required this.closed});

  final bool left;

  /// 0 open, 1 closed.
  final double closed;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final half = box.maxWidth / 2;
      final shift = (1 - closed) * (half + 24);
      return Stack(
        children: [
          Positioned(
            top: 0,
            bottom: 0,
            width: half + 2,
            left: left ? -shift : half - 2 + shift,
            child: ClipRect(
              child: OverflowBox(
                alignment: left ? Alignment.centerLeft : Alignment.centerRight,
                maxWidth: box.maxWidth,
                minWidth: box.maxWidth,
                child: Image.asset(
                  'assets/stage/curtain.webp',
                  fit: BoxFit.cover,
                  width: box.maxWidth,
                  height: box.maxHeight,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
