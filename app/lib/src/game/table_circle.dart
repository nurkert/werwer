import 'dart:math';

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/figures.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/layout.dart';
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
        // As big as the column allows, but never taller than the window
        // shows at once (with room for a title and a line above it).
        final space = ColumnSpace.heightOf(context);
        final most = space == null ? 460.0 : (space - 150).clamp(300.0, 640.0);
        final size = min(box.maxWidth, most);
        final portrait = size < 360
            ? 46.0
            : size > 520
            ? 68.0
            : 56.0;
        final label = size > 520 ? 108.0 : 92.0;
        final radius = size / 2 - label / 2 - 4;
        return SizedBox.square(
          dimension: size,
          child: Stack(
            children: [
              Center(child: _Table(diameter: radius * 1.15)),
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
                        ?openRole(view, seat, l10n),
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
              border: selected || isYou
                  ? Border.all(
                      color: selected ? Palette.lantern400 : Palette.moon100,
                      width: 3,
                    )
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Portrait(
                persona: seat.persona,
                size: portrait,
                grey: !seat.isAlive,
              ),
            ),
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
            // A little tag, readable even where it overlaps the table.
            DecoratedBox(
              decoration: BoxDecoration(
                color: Palette.night950.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                child: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Palette.moon200,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// The round wooden table in the middle, a gold inlay and the emblem burnt
/// into its centre.
class _Table extends StatelessWidget {
  const _Table({required this.diameter});

  final double diameter;

  @override
  Widget build(BuildContext context) => Container(
    width: diameter,
    height: diameter,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        center: Alignment(-0.3, -0.35),
        colors: [Color(0xFF6B4528), Palette.wood700, Color(0xFF3B2414)],
        stops: [0, 0.55, 1],
      ),
      boxShadow: [
        BoxShadow(color: Palette.night950, offset: Offset(0, 5)),
        BoxShadow(
          color: Color(0x80000000),
          blurRadius: 28,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: Padding(
      padding: EdgeInsets.all(diameter * 0.06),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Palette.gold500.withValues(alpha: 0.55),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Opacity(
            opacity: 0.22,
            child: Image.asset(
              'assets/brand/emblem.png',
              width: diameter * 0.42,
              color: const Color(0xFF2A170B),
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
        ),
      ),
    ),
  );
}
