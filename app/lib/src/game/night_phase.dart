import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:protocol/protocol.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/door_sign.dart';
import 'package:whowolf/src/game/phases.dart';
import 'package:whowolf/src/game/sheep.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/net/game_session.dart';
import 'package:whowolf/src/theme.dart';

/// The night, in one or two steps (the witch decides after the wolves).
/// Every living player has a task in every step; whoever has nothing to do
/// gets a cover task, so the screen and the network give nobody away.
class NightPhase extends StatefulWidget {
  const NightPhase({required this.session, super.key});

  final GameSession session;

  @override
  State<NightPhase> createState() => _NightPhaseState();
}

class _NightPhaseState extends State<NightPhase> {
  final _random = Random();
  late final Timer _report;
  Timer? _decoy;

  /// The step everything below belongs to; a new step starts fresh.
  (int, NightStep)? _step;
  int _sheep = 0;
  int _sentSheep = 0;

  /// Cupid's picks and the witch's draft, before they are sent.
  final _pair = <PlayerId>{};
  bool _heal = false;
  PlayerId? _poison;

  GameSession get session => widget.session;

  @override
  void initState() {
    super.initState();
    _sync();
    // Tonight's sheep go to the host as a running total, at most once a
    // second; everyone sees the totals in the morning.
    _report = Timer.periodic(const Duration(seconds: 1), (_) => _sendSheep());
  }

  @override
  void didUpdateWidget(NightPhase old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _decoy?.cancel();
    _report.cancel();
    super.dispose();
  }

  void _sendSheep() {
    if (_sheep == _sentSheep) return;
    _sentSheep = _sheep;
    // The host refuses more than tonight's flock.
    final most = session.view?.yourFlock ?? maxSheepPerNight;
    session.send(SheepIntent(_sheep.clamp(-maxSheepPerNight, most)));
  }

  /// Starts over for a new step and plans the cover pick if one is due.
  void _sync() {
    final view = session.view!;
    final step = (view.round, view.nightStep);
    if (step != _step) {
      if (_step?.$1 != view.round) {
        _sheep = 0;
        _sentSheep = 0;
      }
      _step = step;
      _decoy?.cancel();
      _decoy = null;
      _pair.clear();
      _open = false;
      _heal = false;
      _poison = null;
    }
    _planDecoy(view);
  }

