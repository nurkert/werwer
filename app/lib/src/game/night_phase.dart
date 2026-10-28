import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:protocol/protocol.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/door_sign.dart';
import 'package:whowolf/src/game/ghost_sight.dart';
import 'package:whowolf/src/game/narrator.dart';
import 'package:whowolf/src/game/news.dart';
import 'package:whowolf/src/game/phases.dart';
import 'package:whowolf/src/game/seer_vision.dart';
import 'package:whowolf/src/game/sheep.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/layout.dart';
import 'package:whowolf/src/net/game_session.dart';
import 'package:whowolf/src/stage/moon.dart';
import 'package:whowolf/src/theme.dart';

/// The night, in one or two steps (the witch decides after the wolves).
/// Every living player has a task in every step; whoever has nothing to do
/// gets a cover task, so the screen and the network give nobody away.
class NightPhase extends StatefulWidget {
  const NightPhase({required this.session, super.key});

  final GameSession session;

  /// This device's clock in milliseconds; screenshot tests move it past
  /// the moment of closing the eyes.
  @visibleForTesting
  static int Function() clock = _now;

  /// When the narrator calls the current step's role (this device's
  /// clock), from the narration plan, which is the same on every phone:
  /// the tasks open a moment after the call begins, not before.
  static final callAt = ValueNotifier<int?>(null);

  static int _now() => DateTime.now().millisecondsSinceEpoch;

  @override
  State<NightPhase> createState() => _NightPhaseState();
}

class _NightPhaseState extends State<NightPhase> {
  final _random = Random();
  late final Timer _report;
  Timer? _decoy;

  /// Ends the moment at a step's start in which every phone shows the same
  /// closed eyes (see [_holding]).
  Timer? _holdEnd;

  /// The step everything below belongs to; a new step starts fresh.
  (int, NightStep)? _step;
  int _sheep = 0;
  int _sentSheep = 0;

