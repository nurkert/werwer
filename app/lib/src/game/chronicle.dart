import 'dart:async';

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/figures.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/layout.dart';
import 'package:whowolf/src/theme.dart';

/// Who voted for whom: one line per player voted for, most votes first,
/// then who abstained.
class VotesPanel extends StatelessWidget {
  const VotesPanel({
    required this.view,
    required this.votes,
    this.title,
    super.key,
  });

  final PlayerView view;

  /// Voter to target (`null` abstains), in the order they were cast.
  final Map<PlayerId, PlayerId?> votes;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final byTarget = <PlayerId, List<PlayerId>>{};
    final abstained = <PlayerId>[];
    for (final MapEntry(key: voter, value: target) in votes.entries) {
      if (target == null) {
        abstained.add(voter);
      } else {
        byTarget.putIfAbsent(target, () => []).add(voter);
      }
    }
    final ranked = byTarget.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: displayFont,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Palette.stageLanternTop,
              ),
            ),
            const SizedBox(height: 8),
          ],
          for (final MapEntry(key: target, value: voters) in ranked)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 34,
                    child: Text(
                      '${voters.length}',
                      style: const TextStyle(
                        fontFamily: displayFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Palette.stageLanternTop,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Body(
                      l10n.votesFor(
                        view.nameOf(target),
                        voters.map(view.nameOf).join(', '),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (abstained.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Body(
                l10n.votesAbstained(abstained.map(view.nameOf).join(', ')),
                muted: true,
              ),
            ),
        ],
      ),
    );
  }
}

/// The votes of [round] from the chronicle (the runoff's if there was
/// one, as that decided).
Map<PlayerId, PlayerId?> votesOf(PlayerView view, int round) {
  final entries = [
    for (final e in view.chronicle)
      if (e.kind == ChronicleKind.vote && e.round == round && e.actor != null)
        e,
  ];
  final runoff = entries.any((e) => e.runoff);
  return {
    for (final e in entries)
      if (e.runoff == runoff) e.actor!: e.target,
  };
}

/// "What really happened" folded into one button at the end, unfolding
/// (animated) into the chronicle, so the curtain call stays in view.
class ChronicleButton extends StatefulWidget {
  const ChronicleButton({required this.view, super.key});

  final PlayerView view;

  @override
  State<ChronicleButton> createState() => _ChronicleButtonState();
}

class _ChronicleButtonState extends State<ChronicleButton> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnimatedSize(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _open = !_open),
              style: TextButton.styleFrom(
                foregroundColor: Palette.stageLanternTop,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
              icon: Icon(
                _open ? Icons.expand_less_rounded : Icons.auto_stories_rounded,
              ),
              label: Text(
                l10n.chronicleTitle,
                style: const TextStyle(
                  fontFamily: displayFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          if (_open) ChroniclePanel(view: widget.view, title: false),
        ],
      ),
    );
  }
}

/// What really happened, night by night and vote by vote: told when the
/// game is over.
class ChroniclePanel extends StatelessWidget {
  const ChroniclePanel({required this.view, this.title = true, super.key});

  final PlayerView view;

