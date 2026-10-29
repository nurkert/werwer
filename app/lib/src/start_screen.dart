import 'dart:async';

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart' show NarratorLanguage;
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/app.dart' show appVersion;
import 'package:whowolf/src/app_settings.dart';
import 'package:whowolf/src/game/game_screen.dart';
import 'package:whowolf/src/game/help.dart';
import 'package:whowolf/src/game/stage.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/join_screen.dart';
import 'package:whowolf/src/layout.dart';
import 'package:whowolf/src/net/app_links.dart';
import 'package:whowolf/src/net/discovery.dart';
import 'package:whowolf/src/net/game_session.dart';
import 'package:whowolf/src/net/hosted_room.dart';
import 'package:whowolf/src/net/room_store.dart';
import 'package:whowolf/src/net/store.dart';
import 'package:whowolf/src/net/update_check.dart';
import 'package:whowolf/src/privacy_screen.dart';
import 'package:whowolf/src/stage/stage_pages.dart';
import 'package:whowolf/src/stage/wolf_title.dart';
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

  /// Rooms open on this Wi-Fi whose host answers, to join in one tap; the
  /// last one first.
  final _finder = RoomFinder(probe: tcpProbe);
  String? _lastRoom;

  /// Rejoining by itself happens once per app start; coming back to this
  /// screen afterwards (the player left) shows the buttons instead.
  static bool _autoResumed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadResume(auto: !_autoResumed));
    _autoResumed = true;
    unawaited(
      Future.wait([const Store().name(), const Store().lastRoom()]).then((v) {
        if (!mounted) return;
        setState(() {
          if (_name.text.isEmpty && v[0] != null) _name.text = v[0]!;
          _lastRoom = v[1];
        });
      }),
    );
    _name.addListener(_keepName);
    incomingLink.addListener(_linked);
    WidgetsBinding.instance.addPostFrameCallback((_) => _linked());
  }

  /// A room link opened the app: with a name, straight to the question
  /// whether to join; without one, it waits until the player taps join.
  void _linked() {
    if (incomingLink.value == null || !mounted) return;
    if (_name.text.trim().isEmpty) {
      setState(() => _error = AppLocalizations.of(context).nameRequired);
      return;
    }
    unawaited(_join());
  }

  void _keepName() => unawaited(const Store().setName(_name.text.trim()));

  Future<void> _quickJoin(NearbyRoom room) async {
    final name = _checkedName();
    if (name == null) return;
    // The room may have closed since the last probe: say so instead of
    // waiting for a host that is gone.
    if (!await _finder.check(room)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).roomGone)),
      );
      return;
    }
    if (!mounted) return;
    await playSession(
      context,
      playerSession(
        name: name,
        room: room.room,
        lan: room.lan,
        keyPrint: room.keyPrint,
      ),
    );
    await _loadResume();
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
      if (mounted && auto) await checkForUpdate(context, widget.version);
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
        hosted: room,
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => GameScreen(session: session)),
      );
    } on Object {
      await const RoomStore().clear();
      setState(() => _error = l10n.hostFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
      await _loadResume();
    }
  }

  /// On a computer the settings are behind the gear: the same as the
  /// phone's page to the right.
  Future<void> _settings() => showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Palette.stagePlaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Headline(
                      AppLocalizations.of(context).pageSettings,
                      size: 30,
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).closeButtonLabel,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppSettings(version: widget.version),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  void dispose() {
    incomingLink.removeListener(_linked);
    _finder.dispose();
    _name
      ..removeListener(_keepName)
      ..dispose();
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
      const store = Store();
      final room = await HostedRoom.open(
        hostName: name,
        relayServer: await store.relayServer(),
        online: await store.relayMode() == RelayMode.always,
        serveWebApp: await store.serveWebApp(),
        webAppBuild: appVersion,
        notice: l10n.roomOpenNotice,
        language: l10n.localeName == 'de'
            ? NarratorLanguage.de
            : NarratorLanguage.en,
      );
      final session = GameSession(
        name: name,
        roomCode: room.roomCode,
        dial: () async => room.host.connectOwner(),
        hosted: room,
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => GameScreen(session: session)),
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
    final link = incomingLink.value;
    incomingLink.value = null;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => JoinScreen(name: name, link: link),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final resume = _resume;
    return StageScaffold(
      floatingAppBar: true,
      // The pages keep their size; the name field slides above the keyboard.
      resizeForKeyboard: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Palette.moon200,
        // On a phone the settings are the page to the right.
        actions: [
          const LanguageFlag(),
          if (StageLayout.of(context).twoColumns)
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
            WolfTitle(width: layout.twoColumns ? 520 : 360),
            const SizedBox(height: 14),
            Text(
              l10n.tagline,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: displayFont,
                fontSize: 19,
                fontStyle: FontStyle.italic,
                color: Palette.stageIvory,
                shadows: [Shadow(blurRadius: 8)],
              ),
            ),
          ];
          final play = [
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
            // Tables open nearby: one tap, the last one first.
            ListenableBuilder(
              listenable: _finder,
              builder: (context, _) {
                final rooms = [..._finder.rooms]
                  ..sort(
                    (a, b) =>
                        (b.room == _lastRoom ? 1 : 0) -
                        (a.room == _lastRoom ? 1 : 0),
                  );
                return Column(
                  children: [
                    for (final room in rooms.take(2)) ...[
                      SecondaryButton(
                        label: room.hostName.isEmpty
                            ? l10n.joinRoom
                            : l10n.quickJoin(room.hostName),
                        icon: room.room == _lastRoom
                            ? Icons.history_rounded
                            : Icons.wifi_rounded,
                        selected: room.room == _lastRoom,
                        onPressed: () => _quickJoin(room),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
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
              icon: null,
              onPressed: _busy ? null : _open,
            ),
            const SizedBox(height: 12),
            SecondaryButton(label: l10n.joinRoom, onPressed: _join),
          ];
          final about = [
            Headline(l10n.pageSettings, eyebrow: 'Whowolf'),
            const SizedBox(height: 18),
            AppSettings(version: widget.version),
          ];
          final form = [
            ...play,
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: () => showHowItWorks(context),
              icon: const Icon(Icons.menu_book_rounded, size: 18),
              label: Text(l10n.howLink),
            ),
            const SizedBox(height: 28),
            Stamp(l10n.devStamp(widget.version), size: 18),
            const SizedBox(height: 12),
            Body(l10n.testNote, muted: true),
          ];
          if (!layout.twoColumns) {
            // Pages to swipe instead of one long scroll (task 012).
            return StagePages(
              // So geht's to the left, settings to the right.
              initialPage: 1,
              pages: [
                (
                  label: l10n.howTitle,
                  child: ScrollingPage(
                    child: Column(
                      children: [
                        Headline(l10n.howTitle, eyebrow: l10n.howEyebrow),
                        const SizedBox(height: 14),
                        const HowSteps(),
                      ],
                    ),
                  ),
                ),
                (
                  label: l10n.pagePlay,
                  child: Column(
                    children: [...stage, const SizedBox(height: 22), ...play],
                  ),
                ),
                (
                  label: l10n.pageSettings,
                  child: ScrollingPage(child: Column(children: about)),
                ),
              ],
            );
          }
          // Wide: the stage with its ensemble on the left, the form beside.
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Row(
                children: [
                  // The title and the wolf stand still: no scrolling, they
                  // shrink with a low window instead.
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        32,
                        MediaQuery.paddingOf(context).top + 12,
                        32,
                        MediaQuery.paddingOf(context).bottom + 28,
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: 560,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: stage,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // The form on its own plaque, level with the title.
                  Expanded(
                    flex: 4,
                    child: StageScroll(
                      maxWidth: 420,
                      horizontal: 32,
                      center: true,
                      child: Panel(
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
                        child: Column(children: form),
                      ),
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
