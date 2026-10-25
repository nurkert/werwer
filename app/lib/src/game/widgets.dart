import 'dart:async';

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/theme.dart';

extension RoleText on AppLocalizations {
  String role(Role role) => switch (role) {
    Role.villager => roleVillager,
    Role.werewolf => roleWerewolf,
    Role.seer => roleSeer,
  };

  String roleText(Role role) => switch (role) {
    Role.villager => roleVillagerText,
    Role.werewolf => roleWerewolfText,
    Role.seer => roleSeerText,
  };

  String faction(Faction faction) => switch (faction) {
    Faction.village => factionVillage,
    Faction.werewolves => factionWerewolves,
  };
}

extension SeatLookup on PlayerView {
  String nameOf(PlayerId id) =>
      seats.where((s) => s.id == id).map((s) => s.name).firstOrNull ?? '?';
}

/// A big title in the display font.
class Headline extends StatelessWidget {
  const Headline(this.text, {super.key, this.color = Palette.moon100});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: TextStyle(fontFamily: displayFont, fontSize: 34, color: color),
  );
}

/// Body text in the cream colour.
class Body extends StatelessWidget {
  const Body(this.text, {super.key, this.muted = false});

  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: TextStyle(
      fontSize: 16,
      height: 1.4,
      color: muted ? Palette.moon200.withValues(alpha: 0.7) : Palette.moon200,
    ),
  );
}

/// A rounded panel.
class Panel extends StatelessWidget {
  const Panel({required this.child, super.key, this.highlight = false});

  final Widget child;
  final bool highlight;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: highlight ? Palette.night700 : Palette.night800,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: highlight ? Palette.lantern400 : Palette.night700,
        width: highlight ? 2 : 1,
      ),
    ),
    child: Padding(padding: const EdgeInsets.all(18), child: child),
  );
}

/// The seats as tappable tiles.
class SeatGrid extends StatelessWidget {
  const SeatGrid({
    required this.view,
    super.key,
    this.selected,
    this.onTap,
    this.enabled,
    this.badges = const {},
    this.trailing,
  });

  final PlayerView view;
  final PlayerId? selected;
  final void Function(SeatView seat)? onTap;

  /// Which seats can be tapped; all living others by default.
  final bool Function(SeatView seat)? enabled;

  /// Small extra text under a name (e.g. a werewolf's pick).
  final Map<PlayerId, String> badges;

  /// Optional widget per seat (e.g. a remove button).
  final Widget? Function(SeatView seat)? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        for (final seat in view.seats)
          _SeatTile(
            seat: seat,
            isYou: seat.id == view.you,
            selected: seat.id == selected,
            enabled:
                onTap != null &&
                (enabled?.call(seat) ?? (seat.isAlive && seat.id != view.you)),
            onTap: () => onTap?.call(seat),
            subtitle: [
              if (seat.id == view.you) l10n.you,
              if (seat.role != null) l10n.role(seat.role!),
              if (!seat.isAlive) l10n.dead,
              ?badges[seat.id],
            ].join(' · '),
            trailing: trailing?.call(seat),
          ),
      ],
    );
  }
}

class _SeatTile extends StatelessWidget {
  const _SeatTile({
    required this.seat,
    required this.isYou,
    required this.selected,
    required this.enabled,
    required this.onTap,
    required this.subtitle,
    this.trailing,
  });

  final SeatView seat;
  final bool isYou;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final border = selected
        ? Palette.lantern400
        : isYou
        ? Palette.moon200.withValues(alpha: 0.5)
        : Palette.night700;
    return Opacity(
      opacity: seat.isAlive ? 1 : 0.45,
      child: Material(
        color: selected ? Palette.night700 : Palette.night800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: selected ? 2.5 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? onTap : null,
          child: SizedBox(
            width: 150,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          seat.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Palette.moon100,
                            decoration: seat.isAlive
                                ? null
                                : TextDecoration.lineThrough,
                          ),
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            maxLines: 2,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Palette.moon200,
                            ),
                          ),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Seconds until [endsAt], ticking.
class Countdown extends StatefulWidget {
  const Countdown({required this.endsAt, super.key});

  final DateTime? endsAt;

  @override
  State<Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<Countdown> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final endsAt = widget.endsAt;
    if (endsAt == null) return const SizedBox.shrink();
    final seconds = endsAt.difference(DateTime.now()).inSeconds.clamp(0, 9999);
    return Text(
      AppLocalizations.of(context).timeLeft(seconds),
      style: const TextStyle(color: Palette.lantern400, fontSize: 14),
    );
  }
}

/// A full-width primary button.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: Palette.lantern400,
        foregroundColor: Palette.ink,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      onPressed: onPressed,
      child: Text(label),
    ),
  );
}
