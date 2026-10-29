import 'dart:async';

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:protocol/protocol.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/figures.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/layout.dart';
import 'package:whowolf/src/net/game_session.dart';
import 'package:whowolf/src/stage/mayor_mark.dart';
import 'package:whowolf/src/theme.dart';

/// Whether today's talk elects a mayor (as `GameState.electsMayor`).
bool electsMayor(PlayerView view) =>
    view.settings.mayor &&
    view.phase == Phase.day &&
    !view.seats.any((s) => s.id == view.mayor && s.isAlive);

/// Who backs whom in today's open ballot, the candidates by their backers.
Map<PlayerId, List<PlayerId>> mayorBackers(PlayerView view) {
  final backers = <PlayerId, List<PlayerId>>{};
  for (final MapEntry(key: voter, value: candidate)
      in view.mayorVotes.entries) {
    (backers[candidate] ??= []).add(voter);
  }
  return backers;
}

/// In the day's talk while there is no living mayor: the chain of office,
/// how far the ballot is, your own vote, and the way into the election.
class MayorEntry extends StatelessWidget {
  const MayorEntry({required this.session, super.key});

  final GameSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final view = session.view!;
    final alive = view.seats.where((s) => s.isAlive).length;
    final mine = view.mayorVotes[view.you];
    final canVote = view.yourSeat.isAlive;
    return Panel(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MayorMark(label: l10n.mayorBadge, size: 34),
              const SizedBox(width: 10),
              Flexible(child: Headline(l10n.mayorBallotTitle, size: 24)),
            ],
          ),
          const SizedBox(height: 6),
          Body(
            l10n.mayorProgress(view.mayorVotes.length, alive),
            muted: true,
          ),
          if (mine != null) Body(l10n.mayorYourPick(view.nameOf(mine))),
          const SizedBox(height: 12),
          if (canVote && mine == null)
            PrimaryButton(
              label: l10n.mayorElect,
              icon: Icons.how_to_vote_rounded,
              onPressed: () => showMayorElection(context, session),
            )
          else
            SecondaryButton(
              label: canVote ? l10n.mayorChange : l10n.mayorWatch,
              icon: canVote ? Icons.edit_rounded : Icons.visibility_rounded,
              onPressed: () => showMayorElection(context, session),
            ),
        ],
      ),
    );
  }
}

/// Opens the election: a sheet from the bottom on a phone, a dialog on a
/// computer. It closes by itself once the village has chosen.
Future<void> showMayorElection(BuildContext context, GameSession session) {
  final content = MayorElection(session: session);
  if (StageLayout.of(context).twoColumns) {
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Palette.stagePlaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 760),
          child: content,
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Palette.stagePlaque,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.9,
      child: content,
    ),
  );
}

/// The election itself: every living player as a card with their backers
/// (the ballot is open), pick one and confirm; the dead watch.
class MayorElection extends StatefulWidget {
  const MayorElection({required this.session, super.key});

  final GameSession session;

  @override
  State<MayorElection> createState() => _MayorElectionState();
}

