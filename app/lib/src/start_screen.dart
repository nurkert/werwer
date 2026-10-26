import 'dart:async';

import 'package:flutter/material.dart';
import 'package:protocol/protocol.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/figures.dart';
import 'package:whowolf/src/game/game_screen.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/join_screen.dart';
import 'package:whowolf/src/net/game_session.dart';
import 'package:whowolf/src/net/hosted_room.dart';
import 'package:whowolf/src/net/room_store.dart';
import 'package:whowolf/src/net/store.dart';
import 'package:whowolf/src/theme.dart';

/// First screen: the wordmark, your name, open or join a room.
class StartScreen extends StatefulWidget {
  const StartScreen({required this.version, super.key});

  final String version;

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final _name = TextEditingController();
  String? _error;
  bool _busy = false;
  ResumeInfo? _resume;
  SavedRoom? _savedRoom;

  @override
  void initState() {
    super.initState();
    unawaited(_loadResume());
  }

  Future<void> _loadResume() async {
    final resume = await const Store().loadResume();
    final savedRoom = await const RoomStore().load();
    if (!mounted) return;
    setState(() {
      _resume = resume;
      _savedRoom = savedRoom;
      if (resume != null && _name.text.isEmpty) _name.text = resume.name;
    });
  }

  Future<void> _continue(ResumeInfo resume) async {
    await playSession(
      context,
      playerSession(
        name: resume.name,
        room: resume.room,
        lan: resume.lan,
        relayRoom: resume.relayRoom,
        server: resume.server,
        hostKey: resume.hostKey,
        roomSecret: resume.roomSecret,
        token: resume.token,
      ),
    );
    await _loadResume();
  }

  /// The host app was closed during a game: bring the room back.
  Future<void> _restore(SavedRoom saved) async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    try {
      final room = await HostedRoom.restore(
        saved,
        hostName: _name.text.trim(),
        relayServer: await const Store().relayServer(),
        notice: l10n.roomOpenNotice,
      );
      final session = GameSession(
        name: _name.text.trim().isEmpty ? 'Host' : _name.text.trim(),
        roomCode: room.roomCode,
        token: room.host.ownerToken,
        dial: () async => room.host.connectOwner(),
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => GameScreen(session: session, room: room),
        ),
      );
    } on Object {
      await const RoomStore().clear();
      setState(() => _error = l10n.hostFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
      await _loadResume();
    }
  }

  Future<void> _settings() async {
    const store = Store();
    final field = TextEditingController(text: await store.customServer());
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    String? error;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(l10n.settings),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: field,
                autocorrect: false,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: l10n.relayServer,
                  hintText: 'wss://relay.example.org',
                  errorText: error,
                ),
              ),
              const SizedBox(height: 10),
              Text(l10n.relayServerHelp, style: const TextStyle(fontSize: 13)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final text = field.text.trim();
                if (text.isNotEmpty && parseRelayServer(text) == null) {
                  setDialog(() => error = l10n.invalidServer);
                  return;
                }
                await store.setCustomServer(text);
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
    field.dispose();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? _checkedName() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = AppLocalizations.of(context).nameRequired);
      return null;
    }
    setState(() => _error = null);
    return name;
  }

  Future<void> _open() async {
    final name = _checkedName();
    if (name == null || _busy) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    try {
      final room = await HostedRoom.open(
        hostName: name,
        relayServer: await const Store().relayServer(),
        notice: l10n.roomOpenNotice,
      );
      final session = GameSession(
        name: name,
        roomCode: room.roomCode,
        dial: () async => room.host.connectOwner(),
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => GameScreen(session: session, room: room),
        ),
      );
    } on Object {
      setState(() => _error = l10n.hostFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final name = _checkedName();
    if (name == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => JoinScreen(name: name)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final resume = _resume;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Palette.moon200,
        actions: [
          IconButton(
            tooltip: l10n.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: _settings,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/brand/wordmark.png',
                    semanticLabel: 'Whowolf',
                  ),
                  const SizedBox(height: 12),
                  const _Cast(),
                  const SizedBox(height: 16),
                  Text(
                    l10n.tagline,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 28),
                  if (_savedRoom case final saved?) ...[
                    PrimaryButton(
                      label: l10n.restoreRoom,
                      onPressed: _busy ? null : () => _restore(saved),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (resume != null) ...[
                    PrimaryButton(
                      label: l10n.resume(resume.room),
                      onPressed: () => _continue(resume),
                    ),
                    const SizedBox(height: 20),
                  ],
                  TextField(
                    controller: _name,
                    maxLength: 24,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.nameLabel,
                      errorText: _error,
                    ),
                    onSubmitted: (_) => _open(),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: l10n.createRoom,
                    onPressed: _busy ? null : _open,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Palette.moon100,
                        side: const BorderSide(
                          color: Palette.lantern400,
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      onPressed: _join,
                      child: Text(l10n.joinRoom),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _Stamp(label: l10n.devStamp(widget.version)),
                  const SizedBox(height: 12),
                  Body(l10n.testNote, muted: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A row of cardboard figures, slightly overlapping.
class _Cast extends StatelessWidget {
  const _Cast();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (i, asset) in castAssets.indexed)
            Transform.translate(
              offset: Offset((2 - i) * 8.0, 0),
              child: Transform.rotate(
                angle: (i - 2) * 0.03,
                child: Figure(asset: asset, height: i == 2 ? 120 : 100),
              ),
            ),
        ],
      ),
    ),
  );
}

class _Stamp extends StatelessWidget {
  const _Stamp({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.05,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Palette.lantern400, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: displayFont,
              fontSize: 18,
              color: Palette.lantern400,
            ),
          ),
        ),
      ),
    );
  }
}
