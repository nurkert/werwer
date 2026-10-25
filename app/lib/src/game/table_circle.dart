import 'dart:math';

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/figures.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/theme.dart';

/// The table seen from the viewer's own seat: you at the bottom, your
/// neighbours left and right, everyone else around in seating order. Wrong
/// seating shows at a glance.
class TableCircle extends StatelessWidget {
  const TableCircle({
    required this.view,
    super.key,
    this.selected,
    this.onTap,
    this.badges = const {},
  });

  final PlayerView view;
  final PlayerId? selected;
  final void Function(SeatView seat)? onTap;
  final Map<PlayerId, String> badges;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final seats = view.seats;
    final me = max(0, seats.indexWhere((s) => s.id == view.you));
    final ordered = [...seats.skip(me), ...seats.take(me)];
    return LayoutBuilder(
      builder: (context, box) {
        final size = min(box.maxWidth, 460).toDouble();
        final portrait = size < 360 ? 46.0 : 56.0;
        const label = 92.0;
        final radius = size / 2 - label / 2 - 4;
        return SizedBox.square(
          dimension: size,
          child: Stack(
            children: [
              Center(
                child: Container(
                  width: radius * 1.35,
                  height: radius * 1.35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF3B2414),
                    border: Border.all(
                      color: const Color(0xFF6B4423),
                      width: 6,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Color(0x66000000), blurRadius: 24),
                    ],
                  ),
                ),
              ),
              for (final (i, seat) in ordered.indexed)
                () {
                  // Start at the bottom, go round clockwise on screen.
                  final angle = pi / 2 + i * 2 * pi / ordered.length;
                  final x = size / 2 + radius * cos(angle) - label / 2;
                  final y =
                      size / 2 + radius * sin(angle) - (portrait + 34) / 2;
                  return Positioned(
                    left: x,
                    top: y,
                    width: label,
                    child: _Seat(
                      seat: seat,
                      isYou: seat.id == view.you,
                      selected: seat.id == selected,
                      portrait: portrait,
                      subtitle: [
                        if (seat.id == view.you) l10n.you,
                        if (seat.role != null) l10n.role(seat.role!),
                        if (!seat.isAlive) l10n.dead,
                        ?badges[seat.id],
                      ].join(' · '),
                      onTap: onTap == null ? null : () => onTap!(seat),
                    ),
                  );
                }(),
            ],
          ),
        );
      },
    );
  }
}

class _Seat extends StatelessWidget {
  const _Seat({
    required this.seat,
    required this.isYou,
    required this.selected,
    required this.portrait,
    required this.subtitle,
    this.onTap,
  });

  final SeatView seat;
  final bool isYou;
  final bool selected;
  final double portrait;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Opacity(
      opacity: seat.isAlive ? 1 : 0.45,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? Palette.lantern400
                    : isYou
                    ? Palette.moon100
                    : Palette.night700,
                width: selected || isYou ? 3 : 2,
              ),
            ),
            child: Portrait(persona: seat.persona, size: portrait),
          ),
          const SizedBox(height: 4),
          Text(
            seat.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Palette.moon100,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              decoration: seat.isAlive ? null : TextDecoration.lineThrough,
            ),
          ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Palette.moon200, fontSize: 11),
            ),
        ],
      ),
    ),
  );
}
