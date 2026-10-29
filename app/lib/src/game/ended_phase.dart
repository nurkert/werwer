import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:protocol/protocol.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/chronicle.dart';
import 'package:whowolf/src/game/figures.dart';
import 'package:whowolf/src/game/news.dart';
import 'package:whowolf/src/game/phase_body.dart';
import 'package:whowolf/src/game/reveal_phase.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/layout.dart';
import 'package:whowolf/src/net/game_session.dart';
import 'package:whowolf/src/stage/mayor_mark.dart';
import 'package:whowolf/src/stage/stage_kit.dart';
import 'package:whowolf/src/theme.dart';

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
          height: figureHeight(context, phone: 200, wideShare: 0.5),
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
        if (view.chronicle.isNotEmpty)
          Aside(child: ChronicleButton(view: view)),
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
    final layout = StageLayout.of(context);
    // As big as the column allows on a computer, a row of them on a phone.
    final height = layout.twoColumns
        ? (layout.size.height * 0.26).clamp(150.0, 230.0)
        : (layout.roomy ? 170.0 : 128.0);
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        seat.role == null
                            ? personaAsset(seat.persona)
                            : personaRoleAsset(seat.persona, seat.role!),
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                      ),
                      if (isMayor(view, seat))
                        Positioned(
                          left: 0,
                          top: 0,
                          child: MayorPlaque(label: l10n.mayorBadge),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                DecoratedBox(
                  decoration: const PlaqueDecoration(radius: 10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
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