  /// Whether the panel names itself (not under its own button).
  final bool title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rounds = {for (final e in view.chronicle) e.round}.toList()..sort();
    String name(PlayerId? id) => id == null ? '?' : view.nameOf(id);
    final children = <Widget>[
      if (title) Headline(l10n.chronicleTitle, size: 28),
    ];
    for (final round in rounds) {
      final entries = [
        for (final e in view.chronicle)
          if (e.round == round) e,
      ];
      final night = [
        for (final e in entries)
          if (e.kind != ChronicleKind.vote) e,
      ];
      if (night.isNotEmpty) {
        children.add(_Chapter(l10n.chronicleNight(round)));
        final lines = <String>[];
        final linked = [
          for (final e in night)
            if (e.kind == ChronicleKind.link) e,
        ];
        if (linked.length == 2) {
          lines.add(
            l10n.chronicleLink(
              name(linked.first.actor),
              name(linked.first.target),
              name(linked.last.target),
            ),
          );
        }
        for (final e in night) {
          final line = switch (e.kind) {
            ChronicleKind.hunt =>
              e.target == null
                  ? l10n.chronicleHuntNone
                  : l10n.chronicleHunt(name(e.target)),
            ChronicleKind.look => l10n.chronicleLook(
              name(e.actor),
              name(e.target),
            ),
            ChronicleKind.heal => l10n.chronicleHeal(
              name(e.actor),
              name(e.target),
            ),
            ChronicleKind.poison => l10n.chroniclePoison(
              name(e.actor),
              name(e.target),
            ),
            ChronicleKind.protect => l10n.chronicleProtect(
              name(e.actor),
              name(e.target),
            ),
            ChronicleKind.link || ChronicleKind.vote => null,
          };
          if (line != null) lines.add(line);
        }
        // On a plaque like the votes, so it reads on any stage set.
        children.add(
          Panel(
            child: Column(
              children: [
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Body(line),
                  ),
              ],
            ),
          ),
        );
      }
      final votes = votesOf(view, round);
      if (votes.isNotEmpty) {
        children
          ..add(_Chapter(l10n.chronicleDay(round)))
          ..add(VotesPanel(view: view, votes: votes));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final child in children)
          Padding(padding: const EdgeInsets.only(bottom: 6), child: child),
      ],
    );
  }
}

class _Chapter extends StatelessWidget {
  const _Chapter(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Center(child: Stamp(text, color: Palette.moon200)),
  );
}

/// Closes the last words on screen, if any (a new death, or the end).
void closeLastWords() => _LastWordsState._current?._close();

/// The dead stand in the spotlight for their last words: their figure
/// large, their name, a short countdown; then it closes by itself (or on
/// a tap). The same on every phone; whoever died reads "your last words".
Future<void> showLastWords(
  BuildContext context, {
  required List<SeatView> dead,
  required PlayerId you,
}) {
  closeLastWords();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: AppLocalizations.of(context).lastWordsTitle,
    barrierColor: const Color(0xCC080B18),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, _, _) => _LastWords(dead: dead, you: you),
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
  );
}

class _LastWords extends StatefulWidget {
  const _LastWords({required this.dead, required this.you});

  final List<SeatView> dead;
  final PlayerId you;

  @override
  State<_LastWords> createState() => _LastWordsState();
}

class _LastWordsState extends State<_LastWords> {
  /// The last words on screen now: never two at once.
  static _LastWordsState? _current;

  late int _left = lastWordsTime.inSeconds;
  late final Timer _tick;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _current = this;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_left <= 1) {
        _close();
      } else {
        setState(() => _left--);
      }
    });
  }

  void _close() {
    _tick.cancel();
    if (_closed || !mounted) return;
    _closed = true;
    final route = ModalRoute.of(context);
    if (route == null) return;
    if (route.isCurrent) {
      Navigator.of(context).pop();
    } else if (route.isActive) {
      Navigator.of(context).removeRoute(route);
    }
  }

  @override
  void dispose() {
    _tick.cancel();
    if (_current == this) _current = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mine = widget.dead.any((s) => s.id == widget.you);
    final height = figureHeight(
      context,
      phone: widget.dead.length > 1 ? 200 : 260,
      share: 0.4,
      wideShare: 0.55,
    );
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _close,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stamp(
                    mine ? l10n.lastWordsYou : l10n.lastWordsTitle,
                    color: Palette.curtain400,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    children: [
                      for (final seat in widget.dead)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TurningFigure(
                              asset: seat.role == null
                                  ? personaAsset(seat.persona)
                                  : personaRoleAsset(seat.persona, seat.role!),
                              height: height,
                            ),
                            const SizedBox(height: 8),
                            Headline(seat.name, size: 30),
                            if (seat.role case final role?)
                              Text(
                                l10n.role(role),
                                style: const TextStyle(
                                  fontFamily: displayFont,
                                  fontSize: 18,
                                  color: Palette.stageLanternTop,
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '$_left',
                    style: const TextStyle(
                      fontFamily: displayFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 44,
                      color: Palette.stageIvory,
                    ),
                  ),
                  Body(
                    mine ? l10n.lastWordsYouHint : l10n.lastWordsHint,
                    muted: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