  /// Counting sheep is the cover task; after a while the app sends the
  /// (effectless) cover pick at a random moment, like a real pick. Without
  /// sheep the player answers the plain question by hand instead.
  void _planDecoy(PlayerView view) {
    final due =
        view.settings.sheepCounting &&
        view.yourNightTask == NightAbility.decoy &&
        view.yourSeat.isAlive &&
        !view.youActed;
    if (!due || _decoy != null) return;
    final step = _step;
    // The witch's step is short: pick within it.
    final delay = view.nightStep == NightStep.brew
        ? 3000 + _random.nextInt(9000)
        : 8000 + _random.nextInt(7000);
    _decoy = Timer(Duration(milliseconds: delay), () {
      final now = session.view;
      if (now == null ||
          now.phase != Phase.night ||
          (now.round, now.nightStep) != step ||
          now.yourNightTask != NightAbility.decoy ||
          now.youActed) {
        return;
      }
      final others = now.seats
          .where((s) => s.isAlive && s.id != now.you)
          .toList();
      if (others.isEmpty) return;
      _sendSheep();
      session.send(NightIntent(others[_random.nextInt(others.length)].id));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final view = session.view!;
    final sheep = view.settings.sheepCounting;
    return PhaseBody(
      children: [
        Headline(l10n.nightTitle(view.round)),
        if (view.nightStep == NightStep.hunt) LastNews(view: view),
        CoupleNote(view: view),
        if (!view.yourSeat.isAlive)
          Body(l10n.youAreDead)
        else ...[
          // Everyone's own sign, big: a reason for every player, not just
          // the werewolves, to keep their screen to themselves.
          if (view.yourDoorSign case final sign?) DoorSignPanel(sign: sign),
          _taskCard(view, l10n),
          // The meadow is the same on every phone: once your task is done
          // (or folded away), a werewolf's phone looks like anyone's.
          if (sheep) ...[
            Body(l10n.nightSheep),
            Countdown(endsAt: session.phaseEndsAt),
            SheepMeadow(
              key: ValueKey('meadow-${view.round}'),
              flock: view.yourFlock,
              score: _sheep,
              onPoints: (delta) => setState(() => _sheep += delta),
            ),
            TextButton.icon(
              onPressed: () => _ownCount(view),
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: Text(l10n.ownCount),
            ),
          ],
          Body(l10n.nightHint, muted: true),
        ],
      ],
    );
  }

  /// Folded open while there is something to decide; afterwards one line
  /// that reads the same for every role, unfolded only on request.
  bool _open = false;

  Widget _taskCard(PlayerView view, AppLocalizations l10n) {
    final task = _task(view, l10n);
    final pending = task != null && !view.youActed;
    if (pending || _open) {
      return Panel(
        highlight: pending,
        child: Column(
          children: [
            ...(task ?? [Body(l10n.nightNothingToDo)]),
            if (!pending)
              TextButton(
                onPressed: () => setState(() => _open = false),
                child: Text(l10n.nightTaskHide),
              ),
          ],
        ),
      );
    }
    return Panel(
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Palette.lantern400),
          const SizedBox(width: 10),
          Expanded(child: Body(l10n.nightTaskDone)),
          TextButton(
            onPressed: () => setState(() => _open = true),
            child: Text(l10n.nightTaskShow),
          ),
        ],
      ),
    );
  }

  /// What this step asks of you, or `null` if counting sheep is all (the
  /// cover pick then goes by itself).
  List<Widget>? _task(PlayerView view, AppLocalizations l10n) {
    final countdown = Countdown(endsAt: session.phaseEndsAt);
    switch (view.yourNightTask) {
      case NightAbility.hunt || NightAbility.inspect:
        final hunt = view.yourNightTask == NightAbility.hunt;
        final choice = view.yourNightChoice;
        final inspected = !hunt && choice != null;
        return [
          Body(hunt ? l10n.nightHunt : l10n.nightInspect),
          if (!view.settings.sheepCounting) countdown,
          const SizedBox(height: 12),
          SeatGrid(
            view: view,
            selected: choice,
            enabled: (seat) =>
                seat.isAlive &&
                seat.id != view.you &&
                !inspected &&
                !(hunt && seat.role == Role.werewolf),
            badges: {
              for (final MapEntry(:key, :value) in view.packChoices.entries)
                if (key != view.you) value: l10n.packPick(view.nameOf(key)),
            },
            onTap: (seat) => session.send(NightIntent(seat.id)),
          ),
          if (choice != null) ...[
            const SizedBox(height: 10),
            Body(l10n.picked(view.nameOf(choice))),
          ],
          if (hunt && view.settings.doorSigns) ...[
            const SizedBox(height: 20),
            MarkForm(session: session),
          ],
          for (final r in view.seerResults.where((r) => r.round == view.round))
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Body(
                l10n.seerSaw(
                  view.nameOf(r.target),
                  r.role != null ? l10n.role(r.role!) : l10n.faction(r.faction),
                ),
              ),
            ),
        ];
      case NightAbility.link:
        final linked = view.yourNightTargets;
        if (view.youActed && linked.length == 2) {
          return [
            Body(l10n.linked(view.nameOf(linked[0]), view.nameOf(linked[1]))),
          ];
        }
        return [
          Body(l10n.nightLink),
          const SizedBox(height: 12),
          SeatGrid(
            view: view,
            chosen: _pair,
            enabled: (seat) => seat.isAlive,
            onTap: (seat) => setState(() {
              if (!_pair.remove(seat.id) && _pair.length < 2) {
                _pair.add(seat.id);
              }
            }),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: l10n.linkConfirm,
            onPressed: _pair.length == 2
                ? () => session.send(NightIntent.of(_pair))
                : null,
          ),
        ];
      case NightAbility.brew:
        if (view.youActed) return [Body(l10n.brewSent)];
        return [Body(l10n.nightBrew), countdown, ..._brew(view, l10n)];
      case NightAbility.decoy || null:
        if (view.settings.sheepCounting) return null;
        // No sheep tonight: a plain question everyone answers by hand.
        return [
          Body(l10n.nightDecoy),
          countdown,
          const SizedBox(height: 12),
          SeatGrid(
            view: view,
            selected: view.yourNightChoice,
            onTap: (seat) => session.send(NightIntent(seat.id)),
          ),
        ];
    }
  }

  /// Anyone may set their own count (and so fib a little): the morning
  /// numbers are a hint to argue about, not proof. Same for every role.
  Future<void> _ownCount(PlayerView view) async {
    final l10n = AppLocalizations.of(context);
    final most = view.yourFlock ?? 30;
    var value = _sheep.clamp(0, most);
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Headline(l10n.ownCountTitle, size: 26),
                const SizedBox(height: 8),
                Body(l10n.ownCountHint, muted: true),
                const SizedBox(height: 16),
                Headline('$value', size: 44, color: Palette.lantern300),
                Slider(
                  value: value.toDouble(),
                  max: most.toDouble(),
                  divisions: most,
                  onChanged: (v) => setSheet(() => value = v.round()),
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: l10n.ownCountSet,
                  onPressed: () => Navigator.pop(context, value),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _sheep = picked);
  }

  /// The witch's table: tonight's victim, her potions and one decision.
  List<Widget> _brew(PlayerView view, AppLocalizations l10n) {
    final victim = view.victim;
    final canHeal = victim != null && view.potions.contains(Potion.heal);
    final canPoison = view.potions.contains(Potion.poison);
    final heal = _heal && canHeal;
    final poison = canPoison ? _poison : null;
    return [
      Panel(
        highlight: true,
        child: Column(
          children: [
            Body(
              victim == null
                  ? l10n.brewNoVictim
                  : l10n.brewVictim(view.nameOf(victim)),
            ),
            if (canHeal) ...[
              const SizedBox(height: 10),
              SecondaryButton(
                label: l10n.brewHeal(view.nameOf(victim)),
                selected: heal,
                onPressed: () => setState(() => _heal = !_heal),
              ),
            ],
            if (view.potions.isEmpty) ...[
              const SizedBox(height: 8),
              Body(l10n.brewEmpty, muted: true),
            ],
          ],
        ),
      ),
      if (canPoison) ...[
        Body(l10n.brewPoison),
        SeatGrid(
          view: view,
          selected: poison,
          enabled: (seat) =>
              seat.isAlive && seat.id != view.you && seat.id != victim,
          onTap: (seat) =>
              setState(() => _poison = _poison == seat.id ? null : seat.id),
        ),
      ],
      PrimaryButton(
        label: heal || poison != null ? l10n.brewDone : l10n.brewNothing,
        onPressed: () => session.send(
          NightIntent.of([if (heal) ?victim, ?poison]),
        ),
      ),
    ];
  }
}
