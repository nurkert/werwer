import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:protocol/protocol.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/atmosphere.dart';
import 'package:whowolf/src/game/check_code.dart';
import 'package:whowolf/src/game/help.dart';
import 'package:whowolf/src/game/narration_script.dart';
import 'package:whowolf/src/game/narrator.dart';
import 'package:whowolf/src/game/night_phase.dart';
import 'package:whowolf/src/game/phases.dart';
import 'package:whowolf/src/game/stage.dart';
import 'package:whowolf/src/game/stage_moment.dart';
import 'package:whowolf/src/game/walking_narrator.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/layout.dart';
import 'package:whowolf/src/net/game_session.dart';
import 'package:whowolf/src/net/hosted_room.dart';
import 'package:whowolf/src/stage/scene.dart';
import 'package:whowolf/src/stage/stage_kit.dart';
import 'package:whowolf/src/theme.dart';

/// The game from this player's seat. If this device hosts, the session owns
/// the room (`GameSession.hosted`) and closes it when leaving.
class GameScreen extends StatefulWidget {
  const GameScreen({
    required this.session,
    this.sounds,
    this.clips,
    super.key,
  });

  final GameSession session;

  /// Where night sounds go; the platform's audio unless a test passes one.
  final Sounds? sounds;

  /// Plays the narrator's recordings; the platform's audio unless a test
  /// passes one.
  final ClipPlayer Function()? clips;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  GameSession get session => widget.session;

  /// Only the host device speaks, so the voice comes from one place (also
  /// after this device took the room over).
  Voice? get _voice => session.hosted == null ? null : _hostVoice;
  late final Voice _hostVoice = Voice();

  /// Night sounds and the morning yawn, on every phone.
  late final _atmosphere = Atmosphere(
    room: session.roomCode,
    sounds: widget.sounds,
  );

  /// This phone stays silent (voice and sounds).
  bool _quiet = false;
  PlayerView? _lastView;
  String? _narration;

  /// The recorded narrator walking around the table, once its recordings
  /// are loaded (none in this build: the system voice on the host).
  WalkingNarrator? _walker;

  /// Until when the narrator's intro runs (this device's clock), if one
  /// does; the roles wait for it.
  int? _introUntil;
  Timer? _introEnd;

  /// The owner's skip this screen has followed already.
  int? _skipSeen;

  bool get _introRunning {
    final until = _introUntil;
    return until != null && DateTime.now().millisecondsSinceEpoch < until;
  }

  @override
  void initState() {
    super.initState();
    unawaited(
      VoiceBank.load().then((bank) {
        if (mounted) {
          _walker = WalkingNarrator(
            bank: bank,
            room: session.roomCode,
            player: widget.clips,
          )..muted = _quiet;
        }
      }),
    );
    // The host must stay awake: a locked host phone ends the game for all.
    unawaited(WakelockPlus.enable());
    session.addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
  }

