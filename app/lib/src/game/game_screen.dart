import 'dart:async';

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:protocol/protocol.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:whowolf/l10n/app_localizations.dart';
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

class _GameScreenState extends State<GameScreen> {
  GameSession get session => widget.session;

  @override
  void initState() {
    super.initState();
    // The host must stay awake: a locked host phone ends the game for all.
    unawaited(WakelockPlus.enable());
    session.addListener(_changed);
  }

  @override
  void dispose() {
    session
      ..removeListener(_changed)
      ..dispose();
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
              Expanded(
                child: session.status == SessionStatus.ended
                    ? _Ended(reason: session.byeReason)
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
        PrimaryButton(
          label: l10n.backToStart,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
