import 'dart:async';

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/figures.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/layout.dart';
import 'package:whowolf/src/theme.dart';

/// The costume the seer sees [seat] in: the exact role if the table lets
/// the seer see roles, otherwise the werewolf's or the everyday clothes.
String visionAsset(SeatView seat, SeerResult result) {
  final role = result.role;
  if (role != null) return personaRoleAsset(seat.persona, role);
  return result.faction == Faction.werewolves
      ? personaRoleAsset(seat.persona, Role.werewolf)
      : personaAsset(seat.persona);
}

/// Shows the seer's vision over the night: [seat]'s figure stands with its
/// back to the seer, turns around in the costume of what they are, and
/// the name and role stand large below. It closes by itself after a few
/// seconds, or on a tap. No sound: it is night.
Future<void> showSeerVision(
  BuildContext context,
  SeatView seat,
  SeerResult result,
) => showGeneralDialog<void>(
  context: context,
  barrierDismissible: true,
  barrierLabel: AppLocalizations.of(context).seerVisionClose,
  barrierColor: const Color(0xD9080B18),
  transitionDuration: const Duration(milliseconds: 320),
  pageBuilder: (context, _, _) => _SeerVision(seat: seat, result: result),
  transitionBuilder: (context, animation, _, child) => FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
    child: ScaleTransition(
      scale: Tween<double>(begin: 0.94, end: 1).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      ),
      child: child,
    ),
  ),
);

class _SeerVision extends StatefulWidget {
  const _SeerVision({required this.seat, required this.result});

  final SeatView seat;
  final SeerResult result;

  @override
  State<_SeerVision> createState() => _SeerVisionState();
}

class _SeerVisionState extends State<_SeerVision> {
  /// How long the vision stays before it closes by itself.
  static const _stay = Duration(seconds: 6);

  bool _turned = false;
  late final Timer _turn;
  late final Timer _close;

  @override
  void initState() {
    super.initState();
    // A moment to see who it is from behind, then the figure turns.
    _turn = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _turned = true);
    });
    _close = Timer(_stay, _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route?.isCurrent ?? false) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _turn.cancel();
    _close.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final result = widget.result;
    final wolf = result.faction == Faction.werewolves;
    final color = wolf ? Palette.curtain400 : Palette.stageLanternTop;
    final what = result.role != null
        ? l10n.role(result.role!)
        : l10n.faction(result.faction);
    final height = figureHeight(
      context,
      phone: 300,
      share: 0.46,
      wideShare: 0.6,
    );
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _dismiss,
        child: Semantics(
          liveRegion: true,
          label: l10n.seerSaw(widget.seat.name, what),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stamp(l10n.seerVisionTitle, color: Palette.moon200),
                    const SizedBox(height: 18),
                    // The figure in a pool of moonlight, which takes the
                    // colour of what it turns out to be.
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          width: height * 1.1,
                          height: height * 1.1,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                (_turned ? color : Palette.moon200).withValues(
                                  alpha: 0.28,
                                ),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        TurningFigure(
                          asset: visionAsset(widget.seat, result),
                          backAsset: personaAsset(widget.seat.persona),
                          showBack: !_turned,
                          height: height,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Headline(widget.seat.name, size: 30),
                    const SizedBox(height: 8),
                    AnimatedOpacity(
                      opacity: _turned ? 1 : 0,
                      duration: const Duration(milliseconds: 420),
                      child: Column(
                        children: [
                          Headline(what, color: color, size: 40),
                          const SizedBox(height: 14),
                          Body(l10n.seerVisionClose, muted: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What the seer saw tonight, small, with a way to see it again.
class SeerResultCard extends StatelessWidget {
  const SeerResultCard({
    required this.seat,
    required this.result,
    required this.onSeeAgain,
    super.key,
  });

  final SeatView seat;
  final SeerResult result;
  final VoidCallback onSeeAgain;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final what = result.role != null
        ? l10n.role(result.role!)
        : l10n.faction(result.faction);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          TurningFigure(
            asset: visionAsset(seat, result),
            height: 76,
            sway: false,
            shadow: false,
          ),
          const SizedBox(width: 12),
          Expanded(child: Body(l10n.seerSaw(seat.name, what))),
          TextButton(onPressed: onSeeAgain, child: Text(l10n.seerSeeAgain)),
        ],
      ),
    );
  }
}