  /// What the seer has already seen as a vision (each result once).
  final _visions = <(PlayerId, int)>{};

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
    _holdEnd?.cancel();
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
      _holdEnd?.cancel();
      _holdEnd = null;
      _decoy?.cancel();
      _decoy = null;
      _pair.clear();
      _open = false;
      _heal = false;
      _poison = null;
    }
    _planDecoy(view);
    _showVisions(view);
  }

  /// A new result for the seer: the vision, large, once.
  void _showVisions(PlayerView view) {
    for (final r in view.seerResults) {
      if (r.round != view.round || !_visions.add((r.target, r.round))) {
        continue;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _vision(r));
    }
  }

  void _vision(SeerResult result) {
    final view = session.view;
    if (!mounted || view == null) return;
    final seat = view.seats.where((s) => s.id == result.target).firstOrNull;
    if (seat != null) unawaited(showSeerVision(context, seat, result));
  }

  /// Counting sheep is the cover task; after a while the app sends the
  /// (effectless) cover pick at a random moment, like a real pick. Without
  /// sheep the player answers the plain question by hand instead.
  void _planDecoy(PlayerView view) {
    final due =
        view.settings.sheepInPlay &&
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

  /// Whether this step's first moments still belong to closing the eyes:
  /// for a few seconds every phone shows the same thing, so whoever is
  /// still looking around does not see a neighbour's screen light up with
  /// a werewolf's task. The same time on every phone, from the step's
  /// shared start, whatever the role.
  bool _holding(PlayerView view) {
    final started = session.phaseStartedAtMs;
    if (started == null) return false;
    // After a vote, the one voted out has their last words first.
    final lastWords = freshDeaths(view).any((d) => d.cause == DeathCause.vote)
        ? lastWordsTime.inMilliseconds
        : 0;
    final hold = _isFirstStep(view)
        ? 6000 + lastWords
        : view.settings.nightMode == NightMode.called
        ? 4000
        : 3000;
    // With the narrator calling the roles: until shortly after the call
    // began (never longer than 15 s into the step).
    final call = NightPhase.callAt.value;
    var until = started + hold;
    if (call != null && call >= started && call - started < 15000) {
      until = max(until, call + 1500);
    }
    final left = until - NightPhase.clock();
    if (left <= 0) return false;
    _holdEnd ??= Timer(Duration(milliseconds: left), () {
      _holdEnd = null;
      if (mounted) setState(() {});
    });
    return true;
  }

  static bool _isFirstStep(PlayerView view) {
    final cupidFirst =
        view.round == 1 && view.settings.roles.contains(Role.cupid);
    return view.nightStep == (cupidFirst ? NightStep.link : NightStep.hunt);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final view = session.view!;
    final holding = _holding(view);
    if (view.settings.nightMode == NightMode.called) {
      return _calledNight(view, l10n);
    }
    final sheep = view.settings.sheepInPlay;
    return PhaseBody(
      children: [
        Headline(l10n.nightTitle(view.round)),
        if (view.nightStep == NightStep.hunt) LastNews(view: view),
        CoupleNote(view: view),
        if (!view.yourSeat.isAlive)
          GhostPanel(view: view)
        else if (holding) ...[
          _NightMoon(session: session),
          Body(l10n.eyesClosingTogether),
        ] else ...[
          // Everyone's own sign, big: a reason for every player, not just
          // the werewolves, to keep their screen to themselves.
          if (view.yourDoorSign case final sign?) DoorSignPanel(sign: sign),
          _taskCard(view, l10n),
          // The meadow is the same on every phone: once your task is done
          // (or folded away), a werewolf's phone looks like anyone's.
          if (sheep) ...[
            Aside(child: Body(l10n.nightSheep)),
            Aside(child: Countdown(endsAt: session.phaseEndsAt)),
            Aside(
              child: SheepMeadow(
                key: ValueKey('meadow-${view.round}'),
                flock: view.yourFlock,
                score: _sheep,
                height: figureHeight(
                  context,
                  phone: 220,
                  share: 0.3,
                  wideShare: 0.55,
                ).clamp(200, 420),
                onPoints: (delta) => setState(() => _sheep += delta),
              ),
            ),
            Aside(
              child: TextButton.icon(
                onPressed: () => _ownCount(view),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: Text(l10n.ownCount),
              ),
            ),
          ],
          Body(l10n.nightHint, muted: true),
        ],
        ..._leader(),
      ],
    );
  }

  /// The game leader may pause the night too; everyone sees the same note.
  List<Widget> _leader() => [
    if (session.paused) const PausedNote(),
    if (session.isOwner)
      LeaderBar(session: session, canEnd: false, canExtend: false),
  ];

  /// The night everyone knows: eyes closed, unless the narrator calls you.
  Widget _calledNight(PlayerView view, AppLocalizations l10n) {
    // Not called: eyes closed (never the cover question of Whowolf's night).
    final task = view.yourSeat.isAlive && view.yourNightTask != null
        ? _task(view, l10n)
        : null;
    // Last night's news belongs to the first call of the night.
    final cupidFirst =
        view.round == 1 && view.settings.roles.contains(Role.cupid);
    final first =
        view.nightStep == (cupidFirst ? NightStep.link : NightStep.hunt);
    final awake = task != null && !view.youActed && !_holding(view);
    return PhaseBody(
      children: [
        if (awake)
          Headline(l10n.nightYourTurn, eyebrow: l10n.eyebrowAwake)
        else
          Headline(
            l10n.eyesClosedTitle,
            eyebrow: l10n.eyebrowNight('${view.round}'),
          ),
        if (first) LastNews(view: view),
        CoupleNote(view: view),
        if (!view.yourSeat.isAlive)
          GhostPanel(view: view)
        else if (awake)
          Panel(highlight: true, child: Column(children: task))
        else ...[
          // The same for everyone whose eyes are closed (task 012): the
          // moon, its ring running evenly from the step's start.
          _NightMoon(session: session),
          Body(l10n.nightAwakeNow(awakeIn(view.nightStep, l10n))),
          Body(l10n.nightEyesClosedHint, muted: true),
        ],
        ..._leader(),
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
          if (!view.settings.sheepInPlay) countdown,
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
          if (hunt && view.settings.doorSignsInPlay) ...[
            const SizedBox(height: 20),
            MarkForm(session: session),
          ],
          for (final r in view.seerResults.where((r) => r.round == view.round))
            if (view.seats.where((s) => s.id == r.target).firstOrNull
                case final seat?)
              SeerResultCard(
                seat: seat,
                result: r,
                onSeeAgain: () => _vision(r),
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
        if (view.settings.sheepInPlay) return null;
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

/// The night's moon with its ring: how far the step has run, from its
/// start and the night's length only, so it looks the same on every phone
/// whatever anyone picked (never a called role's time left).
class _NightMoon extends StatefulWidget {
  const _NightMoon({required this.session});

  final GameSession session;

  @override
  State<_NightMoon> createState() => _NightMoonState();
}

class _NightMoonState extends State<_NightMoon> {
  late final Timer _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.session.view!;
    return Moon(
      size: figureHeight(context, phone: 220, share: 0.36),
      progress: nightRing(
        nowMs: DateTime.now().millisecondsSinceEpoch,
        phaseStartedAtMs: widget.session.phaseStartedAtMs,
        nightLength: view.settings.nightTime,
      ),
    );
  }
}