class _MayorElectionState extends State<MayorElection> {
  PlayerId? _draft;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_changed);
  }

  @override
  void dispose() {
    widget.session.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    final view = widget.session.view;
    // Decided (or the talk is over): nothing left to choose here.
    if (view == null || !electsMayor(view)) {
      if (!_closing) {
        _closing = true;
        unawaited(Navigator.of(context).maybePop());
      }
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final view = widget.session.view;
    if (view == null) return const SizedBox.shrink();
    final backers = mayorBackers(view);
    final alive = view.seats.where((s) => s.isAlive).length;
    final canVote = view.yourSeat.isAlive && electsMayor(view);
    final mine = view.mayorVotes[view.you];
    final draft = _draft;
    final standings = [
      for (final seat in view.seats)
        if (backers[seat.id] case final who?) (seat, who),
    ]..sort((a, b) => b.$2.length.compareTo(a.$2.length));
    return Material(
      type: MaterialType.transparency,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      MayorMark(label: l10n.mayorBadge, size: 40),
                      const SizedBox(width: 12),
                      // One word in German: shrinks instead of breaking.
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l10n.mayorSheetTitle,
                            maxLines: 1,
                            style: const TextStyle(
                              fontFamily: displayFont,
                              fontWeight: FontWeight.w700,
                              fontSize: 26,
                              color: Palette.stageIvory,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).closeButtonLabel,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Palette.stageIvorySoft,
                        ),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.mayorProgress(view.mayorVotes.length, alive),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: displayFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: Palette.stageLanternTop,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SeatGrid(
                    view: view,
                    selected: draft ?? mine,
                    // Every living player can be chosen, yourself too.
                    enabled: (seat) => seat.isAlive,
                    badges: {
                      for (final MapEntry(:key, :value) in backers.entries)
                        key: l10n.mayorBackers(value.length),
                    },
                    onTap: canVote
                        ? (seat) => setState(
                            () => _draft = _draft == seat.id ? null : seat.id,
                          )
                        : null,
                  ),
                  if (standings.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      l10n.mayorWhoBacksWhom,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: displayFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Palette.stageIvory,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final (seat, who) in standings)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: _Standing(
                          seat: seat,
                          backers: [for (final id in who) view.nameOf(id)],
                          you: seat.id == view.you,
                        ),
                      ),
                  ],
                  if (!canVote) ...[
                    const SizedBox(height: 14),
                    Text(
                      l10n.mayorReadOnly,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Palette.stageIvorySoft),
                    ),
                  ],
                  // How it works, under the choice: the cards come first.
                  const SizedBox(height: 18),
                  Text(
                    l10n.mayorSheetHint,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: Palette.stageIvorySoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Pick, then confirm, like the vote and the hunter's shot.
          if (canVote)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: draft != null && draft != mine
                  ? PrimaryButton(
                      label: l10n.mayorConfirm(view.nameOf(draft)),
                      icon: Icons.how_to_vote_rounded,
                      onPressed: () {
                        widget.session.send(MayorIntent(draft));
                        setState(() => _draft = null);
                      },
                    )
                  : Text(
                      mine == null
                          ? l10n.mayorPickHint
                          : l10n.mayorYourPick(view.nameOf(mine)),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Palette.stageIvorySoft,
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

/// One candidate and who backs them, as a line.
class _Standing extends StatelessWidget {
  const _Standing({
    required this.seat,
    required this.backers,
    required this.you,
  });

  final SeatView seat;
  final List<String> backers;
  final bool you;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 34,
        child: Text(
          '${backers.length}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: displayFont,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Palette.stageLanternTop,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: seat.name,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: you ? Palette.stageLanternTop : Palette.stageIvory,
                ),
              ),
              TextSpan(
                text: '  ← ${backers.join(', ')}',
                style: const TextStyle(color: Palette.stageIvorySoft),
              ),
            ],
          ),
          style: const TextStyle(fontSize: 15, height: 1.35),
        ),
      ),
    ],
  );
}

/// The village has chosen: the new mayor in the spotlight with the chain
/// of office, on every phone at once (the result is public), for a few
/// seconds or until tapped.
Future<void> showMayorCeremony(
  BuildContext context, {
  required SeatView mayor,
  required PlayerId you,
}) => showGeneralDialog<void>(
  context: context,
  barrierDismissible: true,
  barrierLabel: AppLocalizations.of(context).mayorBadge,
  barrierColor: const Color(0xCC080B18),
  transitionDuration: const Duration(milliseconds: 300),
  pageBuilder: (context, _, _) => _Ceremony(mayor: mayor, you: you),
  transitionBuilder: (context, animation, _, child) => FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
    child: child,
  ),
);

class _Ceremony extends StatefulWidget {
  const _Ceremony({required this.mayor, required this.you});

  final SeatView mayor;
  final PlayerId you;

  @override
  State<_Ceremony> createState() => _CeremonyState();
}

class _CeremonyState extends State<_Ceremony>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  Timer? _timer;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_drop.forward());
    _timer = Timer(const Duration(milliseconds: 3800), _close);
  }

  void _close() {
    if (_closed || !mounted) return;
    _closed = true;
    unawaited(Navigator.of(context).maybePop());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _drop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mine = widget.mayor.id == widget.you;
    final reduce = MediaQuery.of(context).disableAnimations;
    final height = figureHeight(
      context,
      phone: 240,
      share: 0.38,
      wideShare: 0.5,
    );
    // The chain drops onto the figure's shoulders.
    final fall = CurvedAnimation(parent: _drop, curve: Curves.bounceOut);
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
                    mine ? l10n.mayorCeremonyYou : l10n.mayorCeremonyTitle,
                    color: Palette.stageLanternTop,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: height,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        Image.asset(
                          personaAsset(widget.mayor.persona),
                          height: height,
                          fit: BoxFit.contain,
                        ),
                        AnimatedBuilder(
                          animation: fall,
                          builder: (context, child) => Transform.translate(
                            offset: Offset(
                              0,
                              reduce
                                  ? height * 0.12
                                  : -height * 0.5 + fall.value * height * 0.62,
                            ),
                            child: child,
                          ),
                          child: MayorMark(
                            label: l10n.mayorBadge,
                            size: height * 0.32,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Headline(widget.mayor.name, size: 30),
                  Body(l10n.mayorCeremonyHint),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
