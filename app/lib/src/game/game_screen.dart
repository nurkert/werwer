import 'dart:async';

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:protocol/protocol.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/check_code.dart';
import 'package:whowolf/src/game/help.dart';
import 'package:whowolf/src/game/narrator.dart';
import 'package:whowolf/src/game/phases.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/net/game_session.dart';
import 'package:whowolf/src/net/hosted_room.dart';
import 'package:whowolf/src/theme.dart';

/// The game from this player's seat. If this device hosts, it also owns the
/// [room] and closes it when leaving.
class GameScreen extends StatefulWidget {
  const GameScreen({required this.session, this.room, super.key});

  final GameSession session;
  final HostedRoom? room;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  GameSession get session => widget.session;

  /// Only the host device speaks, so the voice comes from one place.
  late final Voice? _voice = widget.room == null ? null : Voice();
  PlayerView? _lastView;
  String? _narration;

  @override
  void initState() {
    super.initState();
    // The host must stay awake: a locked host phone ends the game for all.
    unawaited(WakelockPlus.enable());
    session.addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
  }

  /// Back from the lock screen or another app: reconnect right away
  /// instead of waiting for the next retry.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) session.reconnectNow();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    session
      ..removeListener(_changed)
      ..dispose();
    _voice?.stop();
    unawaited(widget.room?.close());
    unawaited(WakelockPlus.disable());
    super.dispose();
  }

  void _changed() {
    final refused = session.refused;
    if (refused != null && mounted) {
      session.refused = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).refused)),
      );
    }
    final view = session.view;
    if (view != null && !identical(view, _lastView) && mounted) {
      final l10n = AppLocalizations.of(context);
      final line = narration(_lastView, view, l10n);
      _lastView = view;
      if (line != null) {
        _narration = line;
        unawaited(_voice?.say(line, l10n.localeName));
      }
    }
    setState(() {});
  }

  Future<void> _leave() async {
    final l10n = AppLocalizations.of(context);
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.leaveTitle),
        content: Text(widget.room != null ? l10n.leaveOwner : l10n.leavePlayer),
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
      session.leave();
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
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Palette.night900,
          foregroundColor: Palette.moon100,
          title: const Text(
            'Whowolf',
            style: TextStyle(fontFamily: displayFont, fontSize: 24),
          ),
          actions: [
            if (_voice != null)
              IconButton(
                tooltip: _voice.muted ? l10n.unmute : l10n.mute,
                icon: Icon(
                  _voice.muted
                      ? Icons.volume_off_outlined
                      : Icons.volume_up_outlined,
                ),
                onPressed: () => setState(() {
                  _voice.muted = !_voice.muted;
                  if (_voice.muted) _voice.stop();
                }),
              ),
            if (session.status != SessionStatus.ended)
              TextButton(onPressed: _leave, child: Text(l10n.leave)),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (session.status == SessionStatus.reconnecting)
                MaterialBanner(
                  backgroundColor: Palette.curtain600,
                  content: Text(
                    l10n.reconnecting,
                    style: const TextStyle(color: Palette.moon100),
                  ),
                  actions: const [SizedBox.shrink()],
                ),
              if (_narration != null &&
                  session.status != SessionStatus.ended &&
                  view?.phase != Phase.lobby)
                _NarratorLine(text: _narration!),
              Expanded(
                child: session.status == SessionStatus.ended
                    ? _Ended(reason: session.byeReason)
                    : session.nameRefused
                    ? _Rename(session: session)
                    : session.waitingForHost && view == null
                    ? _WaitingForHost(code: session.checkCode)
                    : view == null
                    ? const Center(child: CircularProgressIndicator())
                    : _phase(view),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _phase(PlayerView view) => switch (view.phase) {
    Phase.lobby => LobbyPhase(
      session: session,
      link: widget.room?.link,
      relayFailed: widget.room?.relayFailed ?? false,
    ),
    Phase.roleReveal => RevealPhase(session: session),
    Phase.night => NightPhase(session: session),
    Phase.day => DayPhase(session: session),
    Phase.vote => VotePhase(session: session),
    Phase.ended => EndedPhase(session: session, onLeave: _leave),
  };
}

/// The narrator's latest line, on every device.
class _NarratorLine extends StatelessWidget {
  const _NarratorLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey(text),
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Palette.night700,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.nightlight_round, color: Palette.lantern400),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Palette.moon100,
                  fontStyle: FontStyle.italic,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Joined without the QR code: wait until the host has compared the code.
class _WaitingForHost extends StatelessWidget {
  const _WaitingForHost({required this.code});

  final List<int> code;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PhaseBody(
      children: [
        const SizedBox(height: 32),
        Headline(l10n.waitingForHost),
        CheckCode(code: code),
        Body(l10n.waitingHint, muted: true),
        const CircularProgressIndicator(),
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
        const SizedBox(height: 40),
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
