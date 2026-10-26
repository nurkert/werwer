import 'dart:async';

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart' show NarratorLanguage;
import 'package:protocol/protocol.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/app.dart';
import 'package:whowolf/src/game/figures.dart';
import 'package:whowolf/src/game/game_screen.dart';
import 'package:whowolf/src/game/stage.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/join_screen.dart';
import 'package:whowolf/src/layout.dart';
import 'package:whowolf/src/net/game_session.dart';
import 'package:whowolf/src/net/hosted_room.dart';
import 'package:whowolf/src/net/room_store.dart';
import 'package:whowolf/src/net/store.dart';
import 'package:whowolf/src/privacy_screen.dart';
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

  /// Rejoining by itself happens once per app start; coming back to this
  /// screen afterwards (the player left) shows the buttons instead.
  static bool _autoResumed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadResume(auto: !_autoResumed));
    _autoResumed = true;
  }

  Future<void> _loadResume({bool auto = false}) async {
    final resume = await const Store().loadResume();
    final savedRoom = await const RoomStore().load();
    if (!mounted) return;
    setState(() {
      _resume = resume;
      _savedRoom = savedRoom;
      if (resume != null && _name.text.isEmpty) _name.text = resume.name;
    });
    // The app was closed in the middle of a game (on purpose or not): go
    // straight back to the table. Leaving on purpose clears these records.
    if (auto && savedRoom != null) {
      await _restore(savedRoom);
    } else if (auto && resume != null) {
      await _continue(resume);
    } else if (mounted) {
      await showPrivacyNoticeOnce(context);
    }
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
    var off = await store.relayOff();
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
              DropdownButtonFormField<String>(
                initialValue: appLanguage.value?.languageCode ?? '',
                decoration: InputDecoration(labelText: l10n.language),
                items: [
                  DropdownMenuItem(value: '', child: Text(l10n.languageSystem)),
                  const DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                  const DropdownMenuItem(value: 'en', child: Text('English')),
                ],
                onChanged: (code) {
                  final picked = code == null || code.isEmpty ? null : code;
                  appLanguage.value = picked == null ? null : Locale(picked);
                  unawaited(store.setLanguage(picked));
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: off,
                onChanged: (v) => setDialog(() => off = v),
                title: Text(l10n.relayOff),
                subtitle: off ? Text(l10n.relayOffHint) : null,
              ),
              if (!off) ...[
                TextField(
                  controller: field,
                  autocorrect: false,
                  keyboardType: TextInputType.url,
                  onChanged: (_) => setDialog(() {}),
                  decoration: InputDecoration(
                    labelText: l10n.relayServer,
                    hintText: 'wss://relay.example.org',
                    errorText: error,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  field.text.trim().isEmpty
                      ? l10n.relayServerHelp
                      : l10n.relayCustomHint,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => showPrivacy(context),
                  child: Text(l10n.privacy),
                ),
              ),
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
                // Switched off, the address does not matter (and its error
                // would sit in a hidden field).
                if (!off && text.isNotEmpty && parseRelayServer(text) == null) {
                  setDialog(() => error = l10n.invalidServer);
                  return;
                }
                await store.setCustomServer(text);
                await store.setRelayOff(off: off);
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
        language: l10n.localeName == 'de'
            ? NarratorLanguage.de
            : NarratorLanguage.en,
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
    return StageScaffold(
      floatingAppBar: true,
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
      body: Builder(
        builder: (context) {
          final layout = StageLayout.of(context);
          final stage = [
            Image.asset(
              'assets/brand/wordmark.png',
              semanticLabel: 'Whowolf',
              height: layout.twoColumns ? null : 150,
            ),
            const SizedBox(height: 12),
            _Cast(height: layout.twoColumns ? 200 : (layout.short ? 90 : 120)),
            const SizedBox(height: 16),
            Text(
              l10n.tagline,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ];
          final form = [
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
            SecondaryButton(label: l10n.joinRoom, onPressed: _join),
            const SizedBox(height: 28),
            Stamp(l10n.devStamp(widget.version), size: 18),
            const SizedBox(height: 12),
            Body(l10n.testNote, muted: true),
          ];
          if (!layout.twoColumns) {
            return StageScroll(
              maxWidth: 440,
              horizontal: 28,
              child: Column(
                children: [...stage, const SizedBox(height: 28), ...form],
              ),
            );
          }
          // Wide: the stage with its ensemble on the left, the form beside.
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: StageScroll(
                      maxWidth: 620,
                      horizontal: 32,
                      child: Column(children: stage),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: StageScroll(
                      maxWidth: 420,
                      horizontal: 32,
                      child: Column(children: form),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A row of cardboard figures, slightly overlapping.
class _Cast extends StatelessWidget {
  const _Cast({this.height = 120});

  /// The middle figure's height; the others stand a little smaller.
  final double height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    // Shrinks as a whole when the column is narrower than the ensemble.
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (i, asset) in castAssets.indexed)
            Transform.translate(
              offset: Offset((2 - i) * height / 15, 0),
              child: Transform.rotate(
                angle: (i - 2) * 0.03,
                child: TurningFigure(
                  asset: asset,
                  height: i == 2 ? height : height * 0.83,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