  /// Back from the lock screen or another app: host again if this device
  /// hosts (iOS kills the server socket in the background) and reconnect
  /// right away instead of waiting for the next retry.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Browsers release the screen lock whenever the page was hidden.
    unawaited(WakelockPlus.enable());
    final room = session.hosted;
    if (room != null) unawaited(_revive(room));
    session.reconnectNow();
  }

  Future<void> _revive(HostedRoom room) async {
    try {
      await room.revive();
    } on Object {
      // No network right now; the next resume tries again.
    }
    // The invite may show a new port or address.
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    session
      ..removeListener(_changed)
      ..dispose();
    _voice?.stop();
    _walker?.stop();
    _introEnd?.cancel();
    _atmosphere.dispose();
    unawaited(WakelockPlus.disable());
    super.dispose();
  }

  void _changed() {
    final refused = session.refused;
    if (refused != null && mounted) {
      session.refused = null;
      _atmosphere.own(Sound.refused);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).refused)),
      );
    }
    final view = session.view;
    if (view != null && !identical(view, _lastView) && mounted) {
      final l10n = AppLocalizations.of(context);
      int? deathAt;
      final before = _lastView;
      final line = narration(before, view, l10n);
      final spoken = spokenMoments(before, view);
      _lastView = view;
      if (line != null) _narration = line;
      // The table can switch the voice off in the settings; the line still
      // shows on every screen.
      final settings = view.settings;
      final walker = _walker;
      if (!settings.narratorVoice) {
        // Silent table.
      } else if (walker != null &&
          spoken.isNotEmpty &&
          walker.bank.speaks(settings.narratorLanguage)) {
        // Recorded voice: it walks around the table, on every phone at
        // the same moment (just after the phase began, by the host's
        // clock).
        final planned = walker.speak(
          moments: spoken,
          language: settings.narratorLanguage,
          round: view.round,
          startMs:
              (session.phaseStartedAtMs ??
                  DateTime.now().millisecondsSinceEpoch) +
              narratorLeadIn(before, view),
          seats: [for (final s in view.seats) s.id],
          me: view.you,
          facts: storyFacts(view),
        );
        _followIntro(planned);
        final named = planned
            .where(
              (p) => deathMoments.contains(p.key) || p.key.startsWith('role_'),
            )
            .firstOrNull;
        if (named != null) deathAt = named.at - 500;
      } else if (line != null) {
        unawaited(_voice?.say(line, l10n.localeName));
      }
      _atmosphere.update(
        view,
        phaseStartedAt: session.phaseStartedAtMs,
        deathAt: deathAt,
      );
      if (view.phase != Phase.roleReveal) _followIntro(const []);
      _followSkip(view);
    }
    setState(() {});
  }

  /// The roles wait while the intro is told (on every phone alike, from
  /// the same plan), and show when it ends.
  void _followIntro(List<Planned> planned) {
    final intro = planned.where((p) => p.key == 'intro').firstOrNull;
    _introEnd?.cancel();
    _introUntil = intro == null ? null : intro.at + intro.clip.ms;
    final left = (_introUntil ?? 0) - DateTime.now().millisecondsSinceEpoch;
    if (left > 0) {
      _introEnd = Timer(Duration(milliseconds: left), () {
        if (mounted) setState(() {});
      });
    }
  }

  /// The owner skipped the intro: it stops on every phone at once and the
  /// narrator goes on to the roles.
  void _followSkip(PlayerView view) {
    final skipped = session.introSkippedAtMs;
    if (view.phase != Phase.roleReveal ||
        skipped == null ||
        skipped == _skipSeen) {
      return;
    }
    _skipSeen = skipped;
    if (!_introRunning) return;
    _followIntro(const []);
    _walker?.speak(
      moments: const [(key: 'reveal', to: null)],
      language: view.settings.narratorLanguage,
      round: view.round,
      startMs: skipped + 600,
      seats: [for (final s in view.seats) s.id],
      me: view.you,
      facts: storyFacts(view),
    );
  }

  Future<void> _leave() async {
    final l10n = AppLocalizations.of(context);
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.leaveTitle),
        content: Text(
          session.hosted != null ? l10n.leaveOwner : l10n.leavePlayer,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.leave),
          ),
        ],
      ),
    );
    if ((sure ?? false) && mounted) {
      // A host hands the room over first; the screen goes right away.
      unawaited(session.leave());
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final view = session.view;
    return PopScope(
      canPop: session.status == SessionStatus.ended,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: SoundScope(
        atmosphere: _atmosphere,
        child: StageMoment(
          view: view,
          child: StageScaffold(
            scene:
                session.status == SessionStatus.reconnecting ||
                    (view == null && session.status != SessionStatus.ended)
                ? Scene.curtain
                : sceneFor(view),
            ghost:
                view != null &&
                !view.yourSeat.isAlive &&
                view.phase != Phase.ended,
            floatingAppBar: true,
            appBar: AppBar(
              toolbarHeight: StageLayout.of(context).short
                  ? 44
                  : kToolbarHeight,
              title: Image.asset(
                'assets/brand/wordmark.png',
                height: StageLayout.of(context).short ? 26 : 34,
                semanticLabel: 'Whowolf',
              ),
              actions: [
                if (_voice != null || (view?.settings.atmosphere ?? false))
                  IconButton(
                    tooltip: _quiet ? l10n.unmute : l10n.mute,
                    icon: Icon(
                      _quiet
                          ? Icons.volume_off_outlined
                          : Icons.volume_up_outlined,
                    ),
                    onPressed: () => setState(() {
                      _quiet = !_quiet;
                      _atmosphere.muted = _quiet;
                      _voice?.muted = _quiet;
                      _walker?.muted = _quiet;
                      if (_quiet) {
                        _voice?.stop();
                        _walker?.stop();
                      }
                    }),
                  ),
                if (session.status != SessionStatus.ended)
                  TextButton(onPressed: _leave, child: Text(l10n.leave)),
              ],
            ),
            body: FloatingHeader(
              header:
                  _narration != null &&
                      session.status != SessionStatus.ended &&
                      view?.phase != Phase.lobby
                  ? _NarratorLine(text: _narration!)
                  : null,
              child: _Paused(
                paused: session.status == SessionStatus.reconnecting,
                onLeave: _leave,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 380),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.97,
                        end: 1,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_screenKey(view)),
                    child: session.status == SessionStatus.ended
                        ? _Ended(reason: session.byeReason)
                        : session.nameRefused
                        ? _Rename(session: session)
                        : (session.waitingForHost ||
                                  session.needsCodeConfirmation) &&
                              view == null
                        ? _WaitingForHost(session: session)
                        : view == null
                        ? const Center(child: CircularProgressIndicator())
                        : _phase(view),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Phones suspend a backgrounded app and with it the room, unless a
  /// foreground service keeps it alive (Android).
  bool get _mustStayOpen {
    final room = session.hosted;
    if (room == null || room.keptAlive || kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.android => true,
      _ => false,
    };
  }

  /// Which screen is up: a new one fades in, updates within one stay put.
  String _screenKey(PlayerView? view) {
    if (session.status == SessionStatus.ended) return 'ended';
    if (session.nameRefused) return 'rename';
    return view?.phase.name ?? 'waiting';
  }

  /// The host's QR code is still hidden: the room is not on the server
  /// yet (players on the same Wi-Fi find it without the code). Showing it
  /// opens the room there first.
  Future<void> Function()? get _showCode {
    final room = session.hosted;
    if (room == null || room.online || room.localOnly) return null;
    if (!room.canGoOnline) return null;
    return () async {
      await room.goOnline();
      if (mounted) setState(() {});
    };
  }

  /// The host wants the Wi-Fi code only (a game without internet).
  void Function()? get _localCode {
    final room = session.hosted;
    if (room == null || room.localOnly) return null;
    return () => setState(() => room.localOnly = true);
  }

  Widget _phase(PlayerView view) => switch (view.phase) {
    Phase.lobby => LobbyPhase(
      session: session,
      link: session.hosted?.link,
      qr: session.hosted?.qrText,
      browserCanJoin: session.hosted?.browserCanJoin ?? false,
      onShowCode: _showCode,
      onLocalCode: _localCode,
      relayFailed: session.hosted?.relayFailed ?? false,
      keepAppOpen: _mustStayOpen,
    ),
    Phase.roleReveal => RevealPhase(
      session: session,
      listening: _introRunning,
      onSkip: session.isOwner
          ? () => session.send(const SkipIntroIntent())
          : null,
    ),
    Phase.night => NightPhase(session: session),
    Phase.day => DayPhase(session: session),
    Phase.hunterShot => HunterPhase(session: session),
    Phase.vote => VotePhase(session: session),
    Phase.ended => EndedPhase(session: session, onLeave: _leave),
  };
}

/// The narrator's latest line, on every device.
class _NarratorLine extends StatelessWidget {
  const _NarratorLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    // Sideways phones have little height: one slim line instead of a card.
    final short = StageLayout.of(context).short;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, short ? 0 : 4, 16, 4),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: Container(
          key: ValueKey(text),
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 640),
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: short ? 6 : 12,
          ),
          // A plaque like every other (task 012); the story in the serif.
          decoration: const PlaqueDecoration(),
          child: Row(
            children: [
              Icon(
                Icons.nightlight_round,
                color: Palette.stageMoonlight,
                size: short ? 18 : 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  maxLines: short ? 2 : 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: displayFont,
                    color: Palette.stageIvory,
                    fontStyle: FontStyle.italic,
                    fontSize: short ? 14 : 16,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Joined without the QR code: wait until the host has compared the code.
class _WaitingForHost extends StatelessWidget {
  const _WaitingForHost({required this.session});

  final GameSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final confirm = session.needsCodeConfirmation;
    return PhaseBody(
      children: [
        const SizedBox(height: 32),
        Headline(l10n.waitingForHost),
        CheckCode(code: session.checkCode),
        if (confirm) ...[
          // Both sides compare: only if the host's screen asks about you
          // with these very symbols is it really the host.
          Body(l10n.codeConfirmHint),
          PrimaryButton(
            label: l10n.codeConfirm,
            onPressed: session.confirmCheckCode,
          ),
        ] else ...[
          Body(l10n.waitingHint, muted: true),
          const CircularProgressIndicator(),
        ],
      ],
    );
  }
}

/// The name was taken: pick another one right here, still connected.
class _Rename extends StatefulWidget {
  const _Rename({required this.session});

  final GameSession session;

  @override
  State<_Rename> createState() => _RenameState();
}

class _RenameState extends State<_Rename> {
  late final _name = TextEditingController(text: widget.session.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty) return;
    widget.session.rename(_name.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PhaseBody(
      children: [
        const SizedBox(height: 24),
        Body(l10n.nameTaken),
        TextField(
          controller: _name,
          autofocus: true,
          maxLength: 24,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: l10n.nameLabel),
          onSubmitted: (_) => _submit(),
        ),
        PrimaryButton(label: l10n.connect, onPressed: _submit),
      ],
    );
  }
}

class _Ended extends StatelessWidget {
  const _Ended({required this.reason});

  final ByeReason? reason;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = switch (reason) {
      ByeReason.wrongRoom => l10n.byeWrongRoom,
      ByeReason.gameRunning => l10n.byeGameRunning,
      ByeReason.unknownSession => l10n.byeUnknownSession,
      ByeReason.refused => l10n.byeRefused,
      ByeReason.kicked => l10n.byeKicked,
      ByeReason.left => l10n.byeLeft,
      ByeReason.replaced => l10n.byeReplaced,
      ByeReason.closed => l10n.byeClosed,
      ByeReason.misbehaved => l10n.byeMisbehaved,
      null => l10n.connectFailed,
    };
    return PhaseBody(
      children: [
        const SizedBox(height: 24),
        Image.asset('assets/brand/emblem.png', height: 120),
        Body(text),
        if (reason == null) const HelpLink(),
        PrimaryButton(
          label: l10n.backToStart,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

/// The host is out of reach: a calm pause over the last view. After a long
/// while a quiet way out appears, in case the room is really gone.
class _Paused extends StatefulWidget {
  const _Paused({
    required this.paused,
    required this.onLeave,
    required this.child,
  });

  final bool paused;
  final VoidCallback onLeave;
  final Widget child;

  @override
  State<_Paused> createState() => _PausedState();
}

class _PausedState extends State<_Paused> {
  static const _offerLeaveAfter = Duration(seconds: 45);

  /// Short drops stay invisible: the link reconnects, a successor takes
  /// over, taps wait in the queue. Only a longer absence gets the pause.
  static const _showAfter = Duration(seconds: 8);

  Timer? _timer;
  Timer? _showTimer;
  bool _offerLeave = false;
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    _watch();
  }

  @override
  void didUpdateWidget(_Paused old) {
    super.didUpdateWidget(old);
    if (old.paused != widget.paused) _watch();
  }

  void _watch() {
    _timer?.cancel();
    _showTimer?.cancel();
    _offerLeave = false;
    _shown = false;
    if (widget.paused) {
      _showTimer = Timer(_showAfter, () {
        if (mounted) setState(() => _shown = true);
      });
      _timer = Timer(_offerLeaveAfter, () {
        if (mounted) setState(() => _offerLeave = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _showTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paused = widget.paused && _shown;
    final child = widget.child;
    final l10n = AppLocalizations.of(context);
    return Stack(
      children: [
        child,
        IgnorePointer(
          ignoring: !paused,
          child: AnimatedOpacity(
            opacity: paused ? 1 : 0,
            duration: const Duration(milliseconds: 400),
            // The last view stays, softly out of focus behind a card.
            child: ClipRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: ColoredBox(
                  color: Palette.night950.withValues(alpha: 0.6),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Panel(
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.nightlight_round,
                                size: 56,
                                color: Palette.lantern400,
                              ),
                              const SizedBox(height: 12),
                              Headline(l10n.pauseTitle),
                              const SizedBox(height: 8),
                              Body(l10n.pauseText),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                child: _offerLeave
                                    ? Padding(
                                        padding: const EdgeInsets.only(
                                          top: 16,
                                        ),
                                        child: TextButton(
                                          onPressed: widget.onLeave,
                                          child: Text(l10n.pauseLeave),
                                        ),
                                      )
                                    : const SizedBox(width: double.infinity),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
